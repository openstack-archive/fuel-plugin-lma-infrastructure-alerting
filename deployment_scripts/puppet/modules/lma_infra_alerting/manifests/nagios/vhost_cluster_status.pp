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
# Configure a Nagios host object that represents a cluster of services or nodes.
# The associated IP address is usually a VIP address and the associated
# services are configured with passive checks only.
#
define lma_infra_alerting::nagios::vhost_cluster_status(
  $ensure = present,
  $ip = undef,
  $hostname = undef,
  $notifications_enabled = 1,
  $services = [],
) {

  include lma_infra_alerting::params

  validate_string($ip, $hostname)
  validate_array($services)

  $nagios_config_dir = $nagios::params::config_dir
  $contact_group = $lma_infra_alerting::params::nagios_contactgroup

  nagios::host { $hostname:
    ensure     => $ensure,
    prefix     => $lma_infra_alerting::params::nagios_config_filename_prefix,
    properties => {
      host_name              => $hostname,
      address                => $ip,
      contact_groups         => $contact_group,
      active_checks_enabled  => 1,
      passive_checks_enabled => 0,
      max_check_attempts     => $lma_infra_alerting::params::nagios_default_max_check_attempts_host,
      use                    => $lma_infra_alerting::params::nagios_generic_host_template,
    }
  }

  lma_infra_alerting::nagios::services { "${title} for ${hostname}":
    ensure                => $ensure,
    hostname              => $hostname,
    notifications_enabled => $notifications_enabled,
    contact_group         => $contact_group,
    services              => prefix($services, "${title}-"),
  }
}
