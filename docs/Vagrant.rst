==================================
Development environment in Vagrant
==================================

We've prepared a copy of development environment that can be used with Vagrant and Virtualbox.
Using this it is now possible to deploy full development environment on your own notebook without any changes in the configuration.
The Vagrant configuration contains definition of ops1, ctrl1, comp1/2/3 nodes and public, private and management networks.

Requirements
============

For the script to work you will need:

* notebook with at least 8GB of RAM (16GB recommended)
* fresh installation of Virtualbox 4.3 (without any preconfigurations, networks, etc.)
* Vagrant 1.6 installed
* the Occam repository

Deployment instructions
=======================

Download and prepare Occam repository
-------------------------------------

First, you need to prepare Occam environment. Please proceed as described at `Prepare Occam environment`_ 

Run vagrant configuration helper script
---------------------------------------

Run **utils/prepare_vagrant.sh** script to prepare Vagrant and Virtualbox.

The script takes three parameters:

1. path to the Vagrantfile (located in the root directory of the repository)
2. absolute path to a directory to store virtual disks
3. size of each virtual disk in GB (minimum 200GB)

Example:

.. code:: bash

  % utils/prepare_vagrant.sh Vagrantfile /home/user/VirtualBoxDisks 200

If everything works fine you should have:

* two HostOnly networks configured in Virtualbox vboxnet0 and vboxnet1 with IP addresses assigned and DHCP servers disabled
* eight virtualdisks created in the directory pointed in the second parameter (two disk by VM)
* four copies of the IPXE floppy image (one image by VM)
* modified Vagrantfile with correct paths to these virtualdisks and images


Add NAT rules for vagrant
-------------------------


Mac OS X:
^^^^^^^^^

1. Enable IP forwarding:

  .. code:: bash

    % sudo sysctl -w net.inet.ip.forwarding=1

  You might want to add it to /etc/sysctl.conf for persistency

2. Add anchor for NAT in /etc/pf.conf. We are using 192.168.3.0/24 as a network segment:

  .. code:: bash

    % scrub-anchor "com.apple/*"
    % nat-anchor "com.apple/*"
    % nat on en0 from 192.168.3.0/24 -> (en0)
    % rdr-anchor "com.apple/*"
    % dummynet-anchor "com.apple/*"
    % anchor "com.apple/*"
    % load anchor "com.apple" from "/etc/pf.anchors/com.apple"


3. Load new PF configuration:

  .. code:: bash

    % sudo pfctl -f /etc/pf.conf


Linux:
^^^^^^

1. Enable IP forwarding:

  .. code:: bash

    $ sudo sysctl -w net.ipv4.ip_forward=1

  You might want to add it to /etc/sysctl.conf for persistency:

  .. code:: bash

    $ sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

2. Enable NAT for 192.168.3.0/24 network:

  .. code:: bash

    $ sudo iptables -t nat -I POSTROUTING -s 192.168.3.0/24 -j MASQUERADE

  You might want to add it to /etc/rc.local for persistency:

  .. code:: bash

    $ sudo echo "iptables -t nat -I POSTROUTING -s 192.168.3.0/24 -j MASQUERADE" >> /etc/rc.local


Boot ops1 node
--------------

On local machine run:

.. code:: bash
  
  % vagrant up ops1

Change root password
--------------------

On local machine run:

.. code:: bash

  % vagrant ssh ops1 -c "sudo passwd"

Check connectivity
------------------

Check if you can reach host machine and the Internet from ops1:

.. code:: bash

  % vagrant ssh ops1
  % ping 192.168.3.1
  % ping google.com
  % exit

Deploy ops node
---------------

Deploy ops1 node using rake task in the same way like on real environment:

.. code:: bash

  % OPSUSERNAME='root' OPSPASSWORD='<password>' OC_ENVIRONMENT=testing ZONEFILE=zone1 rake occam:deploy_initial\[192.168.3.10\]

Deploy other nodes
------------------

When ops1 deployment is finished you can deploy another nodes:

.. code:: bash

  % vagrant up ctrl1
  % vagrant up comp1

Known issues:
=============

Sometimes guest starting process may fail with strange error about adding NAT rule into Virtualbox - don't worry, just try to start guest again (magic).

