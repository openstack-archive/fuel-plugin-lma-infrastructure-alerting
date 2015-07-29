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
# Configure Nagios server and Nagios CGI
# Add services status monitoring and contact for notifications
#
class lma_infra_alerting (
  $openstack_management_vip = undef,
  $openstack_deployment_name = '',
  $password = $lma_infra_alerting::params::nagios_http_password,
  $additional_services = [],
) inherits lma_infra_alerting::params {

  validate_array($additional_services)

  $nagios_openstack_vhostname = $lma_infra_alerting::params::nagios_openstack_hostname_prefix
  $vhostname = "${nagios_openstack_vhostname}-env${$openstack_deployment_name}"

  $core_openstack_services = $lma_infra_alerting::params::openstack_core_services
  $all_openstack_services = union($core_openstack_services, $additional_services)

  # Install and configure nagios server
  class { 'lma_infra_alerting::nagios':
    http_password => $password,
  }

  # Configure services
  class { 'lma_infra_alerting::nagios::service_status':
    ip => $openstack_management_vip,
    hostname => $vhostname,
    services => $all_openstack_services,
    require => Class['lma_infra_alerting::nagios'],
  }
}
