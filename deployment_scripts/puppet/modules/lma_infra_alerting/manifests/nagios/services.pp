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
# Configure services related to an existing Nagios host.
# Service are passive checks.
#
define lma_infra_alerting::nagios::services (
  $ensure = present,
  $hostname = undef,
  $notifications_enabled = 1,
  $services = [],
  $active_checks_enabled = 0,
  $process_perf_data = 0,
  $passive_checks_enabled = 1,
  $contact_group = $lma_infra_alerting::params::nagios_contactgroup,
  $max_check_attempts = $lma_infra_alerting::params::nagios_max_check_attempts_service_status,
  $check_interval = $lma_infra_alerting::params::nagios_check_interval_service_status,
  $retry_interval = $lma_infra_alerting::params::nagios_retry_interval_service_status,
  $freshness_threshold = $lma_infra_alerting::params::nagios_freshness_threshold_service_status,
  $use = $lma_infra_alerting::params::nagios_generic_service_template,
){

  validate_string($hostname)
  validate_array($services)

  nagios::service { $services:
    ensure     => $ensure,
    prefix     => $lma_infra_alerting::params::nagios_config_filename_prefix,
    properties => {
      host_name              => $hostname,
      active_checks_enabled  => $active_checks_enabled,
      process_perf_data      => $process_perf_data,
      notifications_enabled  => $notifications_enabled,
      passive_checks_enabled => $passive_checks_enabled,
      contact_groups         => $contact_group,
      max_check_attempts     => $max_check_attempts,
      check_interval         => $check_interval,
      retry_interval         => $retry_interval,
      freshness_threshold    => $freshness_threshold,
      use                    => $use,
    }
  }
}
