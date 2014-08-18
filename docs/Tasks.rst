========================
Occam rake tasks
========================

rake apps:init[app]
========================

  Takes one parameter: **app**.

  Initializes **app** in **puppet/app/cloud/appname** dir using r10k with data provided in **puppet/app/cloud/appname/Puppetfile**

rake apps:init_all
=================================

  Initializes all apps.

rake config:generate[zonename]
=================================

  Takes one parameter: **zonename**.

  Generates Occam config and writes it to **puppet/hiera/zones/zonename.yaml** file (or **puppet/hiera/zones/example_file.yaml** if argument is not provided).

  This will ask you series of questions regarding your ENV and will match your answers against regexes in **lib/files/generator.yaml**.

  You should edit the file afterwards f.e. to change root password.

rake doc:build
=================================

  This tasks converts rst docs to html. 
  
.. Attention::
    It is dependent on you having rst2html available in your local environment. To install on a Mac please use the following command: 

    .. code:: bash

      % easy_install docutils && easy_install pygments

rake occam:deploy_initial[server,port]
======================================

  Takes two parameters: **server** and **port**.

  This task requires you to have installed vanilla Ubuntu Server.
  It will:

  * Initialize necessary modules
  * Prepare archive
  * Send it using scp to **server**
  * Decompress archive
  * Run bootstrap.sh script (which can be found in utils/bootstrap.sh).

.. WARNING::
    It should be the first step performed when deploying Occam. It also should be used **ONLY ONCE**.


rake occam:init
===============

  This tasks performs initalization of Occam modules.

  It uses **puppet/occam/Puppetfile** as a source of necessary modules.

rake occam:prepare_archive[key]
===============================

  Takes one parameter: **key**.

  This task will create Occam archive that will be use used by deploy_initial and update_code tasks.

  Usually it won't be called directly.

rake occam:update_code[server,port]
===================================

  Takes two parameters: **server** and **port**.

  This task will:

  * Create archive using current state of Occam repository
  * Send it using scp to **server**
  * Decompress archive in **/var/puppet/archive**
  * Create necessary symlinks
  * Reload puppet to serve new code to the clients.

.. WARNING::
    This task should be used to upload code **AFTER** occam:deply_initial has been performed.

rake spec
=================================

  This task will perform spec tests on:

  * manifests with:

    * Puppet Face validator (for syntax)
    * **puppet-lint** (for lint failures;))

  * erbs with **erb -P -x -T erbfile | ruby -c**
  * yamls with: **ruby yaml parser**
  * librarian files (Puppetfile) with **r10k  puppetfile check**

rake tempest:download_junit_from_host[server,port]
==================================================

  Takes two parameters: **server** and **port**.

  This task will download **/var/lib/tempest/results.xml** from **server** to local dir.

  This is currently used only by bamboo as a workaround.

rake tempest:make_sure_that_cloud_is_complete[server,port]
==========================================================

  Takes two parameters: **server** and **port**.

  This task runs **wait_for_cloud_complete.rb** script on **server**.

  This is used to ensure that necessary number of puppet runs have been performed in order to start tempest.

rake tempest:run_tests_on_ops_node[server,port]
===============================================

  Takes two parameters: **server** and **port**.

  This task is used to start tempest run on **server**.

Other
=================================

  There are few more rake tasks in repo which will be shown when an **app** is available.

  They should conform **appname:init** naming scheme.

