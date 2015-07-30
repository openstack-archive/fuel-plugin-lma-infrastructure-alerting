#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

$management_vip = hiera('management_vip')
$env_id = hiera('deployment_id')

$plugin = hiera('lma_infrastructure_alerting')
$password = $plugin['nagios_password']
$send_to = $plugin['send_to']
$send_from = $plugin['send_from']
$smtp_host = $plugin['smtp_host']
$smtp_auth = $plugin['smtp_auth']
$smtp_user = $plugin['smtp_user']
$smtp_password = $plugin['smtp_password']

$notify_warning = $plugin['notify_warning']
$notify_critical = $plugin['notify_critical']
$notify_unknown = $plugin['notify_unknown']
$notify_recovery = $plugin['notify_recovery']

$ceilometer = hiera('ceilometer')
$services = {}
if $ceilometer['enabled'] {
  $services['openstack.ceilometer.status'] = true
}

$storage_options = hiera('storage')
if $storage_options['objects_ceph']{
  $services['openstack.radosgw.status'] = true
}else{
  $services['openstack.swift.status'] = true
}

if $plugin['node_name'] == hiera('user_node_name') {
  class { 'lma_infra_alerting':
    openstack_deployment_name => $env_id,
    openstack_management_vip => $management_vip,
    additional_services => keys($services),
    # UI password
    password => $password,
  }

  class { 'lma_infra_alerting::nagios::contact':
    send_to => $send_to,
    send_from => $send_from,
    smtp_host => $smtp_host,
    smtp_auth => $smtp_auth,
    smtp_user => $smtp_user,
    smtp_password => $smtp_password,
    notify_warning => $notify_warning,
    notify_critical => $notify_critical,
    notify_recovery => $notify_recovery,
    notify_unknown => $notify_unknown,
    require => Class['lma_infra_alerting'],
  }

  $nodes_hash = hiera('nodes', {})
  $controller_nodes = hiera('controllers')
  $compute_nodes = filter_nodes($nodes_hash,'role','compute')
  $cinder_nodes = filter_nodes($nodes_hash,'role','cinder')
  $base_os_nodes = filter_nodes($nodes_hash,'role','base-os')
  $osd_nodes = filter_nodes($nodes_hash, 'role', 'ceph-osd')

  $all_nodes = {}
  if !empty($controller_nodes){
    $all_nodes['controller'] = $controller_nodes
  }

  if !empty($compute_nodes){
    $all_nodes['compute'] = $compute_nodes
  }
  if !empty($cinder_nodes){
    $all_nodes['cinder'] = $cinder_nodes
  }
  if !empty($base_os_nodes){
    $all_nodes['base-os'] = $base_os_nodes
  }
  if !empty($osd_nodes){
    $all_nodes['ceph-osd'] = $osd_nodes
  }

  class { 'lma_infra_alerting::nagios::hosts':
    hosts => $all_nodes,
    host_name_key => 'name',
    host_address_key => 'internal_address',
    host_display_name_keys => ['name', 'user_node_name'],
    host_custom_vars_keys => ['internal_address', 'private_address',
                              'public_address', 'storage_address',
                              'fqdn', 'role'],
    require  => Class[lma_infra_alerting],
  }


  # Nodes have private IPs only with GRE segmentation
  $network_config = hiera('quantum_settings')
  $segmentation_type = $network_config['L2']['segmentation_type']
  if $segmentation_type == 'gre' {
    $private_network = true
  } else {
    $private_network = false
  }

  # Configure SSH checks
  lma_infra_alerting::nagios::check_ssh { 'management':
    hostgroups => keys($all_nodes),
    require  => Class[lma_infra_alerting],
  }

  lma_infra_alerting::nagios::check_ssh { 'storage':
    hostgroups => keys($all_nodes),
    custom_var_address => 'storage_address',
    require  => Class[lma_infra_alerting],
  }

  if $private_network {
    lma_infra_alerting::nagios::check_ssh { 'private':
      hostgroups => keys($all_nodes),
      custom_var_address => 'private_address',
      require  => Class[lma_infra_alerting],
    }
  }

  # Configure Grafana and InfluxDB checks
  $influxdb_grafana = hiera('influxdb_grafana', {})
  $influxdb_node_name = $influxdb_grafana['node_name']
  $influxdb_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $influxdb_node_name)
  if ! empty($influxdb_nodes){
    lma_infra_alerting::nagios::check_http { 'Grafana':
       host_name => $influxdb_nodes[0]['name'],
       port => $lma_infra_alerting::params::grafana_port,
       url => '/login',
       custom_var_address => 'internal_address',
       string_expected_in_content => 'grafana',
    }
    lma_infra_alerting::nagios::check_http { 'InfluxDB':
       host_name => $influxdb_nodes[0]['name'],
       port => $lma_infra_alerting::params::influxdb_port,
       url => '/ping',
       custom_var_address => 'internal_address',
       string_expected_in_status => '204 No Content',
       string_expected_in_header => 'X-Influxdb-Version',
    }
  }

  # Configure Elasticsearch and Kibana checks
  $es_kibana = hiera('elasticsearch_kibana', {})
  $es_node_name = $es_kibana['node_name']
  $es_kibana_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $es_node_name)
  if ! empty($es_kibana_nodes){
    lma_infra_alerting::nagios::check_http { 'Kibana':
       host_name => $es_kibana_nodes[0]['name'],
       port => $lma_infra_alerting::params::kibana_port,
       url => '/',
       custom_var_address => 'internal_address',
       string_expected_in_content => 'Kibana 3',
    }

    lma_infra_alerting::nagios::check_http { 'Elasticsearch':
       host_name => $es_kibana_nodes[0]['name'],
       port => $lma_infra_alerting::params::elasticserach_port,
       url => '/',
       custom_var_address => 'internal_address',
       string_expected_in_content => '"status" : 200',
    }
  }
}
