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
# == Class: profile::network
#
# Configures network on server.
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::network {
  case $::osfamily {
    'Debian':   {
      include interfaces
      $interfaces = hiera_hash('interfaces', {})
      create_resources('interfaces::iface', $interfaces)

      package { 'ifenslave-2.6':
        ensure => latest,
      }
      package { 'vlan':
        ensure => latest,
      }
      package { 'ethtool':
        ensure => latest,
      }
      file { '/etc/modules':
        ensure => present
      }->
      file_line { 'bonding':
        line   => 'bonding',
        path   => '/etc/modules',
      }->
      file_line { '8021q':
        line   => '8021q',
        path   => '/etc/modules',
      }
      exec {'restart-networking':
        command     => '/sbin/ifdown -a && /sbin/ifup -a && sleep 10',
        subscribe   => File['/etc/network/interfaces'],
        refreshonly => true,
      }
      exec {'bonding':
        command    => '/sbin/modprobe bonding',
        unless     => '/sbin/lsmod | /bin/grep bonding',
      }
      exec {'vlan':
        command    => '/sbin/modprobe 8021q',
        unless     => '/sbin/lsmod | /bin/grep 8021q',
      }
    }
    default: {
      alert("Interface configuration on ${::osfamily} systems\
not yet supported by occam!")
    }
  }
}
