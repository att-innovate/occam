==================
Occam applications
==================

Introduction
============

Occam can deploy virtually any application that can be configured using ops node (e.g. puppet etc.) The cloud application is only one example of such an application but it can literally be any application.


Application structure
=====================
Each Occam's application should be placed in *puppet/apps/app_name* directory. Structure of an application is quite simple::


  puppet/apps/app_name/
    hiera/
      app_name.yaml
    profile/
      files/
      lib/
      manifests/
      templates/
    role/
      files/
      lib/
      manifests/
      templates/
    tasks/
      appinit.rake
    Puppetfile


Configuration
-------------

``puppet/apps/app_name/hiera/app_name.yaml``

This is a file with configuration options for an application and is a part of hiera database. In general this is a place where profile parameters should be defined.

Profiles
--------

``puppet/apps/app_name/profile/``

Profile directory is for that part of puppet's profile module that is related to the application. During deployment process this directory content is merged with puppet/modules/profile directory to build complete profile puppet module. Anything except manifests directory is optional and depends on application requirements.

Roles
-----

``puppet/apps/app_name/role/``

Profile directory is for that part of puppet's role module that defines application roles for nodes. During deployment process this directory content is merged with puppet/modules/role directory to build complete role puppet module. Just like in profile module, anything except manifests directory is optional and depends on application requirements.


Tasks
-----

Tasks directory should contain applinit.rake file with task init in app_name namespace. This task will be called during installation. Example appinit.rake file:

.. code:: ruby

  namespace :example do
    desc 'Example app initialization'
    task :init do
      app = 'example'
      puts 'Init of Example app'
      run "cd puppet/apps/#{app} && r10k -t -v DEBUG2 puppetfile install"
    end
  end


Modules
-------

All puppet modules required by application need to be present in puppet/apps/app_name/modules/ directory after invoking rake init task of the application. You can use Puppetfile and provided appinit.rake example to initialize modules this way (please refer r10k ruby gem for Puppetfile format). You can of course provide modules directory inside of the application and dummy rake init task, or you can pick different method to do so.
