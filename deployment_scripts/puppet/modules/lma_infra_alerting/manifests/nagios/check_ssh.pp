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
# === Resource lma_infra_alerting::nagios::check_ssh
#
# Configure SSH checks for per hostgroup
#
# === Parameters
# hostgroup: list of hostgroup names
# custom_var_address: (optional) the name of the custom variable used for the IP,
#                     if not defined use the address of the host.
#
define lma_infra_alerting::nagios::check_ssh(
  $hostgroups = [],
  $contact_group = $lma_infra_alerting::params::nagios_contactgroup,
  $custom_var_address = undef,
){

  include lma_infra_alerting::params

  $prefix = $lma_infra_alerting::params::nagios_config_filename_prefix

  if $custom_var_address {
    # create custom command check_ssh with param using custom variable Host
    $var_name = upcase($custom_var_address)
    $check_command = "check_ssh_${title}"
    $command = {
      "check_ssh_${title}" => {
        properties => {
          command_line => "${nagios::params::nagios_plugin_dir}/check_ssh '\$_HOST${var_name}\$'",
        }
      }
    }
    create_resources(nagios::command, $command, {'prefix' => $prefix})
  } else {
    $check_command = $lma_infra_alerting::params::nagios_cmd_check_ssh
  }

  $service_check = {
    "SSH ${title} network" => {
      properties => {
        hostgroup_name => $hostgroups,
        check_command  => $check_command,
        contact_groups => $contact_group,
      }
    }
  }

  $default_services = {
    prefix => $prefix,
    defaults => {
      'use' => $lma_infra_alerting::params::nagios_generic_service_template,
    },
  }
  create_resources(nagios::service, $service_check, $default_services)
}
