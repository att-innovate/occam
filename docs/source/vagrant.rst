==================================
Development Environment in Vagrant
==================================

We've prepared a copy of development environment that can be used with Vagrant
and Virtualbox. Using this it is now possible to deploy full development
environment on your own notebook without any changes in the configuration. The
Vagrant configuration contains definition of ops1, ctrl1, comp1/2/3 nodes and
public, private and management networks.

Requirements
============

For the script to work you will need:

* Notebook with at least 8GB of RAM (16GB recommended)
* Virtualbox 4.3 with the VirtualBox Guest Additions 
* Vagrant 1.6 installed
* gpg
* Occam repository

Other versions may work, but these are the latest versions as of the writing of
this document.

.. Note::

    If you are using VirtualBox, you will need to make sure that you have the VirtualBox Guest Additions installed. You can do so by 
    running this command in a terminal. 

    .. code-block:: bash

      vagrant plugin install vagrant-vbguest

.. Note::

    If you do not have gpg installed, you need to install it. On a Mac you can for instance do so by using *HomeBrew*:

    .. code-block:: bash

      brew install gpg


Obtain the Occam Source & Dependencies
======================================

Check out the most recent version of the Occam source.

.. code-block:: bash

    git clone https://github.com/att-innovate/occam.git

You'll need to install the dependencies and ensure you're running the
appropriate version of ruby. This is typically done using rvm_ or rbenv_. If you
choose rbenv, I'd recommend installing rbenv-gemsets_ too.

Whichever you choose and for whichever platform you're running (Linux, OS X)
please follow the respective documentation for each project.

Once they're installed, you'll need the ruby version specified in the
.ruby-version file.

.. code-block:: bash

    rbenv install `cat .ruby-version`

Or for rvm

.. code-block:: bash

    rvm install `cat .ruby-version`


Next, install the required gems using bundler. **If you're using rbenv**, you'll
need to install bundler first.

.. code-block:: bash

    gem install bundler

Then install your gems

.. code-block:: bash

    bundle install

Now you're ready to rock & roll.


Deploying the Vagrant Development Environment
=============================================

We've created a convenient rake task to setup the vagrant environment.

.. code-block:: bash

    rake demo:init

This will perform quite a few tasks. We'll go through each one.

Initializes the `local` occam configuration
--------------------------------------------

Occam comes with an example set of hiera and ssl certs that work out the box in
the vagrant development environment. The demo configs are found in
`lib/files/examples/demo`. If you have an existing `local` file, you it will not
be overwritten and you will be warned.

Occam Application Downloads
---------------------------

The demo environment installs the openstack cloud occam application. The
required puppet modules are downloaded into the `puppet/occam/modules`
directory.

Create Required Virtualbox Networks
-----------------------------------

Two host-only networks are created, configured according to the mgmt and public
networks specified in the zone file. For the demo these are 192.168.3.0/24 and
192.168.4.0/24. DHCP is disabled on both of these networks as services are
provided by the Occam OPS node.

Vagrant Boxes Are Downloaded
----------------------------

The required vagrant boxes are downloaded. These include

- doctorjnupe/precise64_dhcpclient_on_eth7
- steigr/pxe

The first is a vanilla Ubuntu 12.04 image that is configured for DHCP on eth7.
Vagrant enables NAT on eth7 so it can interact with the booted system. The
second is a pxe boot ready 'blank' image. The OPS node will install and
configure the nodes in our cloud.

Configuration of Node Disks
---------------------------

Next, the disks for each node are configured. This includes both a ipxe image
and sparse disk of 200GB.[*]_


System Configuration
--------------------

Next, you're prompted to accept the system changes that need to be made. These
will require administrator access.

- Enable IPv4 forwarding for the current session
- Set ipv4 forwarding to enabled in /etc/sysctl.conf for persistence
- Set pf or iptable rules for NAT'ing on OS X and Linux respectively
- On OS X, will persist these rules by adding them to /etc/pf.conf [*]_

  + Persistence of NAT rules on Linux are left up to the user.

You will also be prompted for the interface to use for NAT'ing. Most people will
only have one option. However, if you have more than one you must ensure you
select an interface that can route traffic to the WAN.

Deploying the OPS Node
-----------------------

Next, the Occam Operations node is started. Once vagrant indicates the OPS node
is ready. Occam will bundle up the cloud application, ship it to the OPS node,
and configure the node. This is a fully automated process, but it does take a
while. You might want to fix a cup of coffee, but you probably won't have time 
to drink it. Takes 2.5  minutes on my laptop.

When it's done, you'll receive a warning about firewalls. Depending on your 
firewall configuration it *could* block the forwarded packets. The virtual 
machines being unable to route out the 192.168.3.1 gateway might be an 
indication of this problem.

Bringing up the Cloud
======================

At this point, we should have a fully operation OPS node. The OPS node provides
PXE, dhcp, puppet master, and other required services for managing client nodes.

Our cloud application is configured for 4 client nodes: A controller and three
computes. 

Controller First
----------------

First a cloud needs a controller. To bring up the controller node

.. code-block:: bash

    vagrant up ctrl1

This can take a good bit of time. Once it's booted, and the intial puppet run is 
complete you're ready to proceed.

The easiest way to verify the puppet run is done is to just rerun the agent.

.. code-block:: bash

    vagrant ssh ctrl1 -c puppet agent -t --verbose

Finally the Computes
--------------------

The process is the same for hte computes, bring each up in turn and take a back 
seat and wait for the OPS node to do its dance.

.. code-block:: bash

    vagrant up comp1 comp2 comp3

.. attention:: Add a section that walks through the services.
   

.. _rbenv: https://github.com/sstephenson/rbenv
.. _rvm: http://rvm.io
.. _rbenv-gemsets: https://github.com/jf/rbenv-gemset
.. _homebrew: http://brew.sh

.. [*] sparse disks will only take up used space on disk, not the full disk size
.. [*] The original pf.conf is stored in tmp/pf.conf. Subsequent runs of rake demo:init
       will overwrite this file.
