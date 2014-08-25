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
# == Class: profile::monitoring::elasticsearch::manage
#
# Configures elasticsearch.
#
# === Examples
#
# class {'profile::monitoring::elasticsearch::manage':}
#
# === Authors
#
# Bartosz Kupidura <bkupidura@mirantis.com>
# Tomasz 'Zen' Napierala <tnapierala@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::monitoring::elasticsearch::manage (
  $es_address = 'http://127.0.0.1:9200',
  $index_name = 'logstash',
  $retention_days = 14,
  $cron_user = 'root',
  $time_h = 5,
  $time_m = 00,
){

  if !defined(Package['python-pip']) {
    package { 'python-pip':
      ensure => latest,
    }
  }

  package { ['esclient', 'argparse']:
    ensure   => 'present',
    provider => 'pip',
    require  => Package['python-pip']
  }

  file { '/usr/sbin/es_delete_index.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/profile/elasticsearch/es_delete_index.py',
    require => Package['esclient', 'argparse'],
  }

  cron { 'es_delete_index':
    command => "/usr/sbin/es_delete_index.py -o ${retention_days} -n ${index_name} -e ${es_address}",
    user    => $cron_user,
    hour    => $time_h,
    minute  => $time_m,
    require => File['/usr/sbin/es_delete_index.py']
  }
}
