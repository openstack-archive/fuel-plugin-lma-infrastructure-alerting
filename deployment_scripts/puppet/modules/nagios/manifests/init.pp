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
class nagios(
  $service_name = $nagios::params::nagios_service_name,
  $main_config = $nagios::params::main_conf_file,
  $use_syslog = true,
  $accept_passive_service_checks = false,
  $accept_passive_host_checks = false,
  $enable_notifications = true,
  $enable_flap_detection = true,
  $debug_level = 0,
  $process_performance_data = true,
  $check_service_freshness = false,
  $service_freshness_check_interval = 60,
  $check_external_commands = false,
  $command_check_interval = 15,
) inherits nagios::params {

  include nagios::params
  include nagios::server_service

  $config_dir = $nagios::params::config_dir

  package { $service_name:
    ensure => present,
  }

  package { $nagios::params::nagios_plugin_package:
    ensure => present,
  }

  file {"${config_dir}/cmd_notify-service-by-email-with-long-service-output.cfg":
    ensure => present,
    source => 'puppet:///modules/nagios/cmd_notify_service_by_email.cfg',
    owner => 'root',
    group => 'root',
    mode => '0644',
    require => Package[$service_name],
  }

  # update inline main nagios configuration
  # TODO enable external_command (option + chmod)
  $passive_service_check = bool2num($accept_passive_service_checks)
  $passive_host_check = bool2num($accept_passive_host_checks)
  $syslog = bool2num($use_syslog)
  $notif = bool2num($enable_notifications)
  $flap = bool2num($enable_flap_detection)
  $perf_data = bool2num($process_performance_data)
  $service_freshness = bool2num($check_service_freshness)
  $external_command = bool2num($check_external_commands)

  augeas{ $main_config:
    incl => $main_config,
    lens => 'nagioscfg.lns',
    changes => [
        # ensure that passive check is enabled
        "set accept_passive_service_checks ${passive_service_check}",
        "set accept_passive_host_checks ${passive_host_check}",

        "set use_syslog ${syslog}",
        "set enable_notifications ${notif}",
        "set enable_flap_detection ${flap}",
        "set process_performance_data ${perf_data}",

        "set debug_level ${debug_level}",

        "set check_service_freshness ${service_freshness}",
        "set service_freshness_check_interval ${service_freshness_check_interval}",
        "set check_external_commands ${external_command}",
        "set command_check_interval  ${command_check_interval}",
        ],
    notify => Class['nagios::server_service'],
  }
}

