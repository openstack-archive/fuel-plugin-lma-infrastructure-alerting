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
# Configure virtual Nagios hosts for monitoring the clusters of global services
# and nodes.
#
class lma_infra_alerting::nagios::vhost (
  $openstack_management_vip = undef,
  $openstack_deployment_name = '',
  $global_clusters = [],
  $notification_for_global_clusters = 1,
  $node_clusters = [],
  $notification_for_node_clusters = 1,
  $service_clusters = [],
  $notification_for_service_clusters = 0,
) inherits lma_infra_alerting::params {

  validate_array($global_clusters, $node_clusters)

  $vhostname_global = join([
    $lma_infra_alerting::params::nagios_global_vhostname_prefix,
    '-env', $openstack_deployment_name], '')
  $vhostname_node = join([
    $lma_infra_alerting::params::nagios_node_vhostname_prefix,
    '-env', $openstack_deployment_name], '')
  $vhostname_service = join([
    $lma_infra_alerting::params::nagios_service_vhostname_prefix,
    '-env', $openstack_deployment_name], '')

  if ! empty($global_clusters) {
    # Configure the virtual host for the global clusters
    if $notification_for_global_clusters {
      $global_notification = 1
    } else {
      $global_notification = 0
    }
    lma_infra_alerting::nagios::vhost_cluster_status{ 'global':
      ip                    => $openstack_management_vip,
      hostname              => $vhostname_global,
      services              => $global_clusters,
      notifications_enabled => $global_notification,
    }
  }

  if ! empty($node_clusters) {
    if $notification_for_node_clusters {
      $node_notification = 1
    } else {
      $node_notification = 0
    }
    # Configure the virtual host for the node clusters
    lma_infra_alerting::nagios::vhost_cluster_status{ 'nodes':
      ip                    => $openstack_management_vip,
      hostname              => $vhostname_node,
      services              => $node_clusters,
      notifications_enabled => $node_notification,
    }
  }
  if ! empty($service_clusters) {
    # Configure the virtual host for the service clusters
    if $notification_for_service_clusters {
      $service_notification = 1
    } else {
      $service_notification = 0
    }
    lma_infra_alerting::nagios::vhost_cluster_status{ 'services':
      ip                    => $openstack_management_vip,
      hostname              => $vhostname_service,
      services              => $service_clusters,
      notifications_enabled => $service_notification,
    }
  }
}
