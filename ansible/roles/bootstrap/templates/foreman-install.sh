#!/bin/bash
set -ex

if [[ -z $HAMMER ]]; then
    HAMMER=/usr/bin/hammer
fi

function update_vars() {
    if [[ ! -e $HAMMER ]]; then
        HAMMER=`which hammer`
    fi
    if [ -z $provision ];then
        provision=`${HAMMER} template list --search preseed | awk '/Preseed default.*provision/{print $1}'`
    fi
    if [[ -z $finish ]]; then
        finish=`${HAMMER} template list --search preseed | awk '/Preseed default finish/{print $1}'`
    fi 
    if [[ -z $pxe ]]; then
        pxe=`${HAMMER} template list --search preseed | awk '/Preseed default PXELinux/{print $1}'`
    fi 
    if [[ -z $x86 ]]; then
        x86=`${HAMMER} architecture list | awk '/x86_64/{print $1}'`
    fi
    if [[ -z $part ]]; then
        part=`${HAMMER} partition-table list | awk '/Preseed default/{print $1}'`
    fi
    if [[ -z $medium ]]; then
        medium=`${HAMMER} medium list | awk '/Ubuntu mirror/{print $1}'`
    fi
    if [[ -z $osid ]]; then
        osid=`${HAMMER} os list | awk '/Ubuntu 12.04/{print $1}'`
    fi
    if [[ -z $model ]]; then
        model=`${HAMMER} model list | awk '/{{ hosts_model }}/{print $1}'`
    fi
    if [[ -z $proxy ]]; then
        proxy=`${HAMMER} proxy list | awk '/ops1.{{ domain }}/{print $1}'`
    fi
    if [[ -z $domain_id ]]; then
        domain_id=`${HAMMER} domain list | awk '/^[123456789]/{print $1}'`
    fi
}

function get_host_id() {
    ${HAMMER} host list | awk "/$1/{print \$1}"
}

function environment() {
  if ! ${HAMMER} environment info --name $1 > /dev/null 2>&1 ;then
    echo "Creating $1 environment ...."
    ${HAMMER} environment create --name $1
    mkdir -p /etc/puppet/environments/$1
  fi
}

function subnet() {
    update_vars

    if ! ${HAMMER} subnet info --name Management > /dev/null 2>&1 ;then
        ${HAMMER} subnet create \
          --name Management \
          --dhcp-id $proxy \
          --dns-id $proxy \
          --dns-primary {{ management.dns }}\
          --domain-ids $domain_id \
          --gateway {{ management.gateway }} \
          --from {{ management.dhcp_begin }} \
          --to {{ management.dhcp_end }} \
          --mask {{ management.netmask }} \
          --network {{ management.network }} \
          --tftp-id $proxy
    fi
}

function domain() {
    update_vars
    if ! ${HAMMER} domain list | grep {{ domain }};then
      ${HAMMER} domain create --dns-id $proxy --name {{ domain }}
    else
      ${HAMMER} domain update --id $domain_id --dns-id $proxy
    fi
    ${HAMMER} host update --name ops1.{{ domain }} \
                          --domain {{ domain }} \
                          --environment {{ puppet_environment }}
}

function oscreate() {
    if ! ${HAMMER} os list | grep "Ubuntu 12.04";then
      ${HAMMER} os create --description "Ubuntu 12.04" \
                          --family Debian \
                          --major 12 \
                          --minor 04 \
                          --name Ubuntu \
                          --release-name precise
    fi

    update_vars

    ${HAMMER} os update --id $osid \
                        --architecture-ids $x86 \
                        --ptable-ids $part \
                        --medium-ids $medium \
                        --config-template-ids $provision,$finish,$pxe

   ${HAMMER} os set-default-template --id $osid --config-template-id $provision
   ${HAMMER} os set-default-template --id $osid --config-template-id $finish
   ${HAMMER} os set-default-template --id $osid --config-template-id $pxe
}

function hostgroup() {
    if ! ${HAMMER} hostgroup list | grep ops1.{{ domain }};then
      ${HAMMER} hostgroup create --name ops1.{{ domain }} \
                                 --architecture-id $x86 \
                                 --domain {{ domain }} \
                                 --environment {{ puppet_environment }} \
                                 --medium-id $medium \
                                 --operatingsystem-id $osid \
                                 --ptable-id $part \
                                 --puppet-ca-proxy ops1.{{ domain }} \
                                 --puppet-proxy ops1.{{ domain }} \
                                 --subnet Management
    fi

    ${HAMMER} hostgroup set-parameter --hostgroup ops1.{{ domain }} \
                                      --name enable-puppetlabs-repo \
                                      --value true

}

function create_host() {
    update_vars

    if ! ${HAMMER} host list | grep $1;then
        ${HAMMER} host create --name $1 \
                              --architecture-id $x86 \
                              --ask-root-password false \
                              --domain {{ domain }} \
                              --environment {{ puppet_environment }} \
                              --hostgroup ops1.{{ domain }} \
                              --ip $3 \
                              --mac $2 \
                              --medium-id $medium \
                              --model-id $model \
                              --operatingsystem-id $osid \
                              --ptable-id $part \
                              --puppet-ca-proxy-id $proxy \
                              --puppet-proxy-id $proxy \
                              --root-password {{ default_password }} \
                              --subnet $4 
    else
        hostid=`get_host_id $1`
        ${HAMMER} host update --id $hostid \
                              --architecture-id $x86 \
                              --ask-root-password false \
                              --domain {{ domain }} \
                              --environment {{ puppet_environment }} \
                              --hostgroup ops1.{{ domain }} \
                              --ip $3 \
                              --mac $2 \
                              --medium-id $medium \
                              --model-id $model \
                              --operatingsystem-id $osid \
                              --ptable-id $part \
                              --puppet-ca-proxy-id $proxy \
                              --puppet-proxy-id $proxy \
                              --root-password {{ default_password }} \
                              --subnet $4 
    fi
}

function install() {
    # Must do an initial install to generate the auth keys needed for 
    # configuring the proxy
    foreman-installer \
      --enable-foreman-plugin-puppetdb \
      --foreman-configure-scl-repo=false

    consumer_key=`awk '/oauth_consumer_key/{print $2}' /etc/foreman/settings.yaml`
    consumer_secret=`awk '/oauth_consumer_secret/{print $2}' /etc/foreman/settings.yaml`

    foreman-installer \
      --enable-foreman-plugin-puppetdb \
      --foreman-configure-scl-repo=false \
      --puppet-server-facts=true \
      --enable-foreman-proxy \
      --foreman-proxy-tftp=true \
      --foreman-proxy-tftp-servername={{ management.ip }} \
      --foreman-proxy-dhcp=true \
      --foreman-proxy-dhcp-interface={{ management.interface }} \
      --foreman-proxy-dhcp-gateway={{ management.gateway }} \
      --foreman-proxy-dhcp-range="{{ management.dhcp_begin }} {{ management.dhcp_end }}" \
      --foreman-proxy-dhcp-nameservers="{{ management.ip }}" \
      --foreman-proxy-dns=true \
      --foreman-proxy-dns-interface={{ management.interface }} \
      --foreman-proxy-dns-zone={{ domain }} \
      --foreman-proxy-dns-reverse={{ management.reverse }}.in-addr.arpa \
      --foreman-proxy-dns-forwarders={{ management.forwarder }} \
      --foreman-proxy-foreman-base-url=https://ops1.{{ domain }} \
      --foreman-proxy-oauth-consumer-key=${consumer_key} \
      --foreman-proxy-oauth-consumer-secret=${consumer_secret}

    systemctl restart httpd
    
    update_vars
    # Set to production environment for initial checkin
    host=`hostname`
    hostid=`get_host_id $host`
    
    if [[ -z $hostid ]]; then
        # this means the host has not yet checked in
        # Initial puppet checkin
        puppet agent -t || true
    fi


    sed -i 's|environment\s*= production|environment       = {{ puppet_environment }}|g' /etc/puppet/puppet.conf
    sed -i 's|$confdir/hiera.yaml|/etc/puppet/hiera.yaml|g' /etc/puppet/puppet.conf
    systemctl restart httpd

}


function main() {
    install
    update_vars
    environment develop
    environment {{ puppet_environment }}
    domain
    subnet
    oscreate
    hostgroup

    {% for host in hosts %}
    create_host {{ host.name }} {{ host.mac }} {{ host.ip }} {{ host.subnet }}
    {% endfor %}

    touch /etc/foreman/install_success.txt
}

main
