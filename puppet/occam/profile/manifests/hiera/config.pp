###############################################################################
##                                                                           ##
## The MIT License (MIT)                                                     ##
##                                                                           ##
## Copyright (c) 2014 AT&T Inc.                                              ##
##                                                                           ##
## Permission is hereby granted, free of charge, to any person obtaining     ##
## a copy of this software and associated documentation files                ##
## (the "Software"), to deal in the Software without restriction, including  ##
## without limitation the rights to use, copy, modify, merge, publish,       ##
## distribute, sublicense, and/or sell copies of the Software, and to permit ##
## persons to whom the Software is furnished to do so, subject to the        ##
## conditions as detailed in the file LICENSE.                               ##
##                                                                           ##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   ##
## OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                ##
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    ##
## IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      ##
## CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT ##
## OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR  ##
## THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                ##
##                                                                           ##
###############################################################################
# == Class: profile::hiera::config
#
# Manages the hiera config file.
#
# === Parameters
# [backend_confs]
#   Configures the hiera backend section. Takes a key/value form with the key
#   as the ini setting and the value as, well, the value.
#
# [hierarchy]
#   Configures the hierarchy list.
#
# [backends]
#   List of supported backends.
#
# === Examples
#
# class {'profile::hiera::config':
#   backend_confs => {
#     'yaml' => {
#       'datadir' => '/var/puppet/environments/%{environment}/puppet/hiera'
#     },
#     'gpg'  => {
#       'datadir' => '/var/puppet/environments/%{environment}/puppet/hiera',
#       'key_dir' => '/etc/puppet/keyrings'
#     },
#   },
#   hierarchy => [
#     'secrets/%{::zone}',
#     'fqdns/%{::fqdn}',
#     'zones/%{::zone}',
#     'hostgroups/%{::hostgroup}',
#     'users',
#     'common',
#   ],
#   backends => ['yaml', 'gpg']
# }
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::hiera::config (
  $occam_apps = ['cloud']
) {

  $backend_confs = {
    'gpg'  => {
      'datadir' => '/var/puppet/environments/%{::environment}/puppet/hiera',
      'key_dir' => '/etc/puppet/keyrings'
    },
    'yaml' => {
      'datadir' => '/var/puppet/environments/%{::environment}/puppet/hiera'
    },
  }

  $hierarchy_top = [
    "local/secrets/${::zone}",
    'local/fqdns/%{::fqdn}',
    "local/zones/${::zone}",
    'local/hostgroups/%{::hostgroup}',
    'local/users/users',
    'users/users_occam'
  ]

  $hierarchy_bottom = [
    'occam',
    'common',
  ]
  $backends = ['gpg', 'yaml', 'puppetdb']

  file {'/etc/puppet/hiera.yaml':
    ensure  => present,
    mode    => '0644',
    owner   => puppet,
    group   => puppet,
    content => template('profile/hiera/hiera.yaml.erb'),
  }

  package {'build-essential': }
  package {'hiera-gpg':
    ensure   => present,
    provider => 'gem',
    require  => Package['build-essential']
  }

}
