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
# == Class: profile::dns::server
#
# Configures dnsmasq
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Damian Szeluga <dszeluga@mirantis.com>
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::dns::server (
  $nameservers     = ['8.8.8.8', '8.8.4.4'],
  $ntpservers      = ['66.175.209.17',
                      '184.22.183.134',
                      '50.23.135.154',
                      '72.8.140.240'],
  $domain          = $::domain,
  $interface       = undef,
  $dhcp_range      = '192.168.1.100,192.168.1.200,12h',
  $vm_dhcp_range   = '172.16.1.100,172.16.1.200,12h',
  $gateway         = '192.168.1.1',
  $network         = '192.168.1.0/24',
  $address         = $::ipaddress_eth0,
) {
  include dnsmasq
  include stdlib

  # Set up default dnsmasq::confs
  $real_ntpservers = join($ntpservers, ',')

  dnsmasq::conf {'resolv-file':
    content => "resolv-file=/etc/resolv.conf.dnsmasq\n",
  }
  if $interface {
    dnsmasq::conf {'iface':
      content => "interface=${interface}\nbind-interfaces\n"
    }
  }
  dnsmasq::conf {'ntpservers':
    content => "dhcp-option=option:ntp-server,${real_ntpservers}\n"
  }
  dnsmasq::conf {'dns-server':
    content => "dhcp-option=option:dns-server,${address}\n"
  }
  dnsmasq::conf {'no-hosts':    content => "no-hosts\n" }
  dnsmasq::conf {'dhcp-range':  content => "dhcp-range=${dhcp_range}\n" }
  if $vm_dhcp_range {
    dnsmasq::conf {'vm-dhcp-range':
      content => "dhcp-range=${vm_dhcp_range}\n"
    }
  }

  dnsmasq::conf {'dhcp-boot':
    content => "dhcp-match=set:ipxe,175\ndhcp-boot=tag:!ipxe,undionly.kpxe\ndhcp-boot=occamengine.ipxe\n"
  }
  dnsmasq::conf {'expand':
    content => "expand-hosts\n"
  }
  dnsmasq::conf {'addn-hosts':
    content => "addn-hosts=/etc/hosts.d/\n"
  }
  dnsmasq::conf {'gateway':
    content => "dhcp-option=3,${gateway}\n"
  }
  dnsmasq::conf {'net':
    content => "domain=${domain},${network}\n"
  }
  dnsmasq::conf {'occam':
    content => "dhcp-hostsfile=/etc/occam/reservations\n"
  }
  dnsmasq::conf {'tftp':
    content => "enable-tftp\ntftp-root=/opt/occamengine/tftp\n"
  }

  $confs = hiera_hash('dnsmasq_confs', {})
  create_resources('dnsmasq::conf', $confs)

  if is_array($nameservers) {
    $real_nameservers = join(prefix($nameservers, 'nameserver '), "\n")
  } else {
    $real_nameservers = "nameserver ${nameservers}"
  }

  file {'/etc/rsyslog.d/100-dnsmasq.conf':
    ensure  => present,
    content => ":programname, isequal, \"dnsmasq\"  /var/log/dnsmasq.log\n\
:programname, isequal, \"dnsmasq-dhcp\"  /var/log/dnsmasq.log\n\
:programname, isequal, \"dnsmasq-tftp\"  /var/log/dnsmasq.log\n",
    require => Class['dnsmasq'],
  }

  file { '/etc/resolv.conf.dnsmasq':
    ensure  => present,
    content => inline_template('<%= @real_nameservers %>'),
    notify  => Service['dnsmasq']
  }

  concat { '/etc/default/dnsmasq':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['dnsmasq']
  }

  concat::fragment { 'dnsmasq_default_file':
    target  => '/etc/default/dnsmasq',
    content => "IGNORE_RESOLVCONF=yes\nDOMAIN_SUFFIX=${domain}\nENABLED=1\n"
  }
}
