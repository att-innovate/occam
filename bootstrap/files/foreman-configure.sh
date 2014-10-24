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

function main() {
  #environment testing
  ${HAMMER} environment create --name testing
  ${HAMMER} environment create --name develop
  touch /etc/foreman/configure_success.txt
}

main