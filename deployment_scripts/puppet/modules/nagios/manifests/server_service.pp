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
# Class: nagios::server_service
#
# Manage the Nagios daemon
#
# Example:
# myresource { 'foo':
#   notify => Class['nagios::server_service']
#}
#
class nagios::server_service(
  $service_name = $nagios::params::nagios_service_name,
  $service_ensure = 'running',
  $service_enable = true,
  $service_manage = true,
) inherits nagios::params {

  validate_bool($service_enable)
  validate_bool($service_manage)

  if $service_manage {
    service {$service_name:
      ensure => $service_ensure,
      require => Package[$service_name],
      enable => $service_enable,
    }
  }
}

