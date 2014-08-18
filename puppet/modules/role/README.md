# Puppet module: role

This is a Puppet module for role.
It manages its installation, configuration and service.

The blueprint of this module is from http://github.com/Example42-templates/

Released under the terms of Apache 2 License.


## USAGE - Basic management

* Install role with default settings (package installed, service started, default configuration files)

        class { 'role': }

* Remove role package and purge all the managed files

        class { 'role':
          ensure => absent,
        }

* Install a specific version of role package

        class { 'role':
          version => '1.0.1',
        }

* Install the latest version of role package

        class { 'role':
          version => 'latest',
        }

* Enable role service (both at boot and runtime). This is default.

        class { 'role':
          status => 'enabled',
        }

* Disable role service (both at boot and runtime)

        class { 'role':
          status => 'disabled',
        }

* Ensure service is running but don't manage if is disabled at boot

        class { 'role':
          status => 'running',
        }

* Ensure service is disabled at boot and do not check it is running

        class { 'role':
          status => 'deactivated',
        }

* Do not manage service status and boot condition

        class { 'role':
          status => 'unmanaged',
        }

* Do not automatically restart services when configuration files change (Default: true).

        class { 'role':
          autorestart => false,
        }

* Enable auditing (on all the arguments)  without making changes on existing role configuration *files*

        class { 'role':
          audit => 'all',
        }

* Module dry-run: Do not make any change on *all* the resources provided by the module

        class { 'role':
          noops => true,
        }


## USAGE - Overrides and Customizations
* Use custom source for main configuration file 

        class { 'role':
          source => [ "puppet:///modules/example42/role/role.conf-${hostname}" ,
                      "puppet:///modules/example42/role/role.conf" ], 
        }


* Use custom source directory for the whole configuration dir.

        class { 'role':
          dir_source       => 'puppet:///modules/example42/role/conf/',
        }

* Use custom source directory for the whole configuration dir purging all the local files that are not on the dir_source.
  Note: This option can be used to be sure that the content of a directory is exactly the same you expect, but it is desctructive and may remove files.

        class { 'role':
          dir_source => 'puppet:///modules/example42/role/conf/',
          dir_purge  => true, # Default: false.
        }

* Use custom source directory for the whole configuration dir and define recursing policy.

        class { 'role':
          dir_source    => 'puppet:///modules/example42/role/conf/',
          dir_recursion => false, # Default: true.
        }

* Use custom template for main config file. Note that template and source arguments are alternative. 

        class { 'role':
          template => 'example42/role/role.conf.erb',
        }

* Use a custom template and provide an hash of custom configurations that you can use inside the template

        class { 'role':
          template => 'example42/role/role.conf.erb',
          options  => {
            opt  => 'value',
            opt2 => 'value2',
          },
        }

* Specify the name of a custom class to include that provides the dependencies required by the module for full functionality. Use this if you want to use alternative modules to manage dependencies.

        class { 'role':
          dependency_class => 'example42::dependency_role',
        }

* Automatically include a custom class with extra resources related to role.
  Here is loaded $modulepath/example42/manifests/my_role.pp.
  Note: Use a subclass name different than role to avoid order loading issues.

        class { 'role':
          my_class => 'example42::my_role',
        }

## TESTING
[![Build Status](https://travis-ci.org/example42/puppet-role.png?branch=master)](https://travis-ci.org/example42/puppet-role)
