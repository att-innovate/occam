#!/bin/bash

# MUST DEFINE 
# - DRAC_PASS
# - DRAC_USER 

DRAC_NET=${DRAC_NET:-10.201.0.}
MGMT_NET=${MGMT_NET:-192.168.2.}
NIC_NUM=${NIC_NUM:-3}
count=0

echo "dhcp_hosts:" > output.yaml
while (( "$#" ));do
  mac=`ipmitool -I lanplus -H "${DRAC_NET}${1}" -U ${DRAC_USER} -P ${DRAC_PASS} delloem mac | egrep "^${NIC_NUM}" | awk '{print $2}'`

  cat <<EOF >> output.yaml
  host${1}:
    ip: ${MGMT_NET}${1}
    mac: ${mac}
EOF

  shift
  let count=count+1
done

