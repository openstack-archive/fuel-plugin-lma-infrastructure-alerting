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
# Configure individual service checks related to an existing Nagios host.
#
# The service checks are passive and provided either as a hash (key: the title
# of the resource, value: the name of service) or an array ( value: both the
# title of the resource and the name of the service)
define lma_infra_alerting::nagios::services (
  $ensure = present,
  $hostname = undef,
  $notifications_enabled = 1,
  $services = [],
  $active_checks_enabled = 0,
  $process_perf_data = 0,
  $passive_checks_enabled = 1,
  $contact_group = undef,
  $max_check_attempts = undef,
  $check_interval = undef,
  $retry_interval = undef,
  $freshness_threshold = undef,
  $use = undef,
) {
  include lma_infra_alerting::params
  if $contact_group {
    $_contact_group = $contact_group
  } else {
    $_contact_group = $lma_infra_alerting::params::nagios_contactgroup
  }
  if $max_check_attempts {
    $_max_check_attempts = $max_check_attempts
  } else {
    $_max_check_attempts = $lma_infra_alerting::params::nagios_max_check_attempts_service_status
  }
  if $check_interval {
    $_check_interval = $check_interval
  } else {
    $_check_interval = $lma_infra_alerting::params::nagios_check_interval_service_status
  }
  if $retry_interval {
    $_retry_interval = $retry_interval
  } else {
    $_retry_interval = $lma_infra_alerting::params::nagios_retry_interval_service_status
  }
  if $freshness_threshold {
    $_freshness_threshold = $freshness_threshold
  } else {
    $_freshness_threshold = $lma_infra_alerting::params::nagios_freshness_threshold_service_status
  }
  if $use {
    $_use = $use
  } else {
    $_use = $lma_infra_alerting::params::nagios_generic_service_template
  }
  if is_array($services) {
    # Turn ['a', 'b'] into {'a' => 'a', 'b' => 'b'}
    $services_hash = hash(flatten(zip($services, $services)))
  }
  else {
    $services_hash = $services
  }
  validate_hash($services_hash)
  validate_string($hostname)

  $default_resource = {
    ensure     => $ensure,
    prefix     => $lma_infra_alerting::params::nagios_config_filename_prefix,
  }
  $default_properties = {
    host_name              => $hostname,
    active_checks_enabled  => $active_checks_enabled,
    process_perf_data      => $process_perf_data,
    notifications_enabled  => $notifications_enabled,
    passive_checks_enabled => $passive_checks_enabled,
    contact_groups         => $_contact_group,
    max_check_attempts     => $_max_check_attempts,
    check_interval         => $_check_interval,
    retry_interval         => $_retry_interval,
    freshness_threshold    => $_freshness_threshold,
    use                    => $_use,
  }

  # Contrived way to transform:
  #   {'a'=>'x', 'b'=>'y'}
  # into:
  #   {'a'=>{'properties'=>{'service_description'=>'x', ...}, ...}, 'b'=>{'properties'=>{'service_description'=>'y', ...}, ...}}
  $resources = parseyaml(
    inline_template(join([
      '<%= @services_hash.inject({}) { |c, (k, v)| ',
      "  c[k] = @default_resource.merge({'properties' => @default_properties.merge({'service_description' => v})}); c",
      '}.to_yaml %>'
    ], ''))
  )

  create_resources(nagios::service, $resources)
}
