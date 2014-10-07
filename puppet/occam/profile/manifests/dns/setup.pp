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
# == Class: profile::dns::setup
#
# Performs tasks required as a prerequisite to dns server initialization.
#
# === Parameters
# [hostnames]
#   List of hostnames to set for the node in /etc/hosts
#
# === Examples
#   class {'profile::dns::setup':
#     hostnames => ['ops1.foo.com', 'puppet.foo.com']
#   }
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Ari Saha <as754m@att.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::dns::setup (
  $hostnames  = [],
  $ip = $::ipaddress_eth0,
) {

  $host_aliases = flatten([$::hostname, $hostnames])

  host { $::fqdn:
    ensure       => present,
    host_aliases => $host_aliases,
    ip           => $ip,
  }

  exec { 'remove 127.0.1.1 line':
    command => 'sed -i \'/127.0.1.1/d\' /etc/hosts',
    onlyif  => 'grep \'127.0.1.1\' /etc/hosts',
    path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
  }

}
