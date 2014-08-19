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
# == Class: profile::firewall::post
#
# Post configuration for firewalls. This tasks frees up all traffic on private
# subnets and sets a default rule of drop at order 999.
# TODO make subnets configurable
#
# === Examples
#
# include profile::firewall::post
#
# === Authors
#
# James Kyle <james@jameskyle.org>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.

class profile::firewall::post {
  firewall { '995 accept all private 1':
    proto       => 'all',
    action      => 'accept',
    destination => '10.0.0.0/8',
  }->
  firewall { '996 accept all private 1':
    proto       => 'all',
    action      => 'accept',
    destination => '172.16.0.0/12',
  }->
  firewall { '997 accept all private 1':
    proto       => 'all',
    action      => 'accept',
    destination => '192.168.0.0/16',
  }->
  firewall { '998 accept public 1':
    proto       => 'all',
    action      => 'accept',
    destination => '74.175.26.0/24',
  }->
  firewall { '999 drop all':
    proto   => 'all',
    action  => 'drop',
    before  => undef,
  }
}

