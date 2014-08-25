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
# == Class: profile::monitoring::elasticsearch::cluster
#
# Configures elasticsearch.
#
# === Examples
#
# class {'profile::elasticsearch::cluster':}
#
# === Authors
#
# Bartosz Kupidura <bkupidura@mirantis.com>
# Tomasz 'Zen' Napierala <tnapierala@mirantis.com>
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::monitoring::elasticsearch::cluster (
  $es_blkdev = undef,
  $cluster_name = 'logstash'
) {

  if ( $es_blkdev != undef ) {
    exec { "fstab ${es_blkdev}":
      command => "echo '${es_blkdev} /var/lib/elasticsearch  ext4  defaults  0 2' >> /etc/fstab",
      unless  => "grep  ${es_blkdev} /etc/fstab",
      path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      before  => Class['::elasticsearch'],
      notify  => Exec["mkfs.ext4 ${es_blkdev}"],
    }
    exec { "mkfs.ext4 ${es_blkdev}":
      command     => "mkfs.ext4 ${es_blkdev}",
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      before      => Class['::elasticsearch'],
      refreshonly => true,
      notify      => Exec["mount ${es_blkdev}"],
    }
    exec { "mount ${es_blkdev}":
      command     => 'mkdir -p /var/lib/elasticsearch && mount /var/lib/elasticsearch',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin'],
      before      => Class['::elasticsearch'],
      refreshonly => true,
    }
  }
  class { '::elasticsearch':
    version => '1.1.1',
    manage_repo  => true,
    repo_version => '1.1',
    datadir => '/var/lib/elasticsearch',
    config       => {
      'cluster'    => {
        'name'       => $cluster_name
      },
      'index'      => {
        'number_of_replicas' => '0',
        'number_of_shards'   => '5'
      },
      'network'    => {
        'host'       => $::ipaddress
      }
    }
  }

  elasticsearch::instance { "es-${::hostname}": }

}
