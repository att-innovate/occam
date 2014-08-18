=================
Cloud Application
=================

Introduction
============

The Cloud application is a quite standard Openstack installation. The application uses Stackforge Puppet modules to deploy and manage Openstack components.

Version
=======

Openstack components basically are installed in the Havana version, but there are exceptions:

* Savanna is in the 0.3 version
* Ceilometer is backported from the Openstack Icehouse version


Hardware
========

Servers
-------

Server nodes are divided into two groups:

* controller nodes with names like: ctrl1, ctrl2, etc.
* compute nodes with names like: comp1, comp2, etc.

Networks
--------

There are three networks:

* a management network
* a private network
* a public (external) network

Every server is connected to the management and the private network.
The public network is available only on controller nodes - where Neutron L3 Agents are installed.

The management network is used for servers management and Openstack components communication.
The private network is used by Neutron to connect VMs and by Swift for internal communication.

10Gb bandwidth is recommended for the private network.

Communication with external networks is provided through the public network.

Openstack components
====================

Non-high availability architecture
----------------------------------

In a non-high availability architecture there is only one controller node (ctrl1) and many compute nodes.
There are only one Mysql and one RabbitMQ instances, without any replication. They are run on the controller node.


Keystone
^^^^^^^^

A standard installation where Keystone is run on the controller node and has a Mysql 5.5.x backend.
A Keystone database is stored in the Mysql on the controller node.

Nova
^^^^

A standard installation where Nova uses KVM hypervisor to run VMs on compute nodes.
Core Nova services are run on the controller node and the Nova compute service is run on every compute node.
Instances are stored on a /dev/sda4 partition which is EXT4 formatted and mounted at /var/lib/nova/instances.
A Nova database is stored in the Mysql on the controller node.

Glance
^^^^^^

A standard installation where images are stored in a local disk storage on the controller node.
Images are stored on a /dev/sda4 partition which is EXT4 formatted and mounted at /var/lib/glance.
A Glance database is stored in the Mysql on the controller node.

Horizon
^^^^^^^

A standard installation where Horizon is run on an Apache HTTP server on the controller node.

Cinder
^^^^^^

Cinder API and scheduler are run on the controller node.
Volumes are stored on compute nodes as LVMs on the cinder-volumes VG which uses a /dev/sda5 partition as a PV.
Volumes are shared to VMs through iSCSI protocol by tgt software.
A Cinder database is stored in the Mysql on the controller node.

Swift
^^^^^

Swift proxy server is run on the controller node.
Account, Container and Object storage servers as well as related services (auditors, updaters, replicators, etc.) are run on every compute node.
Objects are stored on a /dev/sda6 partition which is XFS formatted and mounted at /srv/node/sda6.
HAproxy is configured in front of swift proxy server as a SSL terminator.
By default there is an one region configured with five zones and three replicas, however an amount of zones and replicas are configurable.
Amazon S3 API is disabled due to a bug in Keystone, but the API will be enabled when we switch to the Icehouse version.
Internal communication in Swift is realized through the private network.

Neutron
^^^^^^^

Neutron uses Open vSwitch plugin to configure bridges on nodes.
It supports network namespaces to fully separate networks owned by different tenants,
so it is posible that two or more tenants have configured the same network.
Additionally Neutron uses GRE tunnels for network traffic separation outside nodes.
Core Neutron services (dhcp, l3, server) are run on the controller node and the Open vSwitch agent is run on every compute node.
A Neutron database is stored in the Mysql on the controller node.

Ceilometer
^^^^^^^^^^

Ceilometer uses MongoDB database as a backend. The database and core services are run on the controller node. The Compute agent is run on every compute node.
MongoDB database files are stored on a /dev/sda6 partition which is EXT4 formatted and mounted at /var/lib/mongodb.

Savanna
^^^^^^^

Savanna is run on the controller node. A database is stored in the Mysql on the controller node.

By default there are two VM images installed:
* Sahara 0.3 Vanilla 1.2.1 Ubuntu 13.04
* Sahara 0.3 HDP 1.3 Centos 6.4

and two plugins:
* Vanilla Apache Hadoop 1.2.1
* HDP 1.3.2


High availability architecture
------------------------------

TODO ---- This still needs to be added.


Location of Openstack services
==============================

Compute nodes are primarily intended to run virtual machines as well as to store Cinder Volumes and Swift Objects.

A list of Openstack services which are run on compute nodes:
* nova-compute
* neutron agent
* cinder-volume
* swift storage servers (account, container, object)
* ceilometer-agent

Controller nodes holds all remaining Openstack services.

