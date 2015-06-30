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
  $ensure = present,
  $email = $nagios::params::default_contact_email,
  $aliass = $nagios::params::default_contact_alias,
  $service_notification_period = $nagios::params::service_notification_period,
  $host_notification_period = $nagios::params::host_notification_period,
  $service_notification_options = $nagios::params::service_notification_options,
  $host_notification_options = $host_notification_options,
  $contact_groups = $nagios::params::default_contact_groups,
  $service_notification_commands = $nagios::params::service_notification_commands,
  $host_notification_commands = $nagios::params::host_notification_commands,
  $prefix = '',
){

  validate_array($service_notification_commands, $host_notification_commands)

  if is_array($contact_groups){
    $contactgroups = join($contact_groups, ',')
  }else{
    $contactgroups = $contact_groups
  }

  $target = "${path}/${prefix}contacts.cfg"
  nagios_contact{ $name:
    ensure => $ensure,
    target => $target,
    email => $email,
    alias => $aliass,
    service_notification_period => $service_notification_period,
    host_notification_period => $host_notification_period,
    service_notification_options => $service_notification_options,
    host_notification_options => $host_notification_options,
    contactgroups => $contactgroups,
    service_notification_commands => join($service_notification_commands, ','),
    host_notification_commands => join($host_notification_commands, ','),
    notify => Class['nagios::server_service'],
  }

  if ! defined(File[$target]){
    file { $target:
      ensure => $ensure,
      mode => '0644',
      notify => Class['nagios::server_service'],
    }
  }
}
