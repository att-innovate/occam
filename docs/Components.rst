Occam components explained
==========================

Ops node
--------
Node hosting all core services of Occam:

* puppet master
* hiera
* puppetdb
* mcollective
* occamengine
* admin tools, etc.

Ops node is first node that is deployed during installation process (see `Occam Rake tasks`_).


Occamengine
-----------
Occamengine (OE) is a daemon written in ruby, running on ops node, responsible for provisioning bare metal nodes. It interacts with dnsmasq and puppet.

Occamengine consist of 5 main parts:

* database interface for storing nodes data (hostnames, ips, mac addresses, puppet's runs statuses)
* http rest api for interacting with nodes (ipxe image serving, callbacks with node operating system installation status)
* http rest api for interacting with puppet master (nodes classification, node run reports)
* dnsmasq interface for creating dhcp reservations and dns entries
* logic for choosing a role for a node

Configuration of OE is done in 2 yaml files. First one is occamengine.yaml file located in /etc/occam directory. This is where general OE options are set, like OE base directory, dhcp and dns reservations files, dnsmasq pidfile location, ip of the ops node and domain name used for quaifying the host names. All options in this file are set up by puppet during ops node configuration phase. Second yaml file is a zone file used for configuration of whole installation environment (see Configure Your Zone). Most important optons read from this file are 'roles' and 'networks' hashes. 


**Roles** hash contains definition of possible roles for nodes (each node need to be bound to one of these roles).
Each role contains following options:

* *puppet_class* - full name of a puppet class used by external node classifier; can be ommited - defaults to role::*name_of_the_role*
* *priority* - priority of the role; lower number means higher priority
* *minimum* - minimun number of nodes for the role
* *maximum* - maximun number of nodes for the role
* *macs* - array of mac addresses of the nodes that should be bound to the role apart from priority of the role

.. code:: yaml
  
  roles:
    ctrl:
      :puppet_class: 'role::openstack::controller'
      :priority: 10
      :minimum: 1
      :maximum: 1
      :macs:
        - 'b8:ca:3a:5b:c1:60'
    monit:
      :puppet_class: 'role::monitoring::server'
      :priority: 20
      :minimum: 1
      :maximum: 1
      :macs:
        - '52:54:00:c2:88:60'
    comp:
      :puppet_class: 'role::openstack::compute'
      :priority: 30
      :minimum: 3
      :maximum: 10

Every node managed by OE need to have exactly one role assigned. Hostname of a node is constructed from role name followed by a number (in sequence, starting from 1). For role named *ctrl* first node will have a hostname ctrl1. 
Selection algorithm of a role for a node is pretty simple: if mac address of the node matches one of the mac addresses in role's *macs* array, the role is assigned; in other case the role with highest priority with a number of currently assigned nodes lower then role's *maximum* setting is selected.

**Networks** hash contains definition of networks used by nodes. Dhcp reservations and dns entries are created for each network for each node. Each network contains following options:

* *network* - netmask of the network
* *netmask* - netmask of the network
* *gateway* - gateway of the network
* *suffix* - suffix for hostname; each aditional network need this setting to construct dns entry

.. code:: yaml

  networks:
    eth0:
      network: 10.100.1.0
      netmask: 255.255.255.0
      gateway: 10.100.1.1
    eth5:
      suffix: 'vm'
      network: 172.20.1.0
      netmask: 255.255.255.0
      gateway: 172.20.1.1

It's important to prepare nodes' network interfaces to match interface names from yaml's networks hash. To ensure proper cabling (especially when using heterogeneous hardware environment) it can be useful to boot up every different hardware from Ubuntu live CD and check ethernet names given by the system for each ethernet port.

Each node need to be set up for pxe booting. pxe files are served by dnsmasq-tftp. Provisioning flow consist of following steps:

* node boots up with pxe. dnsmasq responds with ipxe image (undionly.kpxe)
* ipxe ask again for pxe boot with NIC mac address as a parameter
* OE responds with either with commands for operating system installer boot (for new nodes) followed by kernel, initrd images and with preseed file for installation
* preseed files contains 3 callback calls to update node state in the database
* during installation stage puppet and facter are installed, puppet is configured to start and connect to puppet master running on ops node
* at the end of installation facter is executed in in-target chroot and facts are sent to OE
* OE receives facts from node, sets node status to *deployed*
* mac addresses for networks defined in yaml file are extracted from received facter output and proper dhcp and dns entries are prepared
* node boots up from local disk and puppet makes it's first run on the node
* for first run puppet class role::initial is returned by external node classifier; during this stage all required network interfaces are configured
* for all subsequent puppet runs class linked to node's role is returned.
* OE kicks puppet on all nodes sequentially (one node at a time, nodes with lower count of runs first) until puppet_initial_runs config value is reached for all nodes
 
