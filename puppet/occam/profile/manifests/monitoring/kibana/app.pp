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
# == Class: profile::monitoring::kibana::app
#
# Configures kibana
#
# === Authors
#
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
class profile::monitoring::kibana::app (
  $servername = $::fqdn
) {

  file { '/srv/www':
    ensure  => directory,
  }

  staging::deploy { 'kibana-3.1.0.tar.gz':
    source => 'https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz',
    target => '/srv/www',
    require => File['/srv/www']
  }

  include apache

  apache::vhost { 'kibana':
    port               => 81,
    priority           => '50',
    docroot            => '/srv/www/kibana-3.1.0',
    servername         => $servername,
    ssl                => false,
    require            => Staging::Deploy['kibana-3.1.0.tar.gz']
  }
}
