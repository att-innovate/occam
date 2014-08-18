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
# == Class: profile::occamengine
#
# Configures OccamEngine on ops node.
#
# === Parameters
# [address]
#   ip address of ops node
#
# [kernel_version]
#   package name of ubuntu kernel
#
# [os_root_device]
#   block device name passed to debian installer used as root device
#
# [domain]
#   domain name of occam installation
#
# [timezone]
#   timezone for installed systems
#
# === Examples
#
# class { 'profile::occamengine':
#  $kernel_version   = 'linux-generic-lts-saucy',
# }
#
# === Authors
#
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2014 AT&T Foundry, unless otherwise noted.
#
class profile::occamengine (
  $address              = undef,
  $kernel_version       = 'linux-generic-lts-trusty',
  $os_root_device       = '/dev/sda',
  $domain               = undef,
  $timezone             = 'UTC',
)
{

  package { 'sinatra':
    ensure   => installed,
    provider => 'gem',
  }

  package { 'sequel':
    ensure   => installed,
    provider => 'gem',
  }

  package { 'thin':
    ensure   => installed,
    provider => 'gem',
  }

  package { 'macaddr':
    ensure   => installed,
    provider => 'gem',
  }

  package { 'ipxe':
    ensure   => installed,
  }

  $oe_dirs = [  '/opt/occamengine',
                '/opt/occamengine/bin',
                '/opt/occamengine/db',
                '/opt/occamengine/pxe',
                '/opt/occamengine/tftp',
                '/opt/occamengine/pxe/default',
                '/opt/occamengine/pxe/default/image',
                '/opt/occamengine/pxe/default/templates',
                '/var/log/occam',
                '/var/run/occam'
              ]

  if ! defined(File['/etc/occam']) {
    file { '/etc/occam':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }

  file { $oe_dirs:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/occam'],
  }

  file { '/opt/occamengine/bin/enc':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/occamengine/enc',
    require => File[$oe_dirs]
  }

  file { '/etc/occam/occamengine.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/occamengine/occamengine.yaml.erb'),
    require => File[$oe_dirs]
  }

  file { '/opt/occamengine/bin/occamengine':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/occamengine/occamengine',
    require => [
                  File[$oe_dirs],
                  File['/etc/occam/occamengine.yaml'],
                  Package['sinatra'],
                  Package['sequel'],
                  Package['thin'],
                  Package['macaddr'],
                ],
  }

  file {'/etc/init/occamengine.conf':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/profile/occamengine/occamengine.conf.upstart',
    require => File['/opt/occamengine/bin/occamengine']
  }

  file { '/etc/init.d/occamengine':
    ensure  => link,
    target  => '/lib/init/upstart-job',
    require => File['/etc/init/occamengine.conf']
  }

  file { '/etc/logrotate.d/occamengine':
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///modules/profile/occamengine/occamengine.logrotate',
  }
  service {'occamengine':
    ensure    => running,
    enable    => true,
    require   => File['/etc/init.d/occamengine'],
    subscribe => [
                    File['/etc/occam/occamengine.yaml'],
                    File['/opt/occamengine/bin/occamengine'],
                  ]
  }

  file { '/opt/occamengine/pxe/default/templates/preseed.erb':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/occamengine/preseed.erb.erb'),
    require => File[$oe_dirs]

  }

  file { '/opt/occamengine/pxe/default/templates/boot_install.erb':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/occamengine/boot_install.erb',
    require => File[$oe_dirs]
  }

  file { '/opt/occamengine/pxe/default/templates/boot_local.erb':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/occamengine/boot_local.erb',
    require => File[$oe_dirs]
  }

  file { '/opt/occamengine/pxe/default/templates/puppetconf.erb':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/profile/occamengine/puppetconf.erb',
    require => File[$oe_dirs]
  }

  file { '/opt/occamengine/tftp/occamengine.ipxe':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/occamengine/occamengine.ipxe.erb'),
  }

  staging::file { 'netboot-precise-linux':
    target  => '/opt/occamengine/pxe/default/image/linux',
    source  => 'http://archive.ubuntu.com/ubuntu/dists/precise-updates/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/linux',
    require => [
      File[$oe_dirs]
    ],
  }

  staging::file { 'netboot-precise-initrd':
    target  => '/opt/occamengine/pxe/default/image/initrd.gz',
    source  => 'http://archive.ubuntu.com/ubuntu/dists/precise-updates/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/initrd.gz',
    require => [
      File[$oe_dirs]
    ],
  }

  file { '/opt/occamengine/tftp/undionly.kpxe':
    ensure => link,
    target => '/usr/lib/ipxe/undionly.kpxe',
  }

}
