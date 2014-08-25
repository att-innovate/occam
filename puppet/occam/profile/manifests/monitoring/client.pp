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
# == Class: profile::monitoring::zabbix::agent
#
# Installs necessary packages.
#
# === Parameters
# [virtualhost_cluster_fqdn]
#   FQDN of host from which OpenStack cluster checks will be performed.
#
# === Authors
#
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
# === Copyright
#
# Copyright 2013 AT&T Foundry, unless otherwise noted.
class profile::monitoring::client (
  $virtualhost_cluster_fqdn = undef
){
  class { 'profile::monitoring::zabbix::agent':
    access_user              => hiera('profile::openstack::controller::nova_admin_user'),
    access_password          => hiera('profile::openstack::controller::nova_user_password'),
    keystone_db_user         => hiera('profile::openstack::controller::keystone_db_user'),
    keystone_db_password     => hiera('profile::openstack::controller::keystone_db_password'),
    glance_db_user           => hiera('profile::openstack::controller::glance_db_user'),
    glance_db_password       => hiera('profile::openstack::controller::glance_db_password'),
    nova_db_user             => hiera('profile::openstack::controller::nova_db_user'),
    nova_db_password         => hiera('profile::openstack::controller::nova_db_password'),
    cinder_db_user           => hiera('profile::openstack::controller::cinder_db_user'),
    cinder_db_password       => hiera('profile::openstack::controller::cinder_db_password'),
    quantum_db_user          => hiera('profile::openstack::controller::neutron_db_user'),
    quantum_db_password      => hiera('profile::openstack::controller::neutron_db_password'),
    rabbit_password          => hiera('profile::openstack::controller::rabbit_password'),
    public_address           => $::ipaddress_eth0,
    internal_address         => $::ipaddress_eth0,
    storage_address          => $::ipaddress_eth0,
    management_address       => $::ipaddress_eth0,
    virtualhost_cluster_fqdn => $virtualhost_cluster_fqdn,
    cluster_identifier       => $::zone
  }
  include profile::monitoring::logstash::app
}
