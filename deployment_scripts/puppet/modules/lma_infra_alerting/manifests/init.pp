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
  $service_clusters = [],
  $node_clusters = [],
) inherits lma_infra_alerting::params {

  validate_array($service_clusters, $node_clusters)

  $nagios_openstack_service_vhostname = $lma_infra_alerting::params::nagios_openstack_service_hostname_prefix
  $nagios_openstack_node_clusters_vhostname = $lma_infra_alerting::params::nagios_openstack_node_cluster_hostname_prefix
  $vhostname_service = "${nagios_openstack_service_vhostname}-env${$openstack_deployment_name}"
  $vhostname_node = "${nagios_openstack_node_clusters_vhostname}-env${$openstack_deployment_name}"

  $cluster_suffix = $lma_infra_alerting::params::cluster_status_suffix

  # Install and configure nagios server
  class { 'lma_infra_alerting::nagios':
    http_password => $password,
  }

  # Purge default configuration shipped by distribution
  if !empty($lma_infra_alerting::params::nagios_distribution_configs_to_purge) {
    file { $lma_infra_alerting::params::nagios_distribution_configs_to_purge:
      ensure  => absent,
      backup  => '.puppet-bak',
      require => Class['lma_infra_alerting::nagios'],
    }
  }

  if ! empty($service_clusters){
    # Configure global OpenStack services status
    lma_infra_alerting::nagios::vhost_cluster_status{ 'global':
      ip       => $openstack_management_vip,
      hostname => $vhostname_service,
      services => suffix($service_clusters, $cluster_suffix),
      require  => Class['lma_infra_alerting::nagios'],
    }
  }

  if ! empty($node_clusters){
    # Configure OpenStack cluster status
    lma_infra_alerting::nagios::vhost_cluster_status{ 'nodes':
      ip                    => $openstack_management_vip,
      hostname              => $vhostname_node,
      services              => suffix($node_clusters, $cluster_suffix),
      notifications_enabled => 0,
      require               => Class['lma_infra_alerting::nagios'],
    }
  }
}
