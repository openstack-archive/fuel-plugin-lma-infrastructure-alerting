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
# == Class: lma_infra_alerting::nagios::contact
#
# Configure Nagios contactgroup and contact
#

class lma_infra_alerting::nagios::contact(
  $ensure = present,
  $email = $lma_infra_alerting::params::nagios_contact_email,
  $notify_warning = true,
  $notify_critical = true,
  $notify_recovery = true,
  $notify_unknown = true,
  $notify_flapping = false,
  $notify_schedule  = false,

) inherits lma_infra_alerting::params{
  validate_string($email)

  $contact_groups = $lma_infra_alerting::params::nagios_contactgroup
  nagios::contactgroup { $contact_groups:
    ensure => $ensure,
    prefix => $lma_infra_alerting::params::nagios_config_filename_prefix,
  }

  $service_notifs = {}
  $host_notifs = {}
  if $notify_warning {
    $service_notifs['w'] = true
  }
  if $notify_critical {
    $service_notifs['c'] = true
    $host_notifs['d'] = true
  }
  if $notify_recovery {
    $service_notifs['r'] = true
    $host_notifs['r'] = true
  }
  if $notify_unknown {
    $service_notifs['u'] = true
    $host_notifs['u'] = true
  }
  if $notify_flapping {
    $service_notifs['f'] = true
    $host_notifs['f'] = true
  }
  if $notify_schedule {
    $service_notifs['s'] = true
    $host_notifs['s'] = true
  }

  $service_notify_options = keys($service_notifs)
  if count($service_notify_options) == 0 {
    $_service_notify_options = 'n'
  }else{
    $_service_notify_options = join($service_notify_options, ',')
  }
  $host_notify_options = keys($host_notifs)
  if count($host_notify_options) == 0 {
    $_host_notify_options = 'n'
  }else{
    $_host_notify_options = join($host_notify_options, ',')
  }

  $alias = regsubst($email, '@', '_AT_')
  $contact_name = "${contact_groups}_${alias}"
  nagios::contact { $contact_name:
    ensure => $ensure,
    prefix => $lma_infra_alerting::params::nagios_config_filename_prefix,
    properties => {
      email => $email,
      alias => $alias,
      contactgroups => $contact_groups,
      service_notification_options => $_service_notify_options,
      host_notification_options => $_host_notify_options,
    }
  }
}
