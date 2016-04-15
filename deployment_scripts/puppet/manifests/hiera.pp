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

$hiera_dir        = '/etc/hiera/plugins'
$plugin_name      = 'lma_infrastructure_alerting'
$network_metadata = hiera('network_metadata')
$alerting_vip     = $network_metadata['vips']['infrastructure_alerting_mgmt_vip']['ipaddr']

$calculated_content = inline_template('
---
lma::corosync_roles:
  - infrastructure_alerting
  - primary-infrastructure_alerting
lma::infrastructure_alerting::vip: <%= @alerting_vip %>
lma::infrastructure_alerting::vip_ns: infrastructure_alerting
')

file { "${hiera_dir}/${plugin_name}.yaml":
  ensure  => file,
  content => $calculated_content,
}
