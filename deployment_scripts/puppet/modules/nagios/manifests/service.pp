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
# == Resource: nagios::service
#
# Manage a Nagios service object attached to the Nagios host
#
# == Parameters
# path: the directory conf.d of nagios
# prefix: an optional prefix of the filename(s)
# onefile: all objects are defined in one file if true else one file per service and cmd.
# properties: properties of the nagios_service resource.
#
define nagios::service (
  $path = $nagios::params::config_dir,
  $prefix = '',
  $onefile = true,
  $properties = {},
  $defaults = {},
  $ensure = present,
){

  validate_hash($properties, $defaults)
  validate_string($properties['host_name'])
  $opts = {}

  if is_array($properties['contact_groups']){
    $opts['contact_groups'] = join($properties['contact_groups'], ',')
  }else{
    $opts['contact_groups'] = $properties['contact_groups']
  }

  if is_array($properties['hostgroup_name']){
    $opts['hostgroup_name'] = join($properties['hostgroup_name'], ',')
  }else{
    $opts['hostgroup_name'] = $properties['hostgroup_name']
  }

  if $onefile {
    $target = "${path}/${prefix}services.cfg"
  }else{
    $target = "${path}/${prefix}service_${name}.cfg"
  }
  $opts['target'] = $target
  $opts['notify'] = Class['nagios::server_service']
  $opts['ensure'] = $ensure

  if $properties['passive_checks_enabled']{
    # set default params for passive checks if not provided
    if $properties['max_check_attempts'] == undef {
      $opts['max_check_attempts'] = 1
    }
    if $properties['check_freshness'] == undef {
      $opts['check_freshness'] = 1
    }
  }else{
    if $properties['max_check_attempts'] == undef {
      $opts['max_check_attempts'] = 3
    }
    if $properties['check_freshness'] == undef {
      $opts['check_freshness'] = 0
    }
    if $properties['freshness_threshold'] == undef {
      $opts['freshness_threshold'] = 0
    }
  }

  if $properties['service_description'] == undef {
    $opts['service_description'] = $name
  }

  if $properties['check_command'] == undef {
    # create default command to report UNKNOWN state
    $_check_command = "return-unknown-${name}"
    $opts['check_command'] = $_check_command
    $final_properties = merge($properties, $opts)
    $timeout_freshness = $final_properties['freshness_threshold'] * $final_properties['max_check_attempts']
    nagios::command { $_check_command:
      prefix => "${prefix}services_",
      properties => {
        command_line => "${nagios::params::nagios_plugin_dir}/check_dummy 3 'No data recieved since at least ${timeout_freshness} seconds'",
      }
    }
  }else{
    $final_properties = merge($properties, $opts)
  }

  $service_name = "${properties[host_name]}_${name}"
  $params = {
    "${service_name}" => $final_properties,
  }
  create_resources(nagios_service, $params, $defaults)

  if ! defined(File[$target]){
    file { $target:
      ensure => $ensure,
      mode => '0644',
      require => Nagios_Service[$service_name],
      notify => Class['nagios::server_service'],
    }
  }
}
