=========================
Prepare Occam environment
=========================

Occam repository needs to be prepared before development and deployment. This
includes initialization of all submodules, installation of apps and
initialization of their modules.

Checking out Occam repository
=============================
.. code:: bash

  % git checkout https://github.com/att-innovate/occam.git
  % cd occam

Setup RVM and install the necessary gems
========================================

1. Install rvm if you do not have it:

.. code:: bash

  % curl -sSL https://get.rvm.io | bash

2. Install the right ruby version:

.. code:: bash

  % rvm install ruby-1.8.7

.. note::

    Due to the 12.04 target platform, 1.8.7 is used. On some systems this no
    longer compiles cleanly. In such cases, v2.1.2 _should_ suffice.

3. Install the necessary gems

.. code:: bash

  % bundle install

Adding local configuration
==========================

Local configuration directory should contain everything needed to deploy your
zones. It's capable of storing as many zones as you need. Zone to deploy is
selected during installation process. It's the best to keep the configuration
as a git module, but you can just unpack a tarball with configuration if you
prefer.

Directory structure is as follows::

  local/
    hiera/
      fqdns/
      hostgroups/
      secrets/
      users/
      zones/
    ssl/

``local/ssl``
    This directory should contain SSL certificates in PEM format to be used in a
    zone. A rake task will put each file from this directory to
    puppet/modules/profile/files/ssl

``local/hiera``
    Directory that reflects part of the occam's hiera hierarchy. Most important
    (and the only one required) is a zones directory. There you should put yaml
    files with zones configuration. Others are optional, depending on your setup.
    Eg. you can use hiera gpg backend to store sensitive information like
    passwords. In that case just put gpg encrypted yaml file in secrets
    directory. The secrets directory takes precedens over zones one. See
    `Configuring Your Zone <configure_your_zone.html>`_ for reference.

If you have local conf ready, add it as a submodule at local directory:

.. code:: bash

  % git submodule add https://your.repo/config.git local
  % git submodule init
  % git submodule update

Initialization of Occam itself
==============================

Initialize occam:

.. code:: bash

  % rake occam:init

Installation and initialization of Occam application
====================================================

Occam applications are configured as a list in the zone file under the key
``profile::hiera::config::occam_apps``.

Application Naming Convention
------------------------------

Your application name should be occam-<your appname>.  app should be available
on github. Each entry references the github user account and the application
repository name. For example, the Havana Cloud Application is named
occam-havana-cloud and is in the att-innovate github organization. To include
this application in your deployment, you would add the entry in your zone file
something like

.. code-block:: yaml

    profile::hiera::config::occam_apps:
      - 'att-innovate/occam-havana-cloud'

Then you initialize the apps

.. code:: bash

  % rake apps:init

If you want to clear out all managed apps and start fresh, you can use the clean
task

.. code-block:: bash

    % rake apps:clean

