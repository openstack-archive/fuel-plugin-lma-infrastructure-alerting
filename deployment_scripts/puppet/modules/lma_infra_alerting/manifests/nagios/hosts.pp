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
# == Class lma_infra_alerting::nagios::hosts
#
# Configure a Nagios hosts and Nagios hostgroups objects.
#
# == Parameters
# hosts: Hash of hosts grouped by hostgroup: { group1 => [{host_hash}, ..]}
# host_<property>_key: the key of the host hash to use for nagios <property>
# host_<property>_keys: list of keys used to build <property> by concatenation
# host_custom_vars_keys: list of keys to define as Custom Variables for the Host
#
class lma_infra_alerting::nagios::hosts (
  $ensure = present,
  $hosts = [],
  $host_name_key = undef,
  $network_role_key = undef,
  $host_display_name_keys = [],
  $host_custom_vars_keys = [],
  $role_key = undef,
  $node_profiles = {},
  $node_cluster_alarms = {},
  $alarms = [],
  $metrics = {},
  $service_cluster_alarms = {},
){

  include lma_infra_alerting::params

  validate_string($host_name_key, $network_role_key)
  validate_array($hosts, $host_display_name_keys, $host_custom_vars_keys, $alarms)
  validate_hash($node_profiles, $node_cluster_alarms, $metrics)

  $nagios_hosts = nodes_to_nagios_hosts($hosts,
                                        $host_name_key,
                                        $network_role_key,
                                        $host_display_name_keys,
                                        $host_custom_vars_keys)
  $host_defaults = {
    ensure => $ensure,
    prefix => $lma_infra_alerting::params::nagios_config_filename_prefix,
    defaults => {
      contact_groups => $lma_infra_alerting::params::nagios_contactgroup,
      active_checks_enabled => 1,
      passive_checks_enabled => 0,
      max_check_attempts => $lma_infra_alerting::params::nagios_default_max_check_attempts_host,
      use => $lma_infra_alerting::params::nagios_generic_host_template,
    }
  }
  create_resources(nagios::host, $nagios_hosts, $host_defaults)

  $nagios_hostgroups = nodes_to_nagios_hostgroups($hosts,
                                                  $host_name_key,
                                                  $role_key)
  $hostgroup_defaults = {
    prefix => $lma_infra_alerting::params::nagios_config_filename_prefix,
    ensure => $ensure,
  }
  create_resources(nagios::hostgroup, $nagios_hostgroups, $hostgroup_defaults)

  # Configure AFD-based service checks
  $afd_nodes = afds_to_nagios_services($hosts,
                                        $host_name_key,
                                        $role_key,
                                        $node_profiles,
                                        $node_cluster_alarms,
                                        $alarms,
                                        $metrics
                                        )
  create_resources(lma_infra_alerting::nagios::services, $afd_nodes)

  $afd_services = afds_to_nagios_services($hosts,
                                          $host_name_key,
                                          $role_key,
                                          $node_profiles,
                                          $service_cluster_alarms,
                                          $alarms,
                                          $metrics
                                          )
  create_resources(lma_infra_alerting::nagios::services, $afd_services)

  if empty($node_profiles) and empty($node_cluster_alarms) {
    $node_uid= hiera('uid')
    nagios::service { 'dummy-check-for-ci':
      prefix                 => $lma_infra_alerting::params::nagios_config_filename_prefix,
      onefile                => false,
      service_description    => 'dummy-check',
      dummy_cmd_state        => 0,
      dummy_cmd_state_string => 'OKAY',
      dummy_cmd_text         => 'dummy check okay',
      properties             => {
        'host_name'      => "node-${node_uid}",
        'contact_groups' => $lma_infra_alerting::params::nagios_contactgroup,
        'hostgroup_name' => 'primary-infrastructure_alerting'
      }
    }
  } else {
    include nagios::server_service
    file { "${nagios::params::config_dir}/${lma_infra_alerting::params::nagios_config_filename_prefix}service_dummy-check-for-ci.cfg":
      ensure => absent,
      notify => Class['nagios::server_service'],
    }
  }
}
