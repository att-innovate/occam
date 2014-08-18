=========================================
Occam - Deployment & Automation Framework
=========================================

:Authors & Contributors:

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

:Date: 2014-08-18

.. contents::

What is Occam
=============

The AT&T Foundry currently runs a number of diverse infrastructure projects in various sections - such as Compute, Storage, and PaaS frameworks - which all have vastly varying demands. To be able meet these demands, it was necessary to develop our own solution for automation, orchestration, hardware abstraction and provisioning. 

Our ultimate goal was to build a framework with excellent code quality, inline with industry standards and includes the obligatory abstraction layers. It was essential to make sure out development process introduces best practices for how all services included in the framework as we test various compositions as well as evaluate various underlying technology. The framework is called Occam and is a complete automation, orchestration, hardware abstraction and provisioning framework for to manage your infrastructure and services you run on top. 

The framework is built on using Puppet, OpenStack (hardware abstraction, virtualization) and using the proven development workflow consisting of Gitflow, continuous integration and Test-Driven Development (puppet-lint, spec). We wanted to make sure that the various zones have been brought up with integrity why Tempest was also introduced. Benchmark tests have also been introduced to allow us to properly monitor and test performance irrespectively of configuration of the zone.

The target deployment zone can easily be configured outside the code base using Hiera configuration files, which optionally can be encrypted using GPG to allow for better security on deployed versions of the zone, yet allow development to be more seamless. 

The Puppet orchestration layer is following the well-known role/profile paradigm, which allows us to abstract all local changes, and keep the original modules unmodified and intact. This does not only let us take advantage of the efforts within the larger community but also easily & promptly upgrade all components. It also allows us to introduce new and old components as we evaluate them. 

Currently we support deploying OpenStack Havana based clouds and other internal infrastructure  applications. These applications are self-contained entities that can be easily installed inside the Occam core. Using the cloud application and one occam repository users can deploy many separated clouds - so called zones - with completely different configuration.

We also ship ready to use Vagrant configuration for local development.

Occam consists of many components, from which most prominent are:

* Puppet + hiera + mcollective for automation and orchestration
* Occamengine for bare metal provisioning and external node classification (ENC)
* Logstash + Elasticsearch + Kibana for log collection and analysis
* Zabbix for monitoring


.. include:: docs/Concepts.rst

.. include:: docs/Components.rst

.. include:: docs/Structure.rst

.. include:: docs/Apps.rst

.. include:: docs/Prepare_environment.rst

.. include:: docs/Configure_your_zone.rst

.. include:: docs/Vagrant.rst

.. include:: docs/Production_deployment.rst

.. include:: docs/Development.rst

.. include:: docs/Tasks.rst

.. include:: docs/Cabling_and_Networking.rst

Additional Resources
====================

* `Hiera 1`_
* `Puppet`_
* `Git`_

.. _`Hiera 1`: http://docs.puppetlabs.com/hiera/1/index.html
.. _`Puppet`: http://docs.puppetlabs.com/puppet/
.. _`hiera data lookups`: http://docs.puppetlabs.com/hiera/1/hierarchy.html
.. _`automatic parameter lookup`: http://docs.puppetlabs.com/hiera/1/puppet.html#automatic-parameter-lookup
.. _`Git`: http://git-scm.com/documentation
.. _`Why aren't you using git-flow`: http://jeffkreeftmeijer.com/2010/why-arent-you-using-git-flow/
.. _`nvie's gitflow plugin`: https://github.com/nvie/gitflow
