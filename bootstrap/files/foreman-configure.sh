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
  if ! /bin/hammer subnet info --name $1 > /dev/null 2>&1 ;then
    echo "Creating $1 subnet...."
    /bin/hammer subnet create --name $1
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
  templates
  touch /etc/foreman/configure_success.txt
}

main