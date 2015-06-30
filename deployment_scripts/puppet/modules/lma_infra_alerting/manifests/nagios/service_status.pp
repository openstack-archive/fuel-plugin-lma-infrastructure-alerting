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
# Configure a Nagios host object and configure related services with passive
# checks.
#
class lma_infra_alerting::nagios::service_status (
  $ip = undef,
  $hostname = undef,
  $services = [],
){

  validate_string($ip, $hostname)
  validate_array($services)

  include nagios::server_service

  $nagios_config_dir = $nagios::params::config_dir
  $contact_group = $lma_infra_alerting::params::nagios_contactgroup

  $_host_filename = "${nagios_config_dir}/host_${hostname}.cfg"
  nagios::host { $hostname:
    prefix => 'lma_',
    properties => {
      ensure => present,
      host_name => $hostname,
      address =>  $ip,
      contact_groups => $contact_group,
      passive_checks_enabled => 0,
      passive_checks_enabled => 1,
      use => $lma_infra_alerting::params::nagios_generic_host_template,
    }
  }

  nagios::service { $services:
    prefix => 'lma_',
    properties => {
      host_name => $hostname,
      active_checks_enabled => 0,
      process_perf_data => 0,
      passive_checks_enabled => 1,
      contact_groups => $contact_group,
      check_interval => $lma_infra_alerting::params::nagios_check_interval_service_status,
      retry_interval =>  $lma_infra_alerting::params::nagios_check_interval_service_status,
      use => $lma_infra_alerting::params::nagios_generic_service_template,
    }
  }
}
