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
$email = $plugin['email']
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
    # notifications options
    contact_email => $email,
    notify_warning => $notify_warning,
    notify_critical => $notify_critical,
    notify_recovery => $notify_recovery,
    notify_unknown => $notify_unknown,
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
}
