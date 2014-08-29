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
# == Class: profile::monitoring::zabbix
#
# Set up a Zabbix monitoring
#
# === Parameters
#
# === Authors
#
# Kamil Swiatkowski <kswiatkowski@mirantis.com>
#
class profile::monitoring::zabbix::agent (
  $access_user = undef,
  $access_password = undef,
  $access_tenant = 'services',

  # Keystone
  $keystone_db_user = undef,
  $keystone_db_password = undef,

  # Glance
  $glance_db_user = undef,
  $glance_db_password = undef,

  # Nova
  $nova_db_user = undef,
  $nova_db_password = undef,

  # Cinder
  $cinder_db_user = undef,
  $cinder_db_password = undef,

  # Quantum
  $quantum_db_user = undef,
  $quantum_db_password = undef,

  # Rabbit
  $rabbit_user = 'openstack',
  $rabbit_password = undef,

  $public_address = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $storage_address = '127.0.0.1',
  $management_address = '127.0.0.1',

  $virtualhost_cluster_fqdn = undef,
  $cluster_identifier = undef
) {

  $virtualhost_cluster_name = "OpenStackCluster${cluster_identifier}"


#  class {'zabbix::repo':
#    stage => 'openstack-custom-repo',
#  }

#  class { 'zabbix::agent': }

  class { '::zabbix::agent':
    cluster_identifier => $cluster_identifier
  }

  @@zabbix_usermacro { "${::fqdn} IP_PUBLIC":
    host  => $::fqdn,
    macro => '{$IP_PUBLIC}',
    value => $public_address,
    tag   => "cluster-${cluster_identifier}"
  }

  @@zabbix_usermacro { "${::fqdn} IP_INTERNAL":
    host  => $::fqdn,
    macro => '{$IP_INTERNAL}',
    value => $internal_address,
    tag   => "cluster-${cluster_identifier}"
  }

  @@zabbix_usermacro { "${::fqdn} IP_STORAGE":
    host  => $::fqdn,
    macro => '{$IP_STORAGE}',
    value => $storage_address,
    tag   => "cluster-${cluster_identifier}"
  }

  @@zabbix_usermacro { "${::fqdn} IP_MANAGEMENT":
    host  => $::fqdn,
    macro => '{$IP_MANAGEMENT}',
    value => $management_address,
    tag   => "cluster-${cluster_identifier}"
  }

  #zabbix scripts - begin

  file { $::zabbix::params::agent_scripts_path:
    ensure    => directory,
    recurse   => true,
    purge     => true,
    force     => true,
    mode      => '0755',
    source    => 'puppet:///modules/profile/monitoring/zabbix/scripts',
    require   => Package[$zabbix::params::agent_package]
  }

  file { '/etc/zabbix/check_api.conf':
    ensure      => present,
    content     => template('profile/monitoring/zabbix/check_api.conf.erb'),
    require     => Package[$zabbix::params::agent_package]
  }

  file { '/etc/zabbix/check_rabbit.conf':
    ensure      => present,
    content     => template('profile/monitoring/zabbix/check_rabbit.conf.erb'),
    require     => Package[$zabbix::params::agent_package]
  }

  file { '/etc/zabbix/check_db.conf':
    ensure      => present,
    content     => template('profile/monitoring/zabbix/check_db.conf.erb'),
    require     => Package[$zabbix::params::agent_package]
  }


  #zabbix scripts - end

  sudo::conf {'zabbix_no_requiretty':
    ensure  => present,
    content => 'Defaults:zabbix !requiretty',
  }

  #Zabbix Agent
  @@zabbix_template_link { "${::fqdn} Template App Zabbix Agent":
    host      => $::fqdn,
    template  => 'Template App Zabbix Agent',
    tag       => "cluster-${cluster_identifier}"
  }

  #Puppet Agent
  @@zabbix_template_link { "${::fqdn} Template App Puppet Agent":
    host      => $::fqdn,
    template  => 'Template App Puppet Agent',
    tag       => "cluster-${cluster_identifier}"
  }

  #Linux
  @@zabbix_template_link { "${::fqdn} Template Occam OS Linux":
    host      => $::fqdn,
    template  => 'Template Occam OS Linux',
    tag       => "cluster-${cluster_identifier}"
  }
  zabbix::agent::userparameter {
    'vfs.dev.discovery':
      ensure  => 'present',
      command => '/etc/zabbix/scripts/vfs.dev.discovery.sh';
    'vfs.mdadm.discovery':
      ensure  => 'present',
      command => '/etc/zabbix/scripts/vfs.mdadm.discovery.sh';
    'proc.vmstat':
      key     => 'proc.vmstat[*]',
      command => 'grep \'$1\' /proc/vmstat | awk \'{print $$2}\''
  }

  #Zabbix server
  if defined_in_catalog('zabbix::server') {

    ### TEMPLATE IMPORT - BEGIN

    file { '/etc/zabbix/import':
      ensure    => directory,
      recurse   => true,
      purge     => true,
      force     => true,
      source    => 'puppet:///modules/profile/monitoring/zabbix/import'
    }

    Zabbix_configuration_import {
      require  => File['/etc/zabbix/import']
    }

    zabbix_configuration_import { 'Template_App_Agentless.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Agentless.xml'
    }
    zabbix_configuration_import { 'Template_App_Elasticsearch_Cluster.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Elasticsearch_Cluster.xml'
    }
    zabbix_configuration_import { 'Template_App_Elasticsearch_Node.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Elasticsearch_Node.xml'
    }
    zabbix_configuration_import { 'Template_App_Elasticsearch_Service.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Elasticsearch_Service.xml'
    }
    zabbix_configuration_import { 'Template_App_HAProxy.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_HAProxy.xml'
    }
    zabbix_configuration_import { 'Template_App_Iptables_Stats.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Iptables_Stats.xml'
    }
    zabbix_configuration_import { 'Template_App_Kibana.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Kibana.xml'
    }
    zabbix_configuration_import { 'Template_App_Logstash_Collector.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Logstash_Collector.xml'
    }
    zabbix_configuration_import { 'Template_App_Logstash_Shipper.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Logstash_Shipper.xml'
    }
    zabbix_configuration_import { 'Template_App_Memcache.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Memcache.xml'
    }
    zabbix_configuration_import { 'Template_App_MySQL.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_MySQL.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_API.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_API.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_API_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_API_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_Scheduler.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_Scheduler.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Cinder_Volume.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Cinder_Volume.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Glance_API.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_API.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Glance_API_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_API_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Glance_Registry.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Glance_Registry.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Horizon.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Horizon.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Keystone.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Keystone.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Keystone_API_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Keystone_API_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Libvirt.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Libvirt.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Neutron_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Neutron_Server.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Neutron_Server.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_EC2.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_EC2.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_Metadata.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_Metadata.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_OSAPI.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_OSAPI.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_API_OSAPI_check.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_API_OSAPI_check.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_Cert.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Cert.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_Compute.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Compute.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_ConsoleAuth.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_ConsoleAuth.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Nova_Scheduler.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Nova_Scheduler.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Open_vSwitch.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Open_vSwitch.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Quantum_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Quantum_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Quantum_Server.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Quantum_Server.xml'
    }
    zabbix_configuration_import { 'Template_App_RabbitMQ.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_RabbitMQ.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Account.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Account.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Container.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Container.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Object.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Object.xml'
    }
    zabbix_configuration_import { 'Template_App_OpenStack_Swift_Proxy.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_OpenStack_Swift_Proxy.xml'
    }
    zabbix_configuration_import { 'Template_App_PuppetDB.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_PuppetDB.xml'
    }
    zabbix_configuration_import { 'Template_App_Puppet_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Puppet_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_Puppet_Master.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Puppet_Master.xml'
    }
    zabbix_configuration_import { 'Template_App_Zabbix_Agent.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Zabbix_Agent.xml'
    }
    zabbix_configuration_import { 'Template_App_Zabbix_Server.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_App_Zabbix_Server.xml'
    }
    zabbix_configuration_import { 'Template_Occam_OS_Linux.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_Occam_OS_Linux.xml'
    }
    zabbix_configuration_import { 'Template_OpenStack_Cluster.xml Import':
      ensure   => present,
      xml_file => '/etc/zabbix/import/Template_OpenStack_Cluster.xml'
    }

    ### TEMPLATE IMPORT - END

    @@zabbix_template_link { "${::fqdn} Template App Zabbix Server":
      host      => $::fqdn,
      template  => 'Template App Zabbix Server',
      tag       => "cluster-${cluster_identifier}"
    }

  }

  #Virtual host for openstack cluster monitoring
  if $::fqdn == $virtualhost_cluster_fqdn {
    package {
      $::zabbix::params::python_package_sqlalchemy:
        ensure => present;
      $::zabbix::params::python_package_mysql:
        ensure => present;
      $::zabbix::params::python_package_simplejson:
        ensure => present;
    }

    @@zabbix_host { $virtualhost_cluster_name:
      host    => $virtualhost_cluster_name,
      ip      => $::ipaddress_eth0,
      groups  => 'ManagedByPuppet',
      tag     => "cluster-${cluster_identifier}"
    }

    @@zabbix_template_link { "${virtualhost_cluster_name} Template OpenStack Cluster":
      host      => $virtualhost_cluster_name,
      template  => 'Template OpenStack Cluster',
      tag       => "cluster-${cluster_identifier}"
    }

    @@zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Cinder API check":
      host      => $virtualhost_cluster_name,
      template  => 'Template App OpenStack Cinder API check',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Glance API check":
      host      => $virtualhost_cluster_name,
      template  => 'Template App OpenStack Glance API check',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Keystone API check":
      host      => $virtualhost_cluster_name,
      template  => 'Template App OpenStack Keystone API check',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${virtualhost_cluster_name} Template App OpenStack Nova API OSAPI check":
      host      => $virtualhost_cluster_name,
      template  => 'Template App OpenStack Nova API OSAPI check',
      tag       => "cluster-${cluster_identifier}"
    }

    zabbix::agent::userparameter {
      'db.token.count.query':
        command => '/etc/zabbix/scripts/query_db.py token_count';
      'db.instance.error.query':
        command => '/etc/zabbix/scripts/query_db.py instance_error';
      'db.services.offline.nova.query':
        command => '/etc/zabbix/scripts/query_db.py services_offline_nova';
      'db.instance.count.query':
        command => '/etc/zabbix/scripts/query_db.py instance_count';
      'db.cpu.total.query':
        command => '/etc/zabbix/scripts/query_db.py cpu_total';
      'db.cpu.used.query':
        command => '/etc/zabbix/scripts/query_db.py cpu_used';
      'db.ram.total.query':
        command => '/etc/zabbix/scripts/query_db.py ram_total';
      'db.ram.used.query':
        command => '/etc/zabbix/scripts/query_db.py ram_used';
      'db.services.offline.cinder.query':
        command => '/etc/zabbix/scripts/query_db.py services_offline_cinder';
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::zabbix::params::nova_vip} 8774";
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${::zabbix::params::glance_vip} 9292";
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${::zabbix::params::keystone_vip} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${::zabbix::params::keystone_vip} 35357";
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${::zabbix::params::cinder_vip} 8776";
    }
  }

  #MySQL server
  if defined_in_catalog('mysql::server') {
    @@zabbix_template_link { "${::fqdn} Template App MySQL":
      host      => $::fqdn,
      template  => 'Template App MySQL',
      tag       => "cluster-${cluster_identifier}"
    }
    sudo::conf {'zabbix_mysql':
      ensure  => present,
      content => 'zabbix ALL = NOPASSWD: /usr/bin/mysql',
    }
    sudo::conf {'zabbix_mysqladmin':
      ensure  => present,
      content => 'zabbix ALL = NOPASSWD: /usr/bin/mysqladmin',
    }
    zabbix::agent::userparameter {
      'mysql.status':
        key     => 'mysql.status[*]',
        command => 'echo "show global status where Variable_name=\'$1\';" | sudo mysql -N | awk \'{print $$2}\'';
      'mysql.size':
        key     => 'mysql.size[*]',
        command =>'echo "select sum($(case "$3" in both|"") echo "data_length+index_length";; data|index) echo "$3_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$1" = "all" || ! "$1" ]] || echo " where table_schema=\'$1\'")$([[ "$2" = "all" || ! "$2" ]] || echo "and table_name=\'$2\'");" | sudo mysql -N';
      'mysql.ping':
        command => 'sudo mysqladmin ping | grep -c alive';
      'mysql.version':
        command => 'mysql -V';
    }

    file { "${::zabbix::params::agent_include_path}/userparameter_mysql.conf":
      ensure => absent,
    }
  }

  #Nova (controller)
  if defined_in_catalog('openstack::controller') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova API',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API Metadata":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova API Metadata',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API OSAPI":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova API OSAPI',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API OSAPI check":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova API OSAPI check',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API EC2":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova API EC2',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova Cert":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova Cert',
      tag       => "cluster-${cluster_identifier}"
    }
    zabbix::agent::userparameter {
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${internal_address} 8774";
    }
  }

  #Nova (compute)
  # if defined_in_catalog('openstack::compute') {
  #   @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API":
  #     host      => $::fqdn,
  #     template  => 'Template App OpenStack Nova API',
  #     tag       => "cluster-${cluster_identifier}"
  #   }
  #   @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API Metadata":
  #     host      => $::fqdn,
  #     template  => 'Template App OpenStack Nova API Metadata',
  #     tag       => "cluster-${cluster_identifier}"
  #   }
  # }

  if defined_in_catalog('nova::cert') {
    # @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova API":
    #   host => $::fqdn,
    #   template => 'Template App OpenStack Nova API'
    # }
  }
  if defined_in_catalog('nova::consoleauth') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova ConsoleAuth":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova ConsoleAuth',
      tag       => "cluster-${cluster_identifier}"
    }
  }
  if defined_in_catalog('nova::scheduler') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova Scheduler":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova Scheduler',
      tag       => "cluster-${cluster_identifier}"
    }
  }
  if defined_in_catalog('nova::compute') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova Network":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova Network',
      tag       => "cluster-${cluster_identifier}"
    }
  } else {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova Network":
      ensure    => absent,
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova Network',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Cinder
  if defined_in_catalog('cinder::api') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Cinder API":
      host      => $::fqdn,
      template  => 'Template App OpenStack Cinder API',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Cinder API check":
      host      => $::fqdn,
      template  => 'Template App OpenStack Cinder API check',
      tag       => "cluster-${cluster_identifier}"
    }
    zabbix::agent::userparameter {
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${internal_address} 8776";
    }
  }
  if defined_in_catalog('cinder::scheduler') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Cinder Scheduler":
      host      => $::fqdn,
      template  => 'Template App OpenStack Cinder Scheduler',
      tag       => "cluster-${cluster_identifier}"
    }
  }
  if defined_in_catalog('cinder::volume') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Cinder Volume":
      host      => $::fqdn,
      template  => 'Template App OpenStack Cinder Volume',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Glance
  if defined_in_catalog('glance::api') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Glance API":
      host      => $::fqdn,
      template  => 'Template App OpenStack Glance API',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Glance API check":
      host      => $::fqdn,
      template  => 'Template App OpenStack Glance API check',
      tag       => "cluster-${cluster_identifier}"
    }
    zabbix::agent::userparameter {
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${internal_address} 9292";
    }
  }
  if defined_in_catalog('glance::registry') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Glance Registry":
      host      => $::fqdn,
      template  => 'Template App OpenStack Glance Registry',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Horizon
  if defined_in_catalog('horizon') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Horizon":
      host      => $::fqdn,
      template  => 'Template App OpenStack Horizon',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Swift
  if defined_in_catalog('swift::storage::account') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Swift Account":
      host      => $::fqdn,
      template  => 'Template App OpenStack Swift Account',
      tag       => "cluster-${cluster_identifier}"
    }
  }
  if defined_in_catalog('swift::storage::container') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Swift Container":
      host      => $::fqdn,
      template  => 'Template App OpenStack Swift Container',
      tag       => "cluster-${cluster_identifier}"
    }
  }
  if defined_in_catalog('swift::storage::object') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Swift Object":
      host      => $::fqdn,
      template  => 'Template App OpenStack Swift Object',
      tag       => "cluster-${cluster_identifier}"
    }
  }
  if defined_in_catalog('swift::proxy') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Swift Proxy":
      host      => $::fqdn,
      template  => 'Template App OpenStack Swift Proxy',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Keystone
  if defined_in_catalog('keystone') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Keystone":
      host      => $::fqdn,
      template  => 'Template App OpenStack Keystone',
      tag       => "cluster-${cluster_identifier}"
    }
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Keystone API check":
      host      => $::fqdn,
      template  => 'Template App OpenStack Keystone API check',
      tag       => "cluster-${cluster_identifier}"
    }
    zabbix::agent::userparameter {
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${internal_address} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${internal_address} 35357";
    }
  }

  #Libvirt
  if defined_in_catalog('nova::compute::libvirt') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Libvirt":
      host      => $::fqdn,
      template  => 'Template App OpenStack Libvirt',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Nova compute
  if defined_in_catalog('nova::compute') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Nova Compute":
      host      => $::fqdn,
      template  => 'Template App OpenStack Nova Compute',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  ### QUANTUM - BEGIN ###

  #OVS server & db
  if defined_in_catalog('quantum::plugins::ovs') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Open vSwitch":
      host      => $::fqdn,
      template  => 'Template App OpenStack Open vSwitch',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Quantum Open vSwitch Agent
  if defined_in_catalog('quantum::agents::ovs') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Quantum Agent":
      host      => $::fqdn,
      template  => 'Template App OpenStack Quantum Agent',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Quantum server
  if defined_in_catalog('quantum::server') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Quantum Server":
      host      => $::fqdn,
      template  => 'Template App OpenStack Quantum Server',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  ### QUANTUM - END ###

  ### NEUTRON - BEGIN ###

  #OVS server & db
  if defined_in_catalog('neutron::plugins::ovs') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Open vSwitch":
      host      => $::fqdn,
      template  => 'Template App OpenStack Open vSwitch',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Neutron Open vSwitch Agent
  if defined_in_catalog('neutron::agents::ovs') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Neutron Agent":
      host      => $::fqdn,
      template  => 'Template App OpenStack Neutron Agent',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  #Neutron server
  if defined_in_catalog('neutron::server') {
    @@zabbix_template_link { "${::fqdn} Template App OpenStack Neutron Server":
      host      => $::fqdn,
      template  => 'Template App OpenStack Neutron Server',
      tag       => "cluster-${cluster_identifier}"
    }
  }

  ### NEUTRON - END ###

  #RabbitMQ server
  if defined_in_catalog('rabbitmq::server') {
    @@zabbix_template_link { "${::fqdn} Template App RabbitMQ":
      host      => $::fqdn,
      template  => 'Template App RabbitMQ',
      tag       => "cluster-${cluster_identifier}"
    }
    exec { 'enable rabbitmq management plugin':
      command     => 'rabbitmq-plugins enable rabbitmq_management',
      path        => ['/usr/lib/rabbitmq/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      environment => 'HOME=/root',
      unless      => 'rabbitmq-plugins list -m -E rabbitmq_management | grep -q rabbitmq_management',
      notify      => Exec['restart rabbitmq'],
    }
    exec { 'restart rabbitmq':
      command     => 'service rabbitmq-server restart',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      refreshonly => true,
    }
    firewall {'992 rabbitmq management':
      port   => 55672,
      proto  => 'tcp',
      action => 'accept',
    }
    zabbix::agent::userparameter {
      'rabbitmq.queue.items':
        command => '/etc/zabbix/scripts/check_rabbit.py queues-items';
      'rabbitmq.queues.without.consumers':
        command => '/etc/zabbix/scripts/check_rabbit.py queues-without-consumers';
      'rabbitmq.missing.nodes':
        command => '/etc/zabbix/scripts/check_rabbit.py missing-nodes';
      'rabbitmq.unmirror.queues':
        command => '/etc/zabbix/scripts/check_rabbit.py unmirror-queues';
      'rabbitmq.missing.queues':
        command => '/etc/zabbix/scripts/check_rabbit.py missing-queues';
    }
    zabbix::agent::userparameter {
      'rabbitmq.dqueue.discovery':
        key     => 'rabbitmq.dqueue.discovery',
        command => '/etc/zabbix/scripts/rabbitmq.sh -d';
      'rabbitmq.dqueue':
        key     => 'rabbitmq.dqueue[*]',
        command => '/etc/zabbix/scripts/rabbitmq.sh -v $1 $2 $3 $4';
    }
  }

  if defined_in_catalog('haproxy') {
    @@zabbix_template_link { "${::fqdn} Template App HAProxy":
      host      => $::fqdn,
      template  => 'Template App HAProxy',
      tag       => "cluster-${cluster_identifier}"
    }
    zabbix::agent::userparameter {
      'haproxy.be.discovery':
        key     => 'haproxy.be.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -b';
      'haproxy.be':
        key     => 'haproxy.be[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
      'haproxy.fe.discovery':
        key     => 'haproxy.fe.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -f';
      'haproxy.fe':
        key     => 'haproxy.fe[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
      'haproxy.sv.discovery':
        key     => 'haproxy.sv.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -s';
      'haproxy.sv':
        key     => 'haproxy.sv[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
    }
    sudo::conf {'zabbix_socat':
      ensure  => present,
      content => 'zabbix ALL = NOPASSWD: /usr/bin/socat',
    }
  }

  if defined_in_catalog('memcached') {
    @@zabbix_template_link { "${::fqdn} Template App Memcache":
      host      => $::fqdn,
      template  => 'Template App Memcache',
      tag       => "cluster-${cluster_identifier}"
    }
    zabbix::agent::userparameter {
      'memcache':
        key     => 'memcache[*]',
        command => '/bin/echo -e "stats\nquit" | nc 127.0.0.1 11211 | grep "STAT $1 " | awk \'{print $$3}\''
    }
  }

  #Iptables stats
  if defined_in_catalog('firewall') {
    @@zabbix_template_link { "${::fqdn} Template App Iptables Stats":
      host      => $::fqdn,
      template  => 'Template App Iptables Stats',
      tag       => "cluster-${cluster_identifier}"
    }
    package { 'iptstate':
      ensure => present;
    }
    sudo::conf {'iptstate_users':
      ensure  => present,
      content => 'zabbix ALL = NOPASSWD: /usr/sbin/iptstate',
    }
    zabbix::agent::userparameter {
      'iptstate.tcp':
        command => 'sudo iptstate -1 | grep tcp | wc -l';
      'iptstate.tcp.syn':
        command => 'sudo iptstate -1 | grep SYN | wc -l';
      'iptstate.tcp.timewait':
        command => 'sudo iptstate -1 | grep TIME_WAIT | wc -l';
      'iptstate.tcp.established':
        command => 'sudo iptstate -1 | grep ESTABLISHED | wc -l';
      'iptstate.tcp.close':
        command => 'sudo iptstate -1 | grep CLOSE | wc -l';
      'iptstate.udp':
        command => 'sudo iptstate -1 | grep udp | wc -l';
      'iptstate.icmp':
        command => 'sudo iptstate -1 | grep icmp | wc -l';
      'iptstate.other':
        command => 'sudo iptstate -1 -t | head -2 |tail -1 | sed -e \'s/^.*Other: \(.*\) (.*/\1/\''
    }
  }

}
