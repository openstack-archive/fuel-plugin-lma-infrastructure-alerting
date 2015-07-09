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
# Configure a Nagios host object and configure related services with passive
# checks.
#
class lma_infra_alerting::nagios::hosts (
  $ensure = present,
  $hosts = {},
  $hostgroups = {},
){

  validate_hash($hosts, $hostgroups)
  $default = {
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
  }

  create_resources(nagios::hostgroup, $hostgroups, $hg_default)
  create_resources(nagios::host, $hosts, $default)
}
