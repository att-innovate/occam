Repository structure
====================

Folders:

* puppet - contains puppet modules, hiera configuraion, roles, profiles, apps,
* lib - rake tasks supporting occam deployment and maintenance
* spec - scripts mainly for testing Occam code for errors
* utils - auxiliary scripts

Files:

* spec/lint-ignore-list - list of ignores for lint testing
* spec/lint-tested-directories - list of modules which will be tested against puppet-lint
* Rakefile - main rake file that includes tasks from lib folder
* tempest-disabled-tests - tests disabled during tempest run
* Vagrantfile - vagrant configuration for local Occam development
