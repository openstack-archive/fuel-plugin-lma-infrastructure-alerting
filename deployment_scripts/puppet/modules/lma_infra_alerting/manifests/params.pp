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
class lma_infra_alerting::params {
  $nagios_http_user = 'nagiosadmin'
  $nagios_http_password = ''

  $nagios_config_filename_prefix = 'lma_'

  # Override Nagios server configuration
  $nagios_command_check_interval = '10s'

  # Following hostname must match with lma_collector::params::nagios_hostname_service_status
  $nagios_openstack_dummy_hostname = 'openstack-services'

  $nagios_contactgroup = 'openstack'
  $nagios_contact_email = 'root@localhost'
  $nagios_check_interval_service_status = 30
  $nagios_generic_host_template = 'generic-host'
  $nagios_generic_service_template = 'generic-service'

  $nagios_cmd_check_ssh = 'check_ssh'

  # Following service names must be coherent with lma_collector nagios output
  # plugin names.
  $openstack_core_services = [
      'openstack.keystone.status',
      'openstack.nova.status',
      'openstack.glance.status',
      'openstack.cinder.status',
      'openstack.neutron.status',
      'openstack.heat.status',
  ]
}
