==============
What is Occam?
==============

*Last updated:* 2014-08-18

The AT&T Foundry currently runs a number of diverse infrastructure projects in various sections - such as Compute, Storage, and PaaS frameworks - which all have vastly varying demands. To be able meet these demands, it was necessary to develop our own solution for automation, orchestration, hardware abstraction and provisioning. 

Our ultimate goal was to build a framework with excellent code quality, inline with industry standards and includes the obligatory abstraction layers. It was essential to make sure our development process introduces best practices for how all services included in the framework as we test various compositions as well as evaluate various underlying technologies. The result of this work is a framework called *Occam*, which is a complete automation, orchestration, and development framework to manage your infrastructure and services you run on top. 

Occam has been confirmed to be working with a number of infrastructure applications. These applications are self-contained entities that can be easily installed inside the Occam core. You can for instance, using the `OpenStack Havana Cloud Application`_ and `Occam`_, deploy many separated Havana clouds - so called *zones* - with completely different configurations. 

Occam is built using Puppet and using the proven development workflow consisting of Gitflow, continuous integration and Test-Driven Development (puppet-lint, spec). We wanted to make sure that the various zones have been brought up with integrity why Tempest was also introduced. To properly monitor and test performance irrespectively of configuration of the zone we also introduced benchmark tests.

The Puppet orchestration layer is following the well-known role/profile paradigm, which allows us to abstract all local changes and keep the original modules unmodified and intact. This does not only let us take advantage of the efforts within the larger community, but also easily & promptly upgrade all components. It also allows us to introduce new and old components as we evaluate them. 

The target deployment zone can easily be configured using Hiera configuration files, which optionally can be encrypted using GPG to allow for better security on deployed versions of the zone, yet allow development to be more seamless. 

We have also included a Vagrant configuration to allow for seamless local development.

Occam consists of many components, from which most prominent are:

* Puppet + hiera + mcollective for automation and orchestration
* Occamengine for bare metal provisioning and external node classification (ENC)
* Logstash + Elasticsearch + Kibana for log collection and analysis
* Zabbix for monitoring

Where is the documentation?
===========================

You can generate exhaustive documentation by running the following commands:

1. Install rvm if you do not have it:

.. code:: bash

  % curl -sSL https://get.rvm.io | bash
  
2. Install the right ruby version:

.. code:: bash

  % rvm install ruby-1.8.7
  
3. Install the necessary gems

.. code:: bash

  % bundle install
  
4. Generate the latest documentation

.. code:: bash

  % rake docs:build
  
This will generate two HTML files under the *docs* directory: *readme.html* and *quickstart.html*. Please refer to the sections below for details on what you will find in these two files. 

What is in the readme.html?
---------------------------

The *docs/readme.html* file contains an exhaustive documentation of *Occam*. 

.. code:: bash

  % open docs/readme.html
  
*Note:* If you would like to just try it out locally using Vagrant, you will within this file instructions for how to do so.

What is in the quickstart.html?
-------------------------------

The *docs/quickstart.html* file contains a quickstart tutorial for how to get an Havana cloud up and running on bare metal nodes using *Occam*. 

.. code:: bash

  % open docs/quickstart.html


Authors & Contributors
=======================

* James A. Kyle <james.kyle@att.com>
* Jerry A. Higgs <jerry.a.higgs@att.com>
* Ari Saha <ari.saha@att.com>
* Paul McGoldrick <paul.mcgoldrick@att.com>
* Erik Sundelof <eriks@att.com>
* Ashu Sharma <ashu.sharma@att.com>
* Tomasz Z. Napierała <tnapierala@mirantis.com>
* Piotr Misiak <pmisiak@mirantis.com>
* Kamil Świątkowski <kswiatkowski@mirantis.com>
* Damian Szeluga <dszeluga@mirantis.com>
* Michał Skalski <mskalski@mirantis.com>

.. _`OpenStack Havana Cloud Application`: http://github.com/att-innovate/occam-havana-cloud
.. _`Occam`: http://github.com/att-innovate/occam