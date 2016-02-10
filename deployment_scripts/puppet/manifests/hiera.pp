# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

notice('fuel-plugin-lma-infrastructure-alerting: hiera.pp')

# Initialize network-related variables
$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')
prepare_network_config($network_scheme)

$hiera_file       = '/etc/hiera/plugins/lma_infrastructure_alerting.yaml'
$alerting_vip     = $network_metadata['vips']['infrastructure_alerting_mgmt_vip']['ipaddr']
$listen_address  = get_network_role_property('infrastructure_alerting', 'ipaddr')

$kibana_port = hiera('lma::elasticsearch::kibana_port', 80)
$es_port = hiera('lma::elasticsearch::rest_port', 9200)
$grafana_port = hiera('lma::influxdb::grafana_port', 8000)
$influxdb_port = hiera('lma::influxdb::influxdb_port', 8086)

$calculated_content = inline_template('---
lma::corosync_roles:
  - infrastructure_alerting
  - primary-infrastructure_alerting
lma::infrastructure_alerting::listen_address: <%= @listen_address %>
lma::infrastructure_alerting::apache_port: 8001
lma::infrastructure_alerting::vip: <%= @alerting_vip %>
lma::infrastructure_alerting::vip_ns: infrastructure_alerting
lma::infrastructure_alerting::kibana_port: <%= @kibana_port %>
lma::infrastructure_alerting::es_port: <%= @es_port %>
lma::infrastructure_alerting::grafana_port: <%= @grafana_port %>
lma::infrastructure_alerting::influxdb_port: <%= @influxdb_port %>
lma::infrastructure_alerting::cluster_ip: 127.0.0.1
')

file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}
