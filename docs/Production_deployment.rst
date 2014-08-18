===========================
Deploying a new environment
===========================

What you need.
==============

* A Ubuntu 12.04 installation iso
* Access to the ILO network for the target server
* Network information (subnet, gateway, dns, etc.)
* A will of steel.
* Oh, and ninja skilz.
* A approximately 1 hour playlist of your favorite tunes.
* Coffee. Preferrably espresso, or beer... depending on time of day.

Overview
========
Occam deployment starts with deploying so called 'ops node'. Master node hosts all tools required to bootstrap other server, puppet master, DHCP server, DNS server etc. Once deployed, it will be able to deploy other hosts on bare metal.
Occam support deploying OpenStack Havana release including controller hosts (with and w/o HA), compute hosts, storage nodes, etc. As a bonus you can deploy savanna/sahara on top of OpenStack cluster.

Hardware requirements for nodes
===============================
During bare metal deployment you must be able to PXE boot bare metal nodes either by rebooting them manually or using IPMI/custom tools. Occam will then install and configure base operating system and all packages depending on the chosen role. In most cases you should create one raw device on your servers and Occam will create one ca. 128GiB partition for system purposes and partition the rest depending on the role.


Install an operating system
===========================

.. Attention::
    By default, the scripts assume the initial operations node has a hostname
    of 'ops1'. Make life easy on yourself. Use it.

.. Attention::
    This document was written based on the Ubuntu 12.04 LTS operating system.
    Other options are valid. YMMV

.. Attention::
    To best utilize Occam to deploy environments, naming the initial
    operations node 'ops1' is recommended. See note on hostgroups in the
    `Configuring for your environment`_ section.

.. CAUTION::
    The hostname and fqdn must be configured before hand for these scripts to 
    work properly.

Though not required, I suggest splitting up your system mount points. My
configuration looks like:

    * lv_root: 20GB
    * lv_swap: 50GB
    * lv_home: 50GB
    * lv_var: 100GB

The lv indicates I used lvm volume management. This, of course, is not a
requirement.

Bootstrapping the ops node
==========================

First, you need to prepare Occam environment. See `Prepare Occam environment`_ section for more details

Configuring zone
----------------

This step entails the creation of your occam configuration files. The configuration files use hiera - a key/value lookup tool for configuration data - built to make Puppet better and let you set node-specific data without repeating yourself. Hiera loads the hierarchy from the hiera.yaml config file.

Occam's hiera lookup table has the following precedence:

+--------------------------------+-------------------------------------------------+
| Hiera Precedence               | Usage                                           |
+================================+=================================================+
| local/secrets/                 | This used as the password file. The password    |
|                                | file is an encryted gpg file.                   |
+--------------------------------+-------------------------------------------------+
| local/fqdns/%{::fqdn}          | This is where the network interface definitions |
|                                | for the ops and ctrl nodes are stored.          |
+--------------------------------+-------------------------------------------------+
| local/zones/                   | This is where the deployment target information |
|                                | is stored.                                      |
+--------------------------------+-------------------------------------------------+
| local/hostgroups/%{::hostgroup}| This is used to define the dns and dhcp for the |
|                                | target deployment.                              |
+--------------------------------+-------------------------------------------------+
| users/users_occam              | Managed users and groups definitions.           |
+--------------------------------+-------------------------------------------------+
| occam                          | Occamengine specific configurations.            |
+--------------------------------+-------------------------------------------------+

**Note: The following represent example hiera files. They may be used as a reference. You can name your zone anything.**

Secrets
=======

Example secrets file: `secrets/zone1.yaml`_

.. _`secrets/zone1.yaml`: ../lib/files/examples/secrets/zone1.yaml

fqdn
====

Example ops node file: ops1.zone1.example.com.yaml_

.. _ops1.zone1.example.com.yaml: ../lib/files/examples/fqdn/ops1.zone1.example.com.yaml

Example ctrl node file: ctrl1.zone1.example.com.yaml_

.. _ctrl1.zone1.example.com.yaml: ../lib/files/examples/fqdn/ctrl1.zone1.example.com.yaml

Example monit node file: monit1.zone1.example.com.yaml_

.. _monit1.zone1.example.com.yaml: ../lib/files/examples/fqdn/monit1.zone1.example.com.yaml

Zone
=====

Example zone file: zone1.yaml_

.. _zone1.yaml: ../lib/files/examples/zone1.yaml

Hostgroups
==========

Example host files:

* ops.yaml_

.. _ops.yaml: ../lib/files/examples/ops.yaml

* ctrl.yaml_

.. _ctrl.yaml: ../lib/files/examples/ctrl.yaml

* comp.yaml_

.. _comp.yaml: ../lib/files/examples/comp.yaml

* monit.yaml_

.. _monit.yaml: ../lib/files/examples/monit.yaml

* occam-node.yaml_

.. _occam-node.yaml: ../lib/files/examples/occam-node.yaml

Users
=====

Example users file: users.yaml_

.. _users.yaml: ../lib/files/examples/users.yaml

Occam
=====

Example occam file: occam.yaml_

.. _occam.yaml: ../lib/files/examples/occam.yaml

Initial deployment
------------------
.. code:: bash
  
  % OPSUSERNAME='root' OPSPASSWORD='secretpassword' OC_ENVIRONMENT=testing ZONEFILE=yourzone rake occam:deploy_initial\[10.100.1.10\]

Where:

* OPSUSERNAME - username on ops1 node
* OPSPASSWORD - password for OPSUSERNAME
* OC_ENVIRONMENT - name of your puppet environment, usually testing or production
* ZONEFILE - zone configuration file from **puppet/hiera/zones** directory without .yaml extension. Puppet on ops node uses this information to read configuration. You can have many zones within one Occam project
* 10.100.1.10 - ip address of ops node

This rake task will package and transfer occam folder to /var/puppet/environments/$OC_ENVIRONMENT/ on ops node and then install and configure all ops services like puppet, hiera, etc.

Configuring for your environment
--------------------------------

.. WARNING:: 
    Puppet, hiera, git, etc. are beyond the scope of this document. If you do
    not have a working knowledge of these tools, your path will be frought
    with confusion, frustration, chaos, and quite possibly a non-trivial amount
    of psychiatric counseling. Fortunately, there are many, many, many
    resources available on these topics. A few are listed in the additional
    resources section.

.. WARNING::
    This project assumes you're using git to manage the source. The puppet
    master's environments, hiera data, etc are checked out **directly** from a
    parent repository and created dynamically through git commit hooks.

.. Note::
    The 'hostgroup' is a dynamically generated facter based on the node's 
    hostname. It's determined by the return of hostname stripped of appended 
    numbers. 
    
    For example, host ops1 has a hostgroup of 'ops', host comp58 has a 
    hostgroup 'comp', and host ctrl28 has a hostgroup 'ctrl'. 

.. ATTENTION::
    This project assumes the first ops node has a hostname of ops1 and should
    be setup as the dhcp/dns/puppetmaster node. If that's not the case,
    the operator is responsible for modifying the project to accomodate their
    custom configuration.

Occam deployment is based on puppet. Modules should be generalized and
decoupled from environment sepcific data. It uses `hiera data lookups`_ and 
`automatic parameter lookup`_ for class arguments. When setting up a new 
environment, it's highly likely you'll need to create the requisite hiera data 
files for site or node specific information. 

Occam's hiera lookup table has the following precedence:

    * The node's FQDN.
    * The node's hostgroup 
    * The node's virtual facter (vmware, kvm, etc. for specific virtual configs)
    * Either virtual_true or virtual_false (mainly for general virtual configs)
    * The 'common' file which contains defaults.

For the purpose of this example, we'll assume the network configuration must be 
modified from the default. This effects multiple services and so effects 
multipe class arguments that must be configured in hiera. A reasonable place to 
put these site customizations for our new operations node is in the nodes FQDN
hiera data file. For a server with the fqdn 'ops1.zone1.example.com', the 
hiera file would be ops1.zone1.example.com.yaml and placed in the
puppet/hiera/ directory of this project. 

As of the writing of this document, the ops1.zone1.example.com  site 
specific configurations are the only ones required. However, they may not 
reflect all current configurations. It would behoove the new user to read 
through the node manifests and their referenced class's documentation and 
source to familiarize themselves with the project.
