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
#
# Defined Type that creates a dns host entry and optionally as a dhcp record for
# assigning the ip to the specific mac.
#
#
# === Parameters
#
# [file] The name of the host file created in /etc/hosts.d
# [ip] The ip of the host
# [notify_class] name of the class to notify of any changes
# [hostnames] an array of hostnames for ip
# [mac] the mac address of the given host.
#
# === Examples
# profile::dns::host {'mail1':
#   ip             => "192.168.1.100",
#   notify_class   => "dnsmasq::service",
#   hostnames      => [$title],
#   mac            => undef,
# }
#

define profile::dns::host (
  $file           = $title,
  $ip             = '192.168.1.100',
  $notify_class   = 'dnsmasq::service',
  $hostnames      = [$title],
  $mac            = undef,
) {
  include stdlib

  if $mac != undef {
    dnsmasq::conf {$title:
      content => "dhcp-host=${mac},${title},${ip}\n",
    }
  }

  if is_array($hostnames) {
    $real_hostnames = join($hostnames, ' ')
  } else {
    $real_hostnames = $hostnames
  }

  if ! defined(Concat["/etc/hosts.d/${file}"]) {
    concat { "/etc/hosts.d/${file}":
      mode    => 0644,
      owner   => root,
      group   => root,
      require => File['/etc/hosts.d'],
      notify  => Class[$notify_class],
    }
  }

  if ! defined(File['/etc/hosts.d']) {
    file {'/etc/hosts.d':
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
    }
  }

  concat::fragment {$name:
    target  => "/etc/hosts.d/${file}",
    content => inline_template("<%= @ip %> <%= @real_hostnames %>\n")
  }
}

