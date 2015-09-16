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
  $send_from = 'nagios@localhost.localdomain',
  $smtp_auth = 'none',
  $smtp_host = '127.0.0.1:25',
  $smtp_user = undef,
  $smtp_password = undef,
  $ensure = present,
  $defaults = {},
){

  validate_hash($properties, $defaults)
  if ( $smtp_auth != 'none' and $smtp_auth != 'plain' and $smtp_auth != 'login' and $smtp_auth != 'cram-md5'){
    fail('smtp_auth parameter must be one of: none, plain, login or cram-md5')
  }

  if $smtp_auth == 'none' {
    $_smtp_auth = false
  } else {
    $_smtp_auth = $smtp_auth
  }

  if $_smtp_auth and (! $smtp_user or ! $smtp_password) {
    fail("smtp_user and smtp_password must be provided with smtp_auth = ${smtp_auth}")
  }

  $opts = {}

  # default decent properties
  if empty($defaults){
    $_defaults = {
      'host_notifications_enabled'    => 1,
      'service_notifications_enabled' => 1,
      'service_notification_period'   => $nagios::params::service_notification_period,
      'host_notification_period'      => $nagios::params::host_notification_period,
      }
  }else{
    $_defaults = $defaults
  }

  if is_array($properties['contactgroups']){
    $opts['contactgroups'] = join(sort($properties['contactgroups']), ',')
  }else{
    $opts['contactgroups'] = $properties['contactgroups']
  }

  if $properties['service_notification_commands'] == undef {
    if $_smtp_auth {
      $opts['service_notification_commands'] = $nagios::params::service_notification_command_by_smtp
      $command_filename = "${path}/cmd_notify-service-by-smtp-with-long-service-output.cfg"
      $smtp_password_escaped = regsubst($smtp_password, '\'', '\'"\'"\'', 'G')
      if ! defined(File[$command_filename]){
        file {$command_filename:
          ensure  => present,
          content => template('nagios/notify-by-smtp.cfg.erb'),
          owner   => 'root',
          group   => 'root',
          mode    => '0644',
          require => Package[$nagios::params::package_mailx_smtp],
        }
      }
      if ! defined(Package[$nagios::params::package_mailx_smtp]){
        package { $nagios::params::package_mailx_smtp:
          ensure => present,
        }
      }

    } else {
      $opts['service_notification_commands'] = $nagios::params::service_notification_command
      file {"${path}/cmd_notify-service-by-email-with-long-service-output.cfg":
        ensure => present,
        source => 'puppet:///modules/nagios/cmd_notify_service_by_email.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
      }
    }
  }
  if is_array($properties['service_notification_commands']) {
    $opts['service_notification_commands'] = join(sort($properties['service_notification_commands']), ',')
  }
  if $properties['host_notification_commands'] == undef {
    $opts['host_notification_commands'] = $nagios::params::host_notification_commands
  }
  if is_array($properties['host_notification_commands']) {
    $opts['host_notification_commands'] = join(sort($properties['host_notification_commands']), ',')
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
  create_resources(nagios_contact, $params, $_defaults)

  if ! defined(File[$target]){
    file { $target:
      ensure => $ensure,
      mode   => '0644',
      notify => Class['nagios::server_service'],
    }
  }
}
