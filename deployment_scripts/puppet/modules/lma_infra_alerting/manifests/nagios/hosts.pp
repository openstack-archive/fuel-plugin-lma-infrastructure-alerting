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
  $host_address_key = undef,
  $host_display_name_keys = [],
  $host_custom_vars_keys = [],
){

  include lma_infra_alerting::params

  validate_hash($hosts)
  validate_string($host_name_key, $host_address_key)
  validate_array($host_display_name_keys, $host_custom_vars_keys)

  $nagios_hosts = nodes_to_nagios_hosts(
                    $hosts,
                    $host_name_key,
                    $host_address_key,
                    $host_display_name_keys,
                    $host_custom_vars_keys)
  $nagios_hostgroups = nodes_to_nagios_hostgroups($hosts, $host_name_key)

  $default = {
    ensure => $ensure,
    prefix => $lma_infra_alerting::params::nagios_config_filename_prefix,
    defaults => {
      contact_groups => $lma_infra_alerting::params::nagios_contactgroup,
      active_checks_enabled => 1,
      passive_checks_enabled => 0,
      use => $lma_infra_alerting::params::nagios_generic_host_template,
    }
  }

  $hg_default = {
    prefix => $lma_infra_alerting::params::nagios_config_filename_prefix,
    ensure => $ensure,
  }

  create_resources(nagios::hostgroup, $nagios_hostgroups, $hg_default)
  create_resources(nagios::host, $nagios_hosts, $default)
}
