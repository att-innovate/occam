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
# == Class: profile::puppet::master
#
# Configures puppet master.
#
# === Parameters
# [storeconfigs]
#   enable/disable storeconfigs
#
# [puppet_root]
#   path to puppet root
#
# [autosign]
#   enable/disable autosign
#
# [environment]
#   what environment to use
#
# === Examples
# class {'profile::puppet::master:
#   storeconfigs      = true,
#   puppet_root       = '/var/puppet',
#   autosign          = true,
#   environment       = 'production',
# }
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Ari Saha <as754m@att.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::puppet::master (
  $storeconfigs      = true,
  $puppet_root       = '/var/puppet',
  $autosign          = true,
  $environment       = 'production',
) {

  include profile::hiera::config

  $apps = hiera('profile::hiera::config::occam_apps')
  $env_path = "${puppet_root}/environments/\$environment"
  $mainmodulepath = "${env_path}/puppet/modules:${env_path}/puppet/occam/modules"
  $manifest = "${env_path}/puppet/manifests/site.pp"

  # Add main path + app specific module paths
  $modulepath = chop(inline_template('<%= @mainmodulepath %>:<% @apps.each do |app| %><%= @env_path %>/puppet/apps/<%= app %>/modules:<% end %>'))

  class { 'puppetdb':
    ssl_listen_address => '0.0.0.0',
    java_args          => { '-Xmx' => '4g' }
  }

  class {'::puppet::master':
    storeconfigs => true,
    modulepath   => $modulepath,
    manifest     => $manifest,
    autosign     => true,
    reports      => 'store,http',
  }

  # we want to  ensure puppet master has certain dns entries...it's a
  # chicken and egg situation with a dns server since we want to manage that
  # with puppet

  # set master to current fqdn
  Ini_setting {
    path    => '/etc/puppet/puppet.conf',
    require => Class['::puppet::master'],
    notify  => Service['httpd']
  }

  ini_setting {'mainserversetting':
    ensure  => present,
    section => 'main',
    setting => 'server',
    value   => $::fqdn
  }

  ini_setting {'masternodeterminussetting':
    ensure  => present,
    section => 'master',
    setting => 'node_terminus',
    value   => 'exec'
  }

  ini_setting {'masterexternalnodessetting':
    ensure  => present,
    section => 'master',
    setting => 'external_nodes',
    value   => '/opt/occamengine/bin/enc'
  }

  ini_setting {'masterreporturl':
    ensure  => present,
    section => 'master',
    setting => 'reporturl',
    value   => 'http://127.0.0.1:8160/api/puppet/report'
  }

  file {$puppet_root:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file { ["${puppet_root}/environments", "${puppet_root}/archive"]:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File[$puppet_root],
  }
}
