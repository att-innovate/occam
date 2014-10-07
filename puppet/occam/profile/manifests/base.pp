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
# == Class: profile::base
#
# Includes all the core configurations needed for an occam server. These include:
#   - foundry users
#   - networking
#   - puppet agent
#   - firewall pre/post configurations
#   - timezone configuration
#
# === Parameters
# [timezone]
#   timezone to configure servers with. default: UTC
#
# === Examples
#
# include profile::base
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Ari Saha <as754m@att.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::base (
  $timezone   = 'UTC',
  $ntp_servers = [ '0.us.pool.ntp.org', '1.us.pool.ntp.org' ],
  $purge_sudo = false,
  $monitoring = false,
  $deb        = [ 'profile::system::debian', 'apt::unattended_upgrades' ],
) {

  include stdlib
  include profile::users::create
  include profile::network
  include profile::puppet::agent
  include profile::firewall::pre
  #include profile::firewall::post
  include profile::mcollective
  include ::firewall
  include ::puppet::repo::puppetlabs

  if str2bool($monitoring) {
    include profile::monitoring::client
  }

  class {'profile::dns::setup': stage => 'setup' }

  class {'::sudo':
    purge => $purge_sudo,
  }

  class { '::ntp':
    servers  => $ntp_servers,
    restrict => ['127.0.0.1'],
  }

  Firewall {
    #before  => Class['profile::firewall::post'],
    require => Class['profile::firewall::pre'],
  }

  $sudo_confs = hiera_hash('sudo_confs', {})
  create_resources('sudo::conf', $sudo_confs)

  case $::osfamily {
    'RedHat': { include profile::system::redhat }
    'Debian': { include $deb }
    default:  { alert("${::osfamily} family is not supported!") }
  }

  class { 'timezone': timezone => $timezone }

  Profile::Users::Managed<| groups == foundry  |>
  Apt::Source<| |> -> Package<| title != 'ubuntu-cloud-keyring' and
                                title != 'python-software-properties' |>

  if $::virtual == 'virtualbox' {
    notify {"Virtualbox guest detected": }
    include profile::vagrant_guest
  }

}
