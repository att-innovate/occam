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
# == Class: profile::mcollective
#
# Configures mcollective server/client/broker.
#
# === Parameters
# [broker_host]
#   hostname for activemq
#
# === Examples
#
# class { 'profile::mcollective':
#  broker_host => 'puppet'
# }
#
# === Authors
#
# Damian Szeluga <dszeluga@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::mcollective(
  $broker_host = 'puppet'
) {
  if $::hostname == hiera('profile::mcollective::orchestrator') {
    class {'::mcollective':
      client            => true,
      server            => true,
      middleware        => true,
      connector         => 'rabbitmq',
      middleware_hosts  => [ $broker_host ],
    }
    package {'mcollective-puppet-agent':
      ensure => 'present',
      notify => Service['mcollective'],
    }
    package {'mcollective-puppet-client':
      ensure => 'present',
    }
  } else {
    class { '::mcollective':
      server            => true,
      connector         => 'rabbitmq',
      middleware_hosts  => [ $broker_host ],
    }
    package {'mcollective-puppet-agent':
      ensure => 'present',
      notify => Service['mcollective'],
    }
  }
}
