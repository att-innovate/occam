#!/bin/bash
set -ex

foreman-installer \
  --foreman-configure-scl-repo=false \
  --enable-foreman-plugin-puppetdb

consumer_key=`awk '/oauth_consumer_key/{print $2}' /etc/foreman/settings.yaml`
consumer_secret=`awk '/oauth_consumer_secret/{print $2}' /etc/foreman/settings.yaml`

#--puppet-server-environments development \
# --puppet-server-environments production \
# --puppet-server-environments testing \

foreman-installer \
  --puppet-server-facts=true \
  --enable-foreman-proxy \
  --foreman-proxy-tftp=true \
  --foreman-proxy-tftp-servername=192.168.100.10 \
  --foreman-proxy-dhcp=true \
  --foreman-proxy-dhcp-interface=eth1 \
  --foreman-proxy-dhcp-gateway=192.168.100.2 \
  --foreman-proxy-dhcp-range="192.168.100.100 192.168.100.200" \
  --foreman-proxy-dhcp-nameservers="192.168.100.10" \
  --foreman-proxy-dns=true \
  --foreman-proxy-dns-interface=eth1 \
  --foreman-proxy-dns-zone=zone1.example.com \
  --foreman-proxy-dns-reverse=100.168.192.in-addr.arpa \
  --foreman-proxy-dns-forwarders=172.16.101.2 \
  --foreman-proxy-foreman-base-url=https://ops1.zone1.example.com \
  --foreman-proxy-oauth-consumer-key=${consumer_key} \
  --foreman-proxy-oauth-consumer-secret=${consumer_secret}

sed -i 's|environment\s*= production|environment       = testing|g' /etc/puppet/puppet.conf
sed -i 's|$confdir/hiera.yaml|/etc/puppet/hiera.yaml|g' /etc/puppet/puppet.conf
systemctl restart httpd
sleep 5
touch /etc/foreman/install_success.txt