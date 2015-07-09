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
# Configure SSH check for per hostgroup
class lma_infra_alerting::nagios::check_ssh(
  $management_hostgroups = {},
  $internal_hostgroups = {},
  $storage_hostgroups = {},
){

  $prefix = $lma_infra_alerting::params::nagios_config_filename_prefix

  # create custom commands check_ssh with param using custom variables
  $commands = {
    check_ssh_storage => {
      properties => {
        command_line => "${nagios::params::nagios_plugin_dir}/check_ssh '\$_HOSTSTORAGE_ADDRESS\$'",
      }
    },
    check_ssh_private => {
      properties => {
        command_line => "${nagios::params::nagios_plugin_dir}/check_ssh '\$_HOSTPRIVATE_ADDRESS\$'",
      }
    },
  }

  $service_checks = {
    'SSH (management network)' => {
      properties => {
        hostgroup_name => $management_hostgroups,
        check_command => $lma_infra_alerting::params::nagios_cmd_check_ssh,
      }
    },
    'SSH (storage network)' => {
      properties => {
        hostgroup_name => $storage_hostgroups,
        check_command => 'check_ssh_storage',
      }
    },
    'SSH private' => {
      properties => {
        hostgroup_name => $internal_hostgroups,
        check_command => 'check_ssh_private',
      }
    },
  }
  create_resources(nagios::command, $commands, {'prefix' => $prefix})
  $default_services = {
    prefix => $prefix,
    defaults => {
      'use' => $lma_infra_alerting::params::nagios_generic_service_template,
    },
  }
  create_resources(nagios::service, $service_checks, $default_services)
}
