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
  $services['openstack.radowsgw.status'] = true
}else{
  $services['openstack.swift.status'] = true
}

if $plugin['node_name'] == hiera('user_node_name') {
  class { 'lma_infra_alerting':
    openstack_deployment_name => $env_id,
    openstack_management_vip => $management_vip,
    # additional services
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
  $primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')
  $controller_nodes = filter_nodes($nodes_hash,'role','controller')
  $all_controller_nodes = concat($primary_controller_nodes, $controller_nodes)
  $compute_nodes = filter_nodes($nodes_hash,'role','compute')
  $cinder_nodes = filter_nodes($nodes_hash,'role','cinder')
  $base_os_nodes = filter_nodes($nodes_hash,'role','base-os')
  $all_nodes = {
    'controller' => $all_controller_nodes,
  }

  if !empty($compute_nodes){
    $all_nodes['compute'] = $compute_nodes
  }
  if !empty($cinder_nodes){
    $all_nodes['cinder'] = $cinder_nodes
  }
  if !empty($base_os_nodes){
    $all_nodes['base_os'] = $base_os_nodes
  }

  # configure Host
  $hostgroups =  fuel_nodes_to_nagios_hostgroups($all_nodes)
  class { 'lma_infra_alerting::nagios::hosts':
    hosts => fuel_nodes_to_nagios_hosts($all_nodes, 'internal_address'),
    hostgroups => $hostgroups,
  }

  # configure SSH checks (all ips)
  class { 'lma_infra_alerting::nagios::check_ssh':
    management_hostgroups => keys($hostgroups),
    internal_hostgroups  => keys($hostgroups),
    storage_hostgroups => keys($hostgroups),
    public_hostgroups => 'controller',
  }
}
