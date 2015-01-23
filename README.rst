================
Occam Quickstart
================

:Authors: James A. Kyle
:Date: 2015-01-23

Introduction
============

Occam is a framework for deploying `Foreman`_ manged puppet infrastructure. It
uses `Ansible`_ for the initial bootstrapping of a Foreman ops server and
`r10k`_ for managing puppet environments.

By default, the project is configured to deploy the occam openstack
environments, but is easily configured for any arbitrary set of puppet modules.

Dependencies
============

Required
--------

In addition to the dependencies listed in ``requirements.txt``, you also need
the following if you wish to run the demo environment

- VMware >= 6.0
- Vagrant >= 1.7.2
- VMware Vagrant Plugin

.. note::  Virtualbox support is being worked on.


Recommended
-----------

The following tools are recommended, but not required. Their usage is beyond
the scope of this document, but will make your life easier. Think kittens and
puppies, cold beer and bbq rather than stubbed toes and hangnails.

- `pip`_
- `virtualenvwrapper`_

Installation
------------

Install all python dependencies.

Using pip.

.. code::

    % pip install -r requirements.txt

Using easy_install.

.. code::
    
    % easy_install `cat requirements.txt`

.. note:: Depending on your setup, you may need to run as administrator.
    

Demo Environment
================

Validate
--------

To validate the required tools are installed and can be found

.. code::

    % inv validate

You should receive an 'OK' or a 'FAIL' for each check. All 'FAIL' returns
should be resolved or demo environment may not work.


Start a Demo Enviroment
-----------------------

To start the demo environment.

.. code::

    % inv demo.start


When the ops node has finished provisioning, the password to the foreman server
is printed to stdout. It should look something like

.. code::

    TASK: [bootstrap | debug var=foreman_password.stdout_lines] *******************
    ok: [ops1] => {
        "var": {
            "foreman_password.stdout_lines": [
                "fwmKPmVrpZn2AKoX"
            ]
        }
    }

Username `admin` and this password can be used to login to the foreman server at 
`https://ops1.zone1.example.com`_.

Community, discussion and support
=================================

Any questions or want to start contributing, you can contact any of the
`Authors & Contributors`_. We also have an `#occam`_ channel on Freenode's IRC.

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
.. _`#occam`: http://webchat.freenode.net/?channels=occam
.. _`Foreman`: http://theforeman.org/
.. _`Ansible`: http://www.ansible.com/home
.. _`r10k`: https://github.com/adrienthebo/r10k
.. _`pip`: https://pip.pypa.io/en/latest/
.. _`virtualenvwrapper`: https://virtualenvwrapper.readthedocs.org/en/latest/
.. _`https://ops1.zone1.example.com`: https://ops1.zone1.example.com
