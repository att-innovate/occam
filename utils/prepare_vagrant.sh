#!/bin/bash

function usage {
  echo ""
  echo "Usage:"
  echo " $0 <path to Vagrantfile> <absolute path to virtualdisks directory> <size of virtualdisk>"
  echo ""
  exit 1
}

function create_network {
  NAME=$1
  IP=$2
  NETMASK=$3
  if ! `vboxmanage list hostonlyifs |grep -q ^Name:.*${NAME}`; then
    echo "- ${NAME}"
    vboxmanage hostonlyif create && vboxmanage dhcpserver remove --ifname ${NAME} && vboxmanage hostonlyif ipconfig ${NAME} --ip ${IP} --netmask ${NETMASK} && echo "HostOnly interface ${NAME} created"
  else
    echo "- ${NAME} exists - nothing to do"
  fi
}

function create_disks {
  VMNAME=$1
  for NUMBER in 1; do
    if [ -f "${HDDIR}/${VMNAME}_disk${NUMBER}.vdi" ]; then
      echo "  - ${VMNAME}_disk${NUMBER}.vdi exists - nothing to do"
    else
      echo "  - ${VMNAME}_disk${NUMBER}"
      vboxmanage createhd --filename "${HDDIR}/${VMNAME}_disk${NUMBER}.vdi" --size ${HDSIZEMB}
    fi
  done
}

function download_box {
  BOXNAME=$1
  if `vagrant box list |grep -q ${BOXNAME}`; then
    echo "  - ${BOXNAME} exists - nothing to do"
  else
    echo "  - ${BOXNAME}"
    vagrant box add --provider virtualbox "${BOXNAME}"
  fi
}

function copy_pxe_image {
  VMNAME=$1
  if [ -s "${HDDIR}/${VMNAME}_ipxe.dsk" ]; then
    echo "  - ${VMNAME}_ipxe.dsk exists - nothing to do"
  else
    echo "  - ${VMNAME}_ipxe.dsk"
    cp ~/.vagrant.d/boxes/steigr-VAGRANTSLASH-pxe/${STEIGR_PXE_BOX_VERSION}/virtualbox/ipxe.dsk "${HDDIR}/${VMNAME}_ipxe.dsk"
  fi
}

if [ $# -ne 3 ]; then
  usage
fi

VAGRANTFILE="$1"
HDDIR="$2"
HDSIZE=$3

# Vagrantfile validation:
if ! [ -s "${VAGRANTFILE}" ]; then
  echo "Vagrantfile ${VAGRANTFILE} does not exist or is empty"
  exit 1
fi

if ! `grep -q Vagrant.configure "${VAGRANTFILE}"`; then
  echo "${VAGRANTFILE} does not seem to be a valid Vagrantifle"
  exit 1
fi

# HD size validation:
HDSIZEMB=$((${HDSIZE} * 1024))
if ! [ ${HDSIZEMB} -ge 204800 ]; then
  echo "Invalid value for virtual disk size, it must be not lower than 200GB, calculated value in MB: $HDSIZEMB"
  exit 1
fi

# HD directory validation:
if ! `echo ${HDDIR} |grep -q '^/'`; then
  echo "Path to the virtualdisks directory must be absolute"
  exit 1
fi

#cut last slash from directory path
HDDIR=${HDDIR%/}

mkdir -p "${HDDIR}"
if [ ! -w "${HDDIR}" ] || [ ! -d "${HDDIR}" ]; then
  echo "Directory ${HDDIR} does not exist or is not writeable"
  exit 1
fi

# end of parameters validation

echo ""

### create HostOnly networks:
echo "Creating HostOnly networks ..."
# management network:
create_network vboxnet0 192.168.3.1 255.255.255.0
# public network:
create_network vboxnet1 192.168.4.1 255.255.255.0

echo ""

### download boxes:
echo "Downloading boxes ..."
download_box "doctorjnupe/precise64_dhcpclient_on_eth7"
download_box "steigr/pxe"
if ! `vagrant box list |grep -q "doctorjnupe/precise64_dhcpclient_on_eth7"` || ! `vagrant box list |grep -q "steigr/pxe"`; then
  echo "Required Vagrant boxes does not exist, exiting!"
  exit 1
fi

echo ""

### check if source IPXE floppy image file exists
STEIGR_PXE_BOX_VERSION=`vagrant box list | awk '/steigr\/pxe/{print $3}' |tr -d '()'`
if ! [ -s ~/.vagrant.d/boxes/steigr-VAGRANTSLASH-pxe/${STEIGR_PXE_BOX_VERSION}/virtualbox/ipxe.dsk ]; then
  echo "source file ~/.vagrant.d/boxes/steigr-VAGRANTSLASH-pxe/${STEIGR_PXE_BOX_VERSION}/virtualbox/ipxe.dsk does not exist! exiting!"
  exit 1
fi

## create disks for VMs:
echo "Creating disks in the ${HDDIR} ..."
for vm in ctrl1 comp1 comp2 comp3; do
  echo "- for ${vm}"
  copy_pxe_image ${vm}
  create_disks ${vm}
done

echo ""

### modify Vagrantfile
echo "Modifying Vagrantfile ..."
OS=`uname`
if [ ${OS} == "Darwin" ]; then
  sed -i '' "s#PATH_TO_VIRTUALDISKS_DIRECTORY#${HDDIR}#" "${VAGRANTFILE}"
else
  sed -i "s#PATH_TO_VIRTUALDISKS_DIRECTORY#${HDDIR}#" "${VAGRANTFILE}"
fi
if [ $? -ne 0 ]; then
  echo "Something went wrong in Vagrantfile modification"
  exit 1
else
  echo " - done"
fi

cat <<EOF

!!! Important notice:

Don't forget to share Internet for the 192.168.3.0/24 network !!!
The simplest way to do this on Linux is to run - AS ROOT - these two commands:
# sysctl -w net.ipv4.ip_forward=1
# iptables -t nat -I POSTROUTING -s 192.168.3.0/24 -j MASQUERADE
Also add these commands to the /etc/rc.local to make the internet sharing permanent

EOF
