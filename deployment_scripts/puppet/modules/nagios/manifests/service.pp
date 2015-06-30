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
# Manage a Nagios service object attached to the $hostname
#
# == Parameters
# path: the directory conf.d of nagios
# hostname: A valid Nagios Hostname
# ensure: weither or not the Nagios configuration should be present or absent
# process_perf_data: Nagios service configuration
# passive_checks_enabled: Nagios service configuration
# active_check: Nagios service configuration
# check_command: A valid command name, if not provided the class create a
#                command returning UNKNOWN state.
# check_interval: Nagios service configuration
# retry_interval: Nagios service configuration
# freshness_factor: if passive_check enabled, the factor (1.5 by default) used
#                   to enable and configure freshness options:
#                   check_freshness = 1
#                   freshness_threshold = check_interval * freshness_factor
#
define nagios::service (
  $path = $nagios::params::config_dir,
  $hostname = undef,
  $ensure = present,
  $process_perf_data = false,
  $passive_check = false,
  $active_check = true,
  $check_command = undef,
  $check_interval = 30,
  $retry_interval = 30,
  $freshness_factor = 1.5,
  $contact_groups = $nagios::params::default_contact_groups,
  $use = 'generic-service',
  $prefix = '',
){

  validate_bool($process_perf_data, $passive_check, $active_check)
  validate_array($contact_groups)
  validate_string($hostname)

  $target = "${path}/${prefix}service_${name}.cfg"
  $_passive_check = bool2num($passive_check)
  $_active_check = bool2num($active_check)
  $_process_perf_data = bool2num($process_perf_data)

  if $passive_check{
    $max_check_attemmpts = 1
    $check_freshness = 1
    $freshness_threshold = floor($check_interval * $freshness_factor)
  }else{
    $max_check_attemmpts = 3
    $check_freshness = 0
    $freshness_threshold = 0
  }

  if $check_command == undef {
    $_check_command = "return-unknown-${name}"
    $_cmd_target = "${path}/cmd_service_${name}.cfg"
    nagios_command { $_check_command:
      ensure => $ensure,
      #TODO: filename in params
      command_line => "/usr/lib/nagios/plugins/check_dummy 3 'No data recieved since at least ${freshness_threshold} seconds'",
      target => $_cmd_target,
      notify => Class['nagios::server_service'],
    }

    file { $_cmd_target:
      mode => '0644',
      ensure => $ensure,
      require => Nagios_Command[$_check_command],
      notify => Class['nagios::server_service'],
    }
  }else{
    $_check_command = $_check_command
  }

  $service_name = "${hostname}_${name}"
  nagios_service { $service_name:
    ensure => $ensure,
    target => $target,
    service_description => $name,
    display_name => $name,
    host_name => $hostname,
    process_perf_data => "${_process_perf_data}",
    active_checks_enabled => "${_active_check}",
    passive_checks_enabled => "${_passive_check}",
    max_check_attempts => $max_check_attemmpts,
    check_command => $_check_command,
    check_freshness => "${check_freshness}",
    freshness_threshold => "${freshness_threshold}",
    check_interval => $check_interval,
    retry_interval => $retry_interval,
    contact_groups => join($contact_groups, ','),
    use => $use,
    #require => Nagios_Host[$hostname],
    notify => Class['nagios::server_service'],
  }

  file { $target:
    mode => '0644',
    ensure => $ensure,
    require => Nagios_Service[$service_name],
    notify => Class['nagios::server_service'],
  }
}

