Configuring Your Zone
=====================

This step entails the creation of your Occam configuration files. The configuration files use hiera - a key/value lookup tool for configuration data - built to make Puppet better and let you set node-specific data without repeating yourself. Hiera loads the hierarchy from the hiera.yaml config file.

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

You can also generate zone file using rake task `config:generate <Tasks.rst#rake-configgeneratezonename>`_

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
