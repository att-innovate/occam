# Puppet module: profile

This is the puppet module to manage project profiles. A profile consists of one
or more roles and any site specific logic that needs to be performed for those 
classes. 

It may also include custom defines or types, additional libraries, or facts.

## USAGE - Basic management

* The default class is empty. A specific profile must be included.

* Install a hiera config file /etc/puppet/hiera.yaml.

    include profile::hiera::config

* Install/manage the puppet agent.

    include profile::puppet::agent

* Install/manage the puppet dashboard

    include profile::puppet::dashboard

* Install/manage the puppet master

    include profile::puppet::master

* Deploy user public keys to be installed for puppet repository access

    include profile::puppet::user_key

* Deploy base configuration profile, admin users, etc.

    include profile::base
