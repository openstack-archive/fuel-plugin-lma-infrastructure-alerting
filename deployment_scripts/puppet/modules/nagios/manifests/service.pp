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
# freshness_factor: if passive_check enabled, the factor (1.5 by default) used
#                   to enable and configure freshness properties:
#                   check_freshness = 1
#                   freshness_threshold = check_interval * freshness_factor
#
define nagios::service (
  $path = $nagios::params::config_dir,
  $prefix = '',
  $onefile = true,
  $properties = {},
  $freshness_factor = 1.5,
){

  validate_hash($properties)
  validate_string($properties['host_name'])

  $opts = {}

  if is_array($properties['contact_groups']){
    $opts['contact_groups'] = join($properties['contact_groups'], ',')
  }else{
    $opts['contact_groups'] = $properties['contact_groups']
  }

  if $onefile {
    $target = "${path}/${prefix}services.cfg"
  }else{
    $target = "${path}/${prefix}service_${name}.cfg"
  }
  $opts['target'] = $target

  if $properties['ensure'] == undef {
    $properties['ensure'] = present
  }

  if $properties['passive_checks_enabled']{
    # set default params for passive checks if not provided
    if $properties['max_check_attempts'] == undef {
      $opts['max_check_attempts'] = 1
    }
    if $properties['check_freshness'] == undef {
      $opts['check_freshness'] = 1
    }
    if $properties['freshness_threshold'] == undef {
      $freshness_threshold = floor($properties['check_interval'] * $freshness_factor)
      # Note: w/o inline_template, an error occurs:
      # Could not evaluate: undefined method `sub' for 45:Fixnum
      $opts['freshness_threshold'] = inline_template('<%= @freshness_threshold %>')
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
  $opts['notify'] = Class['nagios::server_service']

  if $properties['check_command'] == undef {
    # create default command to report UNKNOWN state
    $_check_command = "return-unknown-${name}"
    $opts['check_command'] = $_check_command
    nagios::command { $_check_command:
      prefix => "${prefix}services_",
      properties => {
        command_line => "${nagios::params::nagios_pluigin_dir}/check_dummy 3 'No data recieved since at least ${freshness_threshold} seconds'",
      }
    }
  }

  $service_name = "${properties[host_name]}_${name}"
  $params = {
    "${service_name}" => merge($properties, $opts),
  }
  create_resources(nagios_service, $params)

  if ! defined(File[$target]){
    file { $target:
      ensure => $properties['ensure'],
      mode => '0644',
      require => Nagios_Service[$service_name],
      notify => Class['nagios::server_service'],
    }
  }
}
