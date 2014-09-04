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
# == Class: profile::monitoring::logstash::app
#
# Installs the logstash on a host
#
# === Examples
#
#   include profile::monitoring::logstash::app
#
# === Authors
#
# James Kyle <james@jameskyle.org>
# Tomasz 'Zen' Napierala <tnapierala@mirantis.com>
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::monitoring::logstash::app (
  $collector = 'monit1',
  $elasticsearch_cluster_name = 'logstash'
) {

  class { 'logstash':
    status         => 'enabled',
    java_install   => true,
    java_package   => 'openjdk-7-jre-headless',
    manage_repo    => true,
    repo_version   => '1.4',
    init_template  => 'profile/monitoring/logstash/logstash.init.erb',
  }

  if ! defined(Package['libzmq1']) {
    package { 'libzmq1':
      ensure  => installed,
    }
  }
  if ! defined(Package['libzmq-dev']) {
    package { 'libzmq-dev':
      ensure  => installed,
    }
  }

  # client or server selection:
  if defined_in_catalog('profile::monitoring::elasticsearch::cluster') {

    logstash::configfile { 'input_zeromq':
      content => template('profile/monitoring/logstash/input_zeromq.erb'),
      require  => [ Package['libzmq1'], Package['libzmq-dev'] ],
    }

    logstash::configfile { 'output_elasticsearch':
      content => template('profile/monitoring/logstash/output_elasticsearch.erb')
    }

  } else {

    logstash::configfile { 'output_zeromq':
      content => template('profile/monitoring/logstash/output_zeromq.erb'),
      require => [ Package['libzmq1'], Package['libzmq-dev'] ],
    }

  }

  package { 'acl':
    ensure => installed,
    before => Service['logstash']
  }

  logstash::patternfile { 'extra_patterns':
     source => 'puppet:///modules/profile/monitoring/logstash/patterns/extras'
   }


  logstash::configfile { 'input_file_syslog':
    source => 'puppet:///modules/profile/monitoring/logstash/input_file_syslog'
  }
  logstash::configfile { 'filter_syslog':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_syslog'
  }


  #apache
  logstash::configfile { 'input_file_apache-access':
    source => 'puppet:///modules/profile/monitoring/logstash/input_file_apache-access'
  }
  logstash::configfile { 'filter_grok_apache-access':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_grok_apache-access'
  }
  logstash::configfile { 'input_file_apache-error':
    source => 'puppet:///modules/profile/monitoring/logstash/input_file_apache-error'
  }
  logstash::configfile { 'filter_grok_apache-error':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_grok_apache-error'
  }


  #RabbitMQ
  logstash::configfile { 'input_file_rabbitmq':
    source => 'puppet:///modules/profile/monitoring/logstash/input_file_rabbitmq'
  }
  logstash::configfile { 'filter_multiline_rabbitmq':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_multiline_rabbitmq'
  }
  logstash::configfile { 'filter_grok_rabbitmq':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_grok_rabbitmq'
  }


  #Libvirt
  logstash::configfile { 'input_file_libvirt':
    source => 'puppet:///modules/profile/monitoring/logstash/input_file_libvirt'
  }
  logstash::configfile { 'filter_grok_libvirt':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_grok_libvirt'
  }


  # Keystone
  logstash::configfile { 'input_file_openstack':
    source => 'puppet:///modules/profile/monitoring/logstash/input_file_openstack'
  }
  logstash::configfile { 'filter_openstack':
    source => 'puppet:///modules/profile/monitoring/logstash/filter_openstack'
  }


}
