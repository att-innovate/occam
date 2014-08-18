=========================
Prepare Occam environment
=========================

Occam repository needs to be prepared before development and deployment. This includes initialization of all submodules, installation of apps and initialization of their modules.

Checking out Occam repository
=============================
.. code:: bash

  % git checkout http://github.com/att/ocam.git
  % cd occam

Setup RVM and install the necessary gems
========================================

1. Install rvm if you do not have it:

.. code:: bash

  % curl -sSL https://get.rvm.io | bash
  
2. Install the right ruby version:

.. code:: bash

  % rvm install ruby-2.0.0
  
3. Install the necessary gems

.. code:: bash

  % bundle install

Adding local configuration
==========================

Local configuration directory should contain everything needed to deploy your zones. It's capable of storing as many zones as you need. Zone to deploy is selected during installation process. It's the best to keep the configuration as a git module, but you can just unpack a tarball with configuration if you prefer.

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

This directory should contain ssl certificates in PEM format to be used in a zone. Rake task will put each file from this directory to puppet/modules/profile/files/ssl

``local/hiera``

Directory that reflects part of the occam's hiera hierarchy. Most important (and the only one required) is a zones directory. There you should put yaml files with zones configuration. Others are optional, depending on your setup. Eg. you can use hiera gpg backend to store sensitive information like passwords. In that case just put gpg encrypted yaml file in secrets directory. Secrets directory takes precedens over zones one. See `Configuring Your Zone`_ for reference.

If you have local conf ready, add it as a submodule at local directory:

.. code:: bash

  % git submodule add https://your.repo/config.git local
  % git submodule init
  % git submodule update

Initialization of occam itself
==============================

Initialize occam:

.. code:: bash

  % rake occam:init

Installation and initialization of occam application
====================================================

Install cloud app:

.. code:: bash

  % rake apps:install https://github.com/att/occam_cloud.git cloud

Initialize app:

.. code:: bash

  % rake apps:init_all
