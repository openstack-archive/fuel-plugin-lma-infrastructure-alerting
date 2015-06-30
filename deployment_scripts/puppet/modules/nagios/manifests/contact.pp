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
# == Resource: nagios::contact
#
# Create contact Nagios object
#
define nagios::contact (
  $path = $nagios::params::config_dir,
  $prefix = '',
  $onefile = true,
  $properties = {},
  $defaults = {
    'service_notification_period'   => $nagios::params::service_notification_period,
    'host_notification_period'      => $nagios::params::host_notification_period,
    'host_notifications_enabled'    => 1,
    'service_notifications_enabled' => 1,
    },
  $ensure = present,
){

  validate_hash($properties, $defaults)
  $opts = {}

  if is_array($properties['contactgroups']){
    $opts['contactgroups'] = join($contact_groups, ',')
  }else{
    $opts['contactgroups'] = $properties['contactgroups']
  }

  if $properties['service_notification_commands'] == undef {
    $opts['service_notification_commands'] = $nagios::params::service_notification_commands
  }
  if is_array($properties['service_notification_commands']) {
    $opts['service_notification_commands'] = join($properties['service_notification_commands'], ',')
  }
  if $properties['host_notification_commands'] == undef {
    $opts['host_notification_commands'] = $nagios::params::host_notification_commands
  }
  if is_array($properties['host_notification_commands']) {
    $opts['host_notification_commands'] = join($properties['host_notification_commands'], ',')
  }

  if $onefile {
    $target = "${path}/${prefix}contacts.cfg"
  }else{
    $target = "${path}/${prefix}contact_${name}.cfg"
  }
  $opts['target'] = $target
  $opts['notify'] = Class['nagios::server_service']
  $opts['ensure'] = $ensure

  if $properties['command_name'] == undef {
    $command_name = $name
  }else{
    $command_name = $properties['command_name']
  }
  $params = {
    "${command_name}" => merge($properties, $opts),
  }
  create_resources(nagios_contact, $params, $defaults)

  if ! defined(File[$target]){
    file { $target:
      ensure => $ensure,
      mode => '0644',
      notify => Class['nagios::server_service'],
    }
  }
}
