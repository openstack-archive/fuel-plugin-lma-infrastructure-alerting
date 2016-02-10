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
# Update inline the main nagios configuration
#
class nagios(
  $service_name = $nagios::params::nagios_service_name,
  $main_config = $nagios::params::main_conf_file,
  $use_syslog = true,
  $log_external_commands = true,
  $log_passive_checks = true,
  $log_rotation_method = $nagios::params::log_rotation_method,
  $accept_passive_service_checks = false,
  $accept_passive_host_checks = false,
  $execute_service_checks = true,
  $execute_host_checks = true,
  $enable_notifications = true,
  $enable_event_handlers = true,
  $enable_flap_detection = true,
  $debug_level = 0,
  $process_performance_data = true,
  $check_service_freshness = false,
  $service_freshness_check_interval = $nagios::params::service_freshness_check_interval,
  $check_host_freshness = false,
  $max_concurrent_checks = $nagios::params::max_concurrent_checks,
  $host_freshness_check_interval = $nagios::params::host_freshness_check_interval,
  $additional_freshness_latency = $nagios::params::additional_freshness_latency,
  $check_external_commands = false,
  $command_check_interval = $nagios::params::command_check_interval,
  $config_files_to_purge = [],
  $data_dir = $nagios::params::data_dir,

  $interval_length = $nagios::params::interval_length,
) inherits nagios::params {

  include nagios::params
  include nagios::server_service

  validate_array($config_files_to_purge)

  $config_dir = $nagios::params::config_dir

  package { $service_name:
    ensure => present,
  }

  package { $nagios::params::nagios_plugin_package:
    ensure => present,
  }

  $passive_service_check = bool2num($accept_passive_service_checks)
  $passive_host_check = bool2num($accept_passive_host_checks)
  $service_checks = bool2num($execute_service_checks)
  $host_checks = bool2num($execute_host_checks)
  $syslog = bool2num($use_syslog)
  $_log_external_commands = bool2num($log_external_commands)
  $_log_passive_checks = bool2num($log_passive_checks)
  $notif = bool2num($enable_notifications)
  $event  = bool2num($enable_event_handlers)
  $flap = bool2num($enable_flap_detection)
  $perf_data = bool2num($process_performance_data)
  $service_freshness = bool2num($check_service_freshness)
  $host_freshness = bool2num($check_host_freshness)
  $external_command = bool2num($check_external_commands)
  $cache_dir = "${data_dir}/cache"
  $object_cache_file = "${cache_dir}/objects.cache"
  $status_file = "${cache_dir}/status.dat"
  $temp_file = "${cache_dir}/nagios.tmp"
  $log_file = "${data_dir}/nagios.log"
  $debug_file = "${data_dir}/nagios.debug.log"
  $log_archive_path = "${data_dir}/archives"

  file { $data_dir:
    ensure  => directory,
    owner   => 'nagios',
    require => Package[$service_name],
  }

  file { $cache_dir:
    ensure  => directory,
    owner   => 'nagios',
    require => File[$data_dir];
  }

  file { $log_archive_path:
    ensure  => directory,
    owner   => 'nagios',
    require => File[$data_dir];
  }

  augeas{ $main_config:
    incl    => $main_config,
    lens    => 'nagioscfg.lns',
    changes => [
        "set interval_length ${interval_length}",
        "set accept_passive_service_checks ${passive_service_check}",
        "set execute_service_checks ${service_checks}",
        "set accept_passive_host_checks ${passive_host_check}",
        "set execute_host_checks ${host_checks}",
        "set use_syslog ${syslog}",
        "set log_external_commands ${_log_external_commands}",
        "set log_passive_checks ${_log_passive_checks}",
        "set enable_notifications ${notif}",
        "set enable_event_handlers ${event}",
        "set enable_flap_detection ${flap}",
        "set process_performance_data ${perf_data}",
        "set debug_level ${debug_level}",
        "set check_service_freshness ${service_freshness}",
        "set check_host_freshness ${host_freshness}",
        "set service_freshness_check_interval ${service_freshness_check_interval}",
        "set check_external_commands ${external_command}",
        "set command_check_interval  ${command_check_interval}",
        "set object_cache_file ${object_cache_file}",
        "set status_file ${status_file}",
        "set temp_file ${temp_file}",
        "set log_file ${log_file}",
        "set debug_file ${debug_file}",
        "set log_archive_path ${log_archive_path}",
        ],
    require => Package[$service_name],
    notify  => Class['nagios::server_service'],
  }

  if !empty($config_files_to_purge) {
    $to_purge = prefix($config_files_to_purge, "${nagios::params::config_dir}/")
    file { $to_purge:
      ensure => absent,
      backup => '.puppet-bak',
      notify => Class['nagios::server_service'],
    }
  }

}
