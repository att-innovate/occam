#!/bin/bash
set -ex

HAMMER=/bin/hammer

function environment() {
  if ! /bin/hammer environment info --name $1 > /dev/null 2>&1 ;then
    echo "Creating $1 environment ...."
    /bin/hammer environment create --name $1
  fi
}

function subnet() {
  if ! /bin/hammer subnet info --name Management > /dev/null 2>&1 ;then
    echo "Creating subnets...."
    proxy_id=`${HAMMER} proxy list | awk '/https/{print $1}'`
    domain_id=`${HAMMER} domain list | awk '/^[123456789]/{print $1}'`
    
    /bin/hammer subnet create \
      --name Management \
      --dhcp-id $proxy_id \
      --dns-id $proxy_id \
      --dns-primary 192.168.100.10 \
      --domain-ids $domain_id \
      --gateway 192.168.100.2 \
      --from 192.168.100.100 \
      --to 192.168.100.200 \
      --mask 255.255.255.0 \
      --network 192.168.100.0 \
      --tftp-id $proxy_id
  fi
}

function templates() {
  ${HAMMER} template update \
      --name "PXELinux global default" \
      --file /tmp/pxelinux_global.erb
  
  arch_id=`${HAMMER} architecture list | awk '/x86_64/{print $1}'`
  medium_id=`${HAMMER} medium list | awk '/Ubuntu mirror/{print $1}'`
  ptable_id=`${HAMMER} partition-table list | awk '/Preseed custom LVM/{print $1}'`
  hammer os create \
    --architecture-ids ${arch_id} \
    --family Debian \
    --major 12 \
    --minor 04 \
    --medium-ids ${medium_id} \
    --name "Ubuntu" \
    --ptable-ids ${ptable_id}
}

function main() {
  environment testing
  environment develop
  # templates
  # subnet
  touch /etc/foreman/configure_success.txt
}

main