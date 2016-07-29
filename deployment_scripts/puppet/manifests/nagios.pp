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
if $notify_warning == false and
  $notify_critical == false and
  $notify_unknown == false and
  $notify_recovery == false {

  $send_to = undef
  $send_from = undef
  $smtp_host = undef
  $smtp_auth = undef
  $smtp_password = undef
} else {
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
}

$lma_collector = hiera_hash('lma_collector', {})

if $lma_collector['gse_cluster_global'] {
  $service_clusters = keys($lma_collector['gse_cluster_global']['clusters'])
}else{
  $service_clusters = []
}

if $lma_collector['gse_cluster_node'] {
  $node_clusters = keys($lma_collector['gse_cluster_node']['clusters'])
}else{
  $node_clusters = []
}

class { 'lma_infra_alerting':
  openstack_deployment_name => $env_id,
  openstack_management_vip  => $management_vip,
  global_clusters           => $service_clusters,
  node_clusters             => $node_clusters,
  password                  => $password,
}

file { 'ocf-ns_apache':
  ensure => present,
  path   => '/usr/lib/ocf/resource.d/fuel/ocf-ns_apache',
  source => 'puppet:///modules/lma_infra_alerting/ocf-ns_apache',
  mode   => '0755',
  owner  => 'root',
  group  => 'root',
}

file { 'ocf-ns_nagios':
  ensure => present,
  path   => '/usr/lib/ocf/resource.d/fuel/ocf-ns_nagios',
  source => 'puppet:///modules/lma_infra_alerting/ocf-ns_nagios',
  mode   => '0755',
  owner  => 'root',
  group  => 'root',
}

# This is required so Apache and Nagios can bind to the VIP address
exec { 'net.ipv4.ip_nonlocal_bind':
  command => '/sbin/sysctl -w net.ipv4.ip_nonlocal_bind=1',
  unless  => '/sbin/sysctl -n net.ipv4.ip_nonlocal_bind | /bin/grep 1',
}

# Apache2 resources for Pacemaker
pacemaker_wrappers::service { 'apache2':
  primitive_type => 'ocf-ns_apache',
  parameters     => {
    'ns'         => 'infrastructure_alerting',
    'status_url' => 'http://localhost:8001/server-status',
    'ns_gateway' => hiera('lma::infrastructure_alerting::apache_ns_gateway')
  },
  metadata       => {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  },
  operations     => {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'start'   => {
      'timeout' => '60'
    },
    'stop'    => {
      'timeout' => '60'
    },
  },
  prefix         => false,
  use_handler    => false,
  require        => [File['ocf-ns_apache'], Exec['net.ipv4.ip_nonlocal_bind'], Class['lma_infra_alerting']],
}

cs_rsc_colocation { 'infrastructure_alerting_vip-with-apache2':
  ensure     => present,
  score      => 'INFINITY',
  primitives => [
    'vip__infrastructure_alerting_mgmt_vip',
    'apache2'
  ],
  require    => Cs_resource['apache2'],
}

# Nagios resources for Pacemaker
pacemaker_wrappers::service { 'nagios3':
  primitive_type => 'ocf-ns_nagios',
  parameters     => {
    'ns'         => 'infrastructure_alerting',
  },
  metadata       => {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  },
  operations     => {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'start'   => {
      'timeout' => '60'
    },
    'stop'    => {
      'timeout' => '60'
    },
  },
  prefix         => false,
  use_handler    => false,
  require        => [File['ocf-ns_nagios'], Exec['net.ipv4.ip_nonlocal_bind'], Class['lma_infra_alerting']],
}

cs_rsc_colocation { 'infrastructure_alerting_vip-with-nagios':
  ensure     => present,
  score      => 'INFINITY',
  primitives => [
    'vip__infrastructure_alerting_mgmt_vip',
    'nagios3'
  ],
  require    => Cs_resource['nagios3'],
}

class { 'lma_infra_alerting::nagios::contact':
  send_to         => $send_to,
  send_from       => $send_from,
  smtp_host       => $smtp_host,
  smtp_auth       => $smtp_auth,
  smtp_user       => $smtp_user,
  smtp_password   => $smtp_password,
  notify_warning  => $notify_warning,
  notify_critical => $notify_critical,
  notify_recovery => $notify_recovery,
  notify_unknown  => $notify_unknown,
  require         => Class['lma_infra_alerting'],
}

if $lma_collector['node_cluster_roles'] {
  $node_cluster_roles = $lma_collector['node_cluster_roles']
} else {
  $node_cluster_roles = {}
}
if $lma_collector['node_cluster_alarms'] {
  $node_cluster_alarms = $lma_collector['node_cluster_alarms']
} else {
  $node_cluster_alarms = {}
}

# Since MOS 8, the private (or mesh) network addresses aren't present in the
# 'nodes' hash anymore. For now, the checks on this network are disabled until
# we find a better way to resolve it.
# See https://bugs.launchpad.net/lma-toolchain/+bug/1532869 for details.
$private_network = false

$nodes = hiera('nodes', {})
class { 'lma_infra_alerting::nagios::hosts':
  hosts                  => $nodes,
  host_name_key          => 'name',
  host_address_key       => 'internal_address',
  role_key               => 'role',
  host_display_name_keys => ['name', 'user_node_name'],
  host_custom_vars_keys  => ['internal_address',
                            'public_address', 'storage_address',
                            'fqdn', 'role'],
  private_network        => $private_network,
  # No service check for the storage network because there is no guarantee that
  # the Nagios node has access to it.
  storage_network        => false,
  node_cluster_roles     => $node_cluster_roles,
  node_cluster_alarms    => $node_cluster_alarms,
  require                => Class['lma_infra_alerting'],
}

$influxdb_nodes = concat(
  filter_nodes($nodes, 'role', 'influxdb_grafana'),
  filter_nodes($nodes, 'role', 'primary-influxdb_grafana')
)
$es_kibana_nodes = concat(
  filter_nodes($nodes, 'role', 'elasticsearch_kibana'),
  filter_nodes($nodes, 'role', 'primary-elasticsearch_kibana')
)

# Configure Grafana and InfluxDB checks
if ! empty($influxdb_nodes){
  $grafana_params = parseyaml(
    inline_template("<%= a={}; @influxdb_nodes.each { |node| a.update({\"Grafana_#{node['name']}\" => {'host_name' => node['name'], 'service_description' => 'Grafana'}})}; a.to_yaml %>")
  )
  $grafana_defaults = {
    port                       => $lma_infra_alerting::params::grafana_port,
    url                        => '/login',
    custom_var_address         => 'internal_address',
    string_expected_in_content => 'grafana',
    require                    => Class['lma_infra_alerting::nagios::hosts'],
  }
  create_resources(lma_infra_alerting::nagios::check_http, $grafana_params, $grafana_defaults)

  $influxdb_params = parseyaml(
    inline_template("<%= a={}; @influxdb_nodes.each { |node| a.update({\"InfluxDB_#{node['name']}\" => {'host_name' => node['name'], 'service_description' => 'InfluxDB'}})}; a.to_yaml %>")
  )
  $influxdb_defaults = {
    port                       => $lma_infra_alerting::params::influxdb_port,
    url                        => '/ping',
    custom_var_address         => 'internal_address',
    string_expected_in_status  => '204 No Content',
    string_expected_in_headers => 'X-Influxdb-Version',
    require                    => Class['lma_infra_alerting::nagios::hosts'],
  }
  create_resources(lma_infra_alerting::nagios::check_http, $influxdb_params, $influxdb_defaults)
}

# Configure Elasticsearch and Kibana checks
if ! empty($es_kibana_nodes){
  $kibana_params = parseyaml(
    inline_template("<%= a={}; @es_kibana_nodes.each { |node| a.update({\"Kibana_#{node['name']}\" => {'host_name' => node['name'], 'service_description' => 'Kibana'}})}; a.to_yaml %>")
  )
  $kibana_defaults = {
    port                       => $lma_infra_alerting::params::kibana_port,
    url                        => '/',
    custom_var_address         => 'internal_address',
    string_expected_in_content => 'Kibana 3',
    require                    => Class[lma_infra_alerting::nagios::hosts],
  }
  create_resources(lma_infra_alerting::nagios::check_http, $kibana_params, $kibana_defaults)

  $es_params = parseyaml(
    inline_template("<%= a={}; @es_kibana_nodes.each { |node| a.update({\"Elasticsearch_#{node['name']}\" => {'host_name' => node['name'], 'service_description' => 'Elasticsearch'}})}; a.to_yaml %>")
  )
  $es_defaults = {
    port                       => $lma_infra_alerting::params::elasticserach_port,
    url                        => '/',
    custom_var_address         => 'internal_address',
    string_expected_in_content => '"status" : 200',
    require                    => Class[lma_infra_alerting::nagios::hosts],
  }
  create_resources(lma_infra_alerting::nagios::check_http, $es_params, $es_defaults)
}
