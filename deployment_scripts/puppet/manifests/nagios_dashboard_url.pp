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

notice('fuel-plugin-lma-infrastructure-alerting: nagios_dashboard_url.pp')

$deployment_id = hiera('deployment_id')
$master_ip = hiera('master_ip')
$nagios_ui = hiera_hash('lma::infrastructure_alerting::nagios_ui')
$vip = $nagios_ui['vip']
$tls_enabled = $nagios_ui['tls_enabled']

if $tls_enabled {
  $host_name = $nagios_ui['hostname']
  $link = "https://${$host_name}/"
  $text = "Dashboard for visualizing alerts (${host_name}: https://${vip})"
} else {
  $link = "http://${vip}/"
  $text = 'Dashboard for visualizing alerts'
}
$nagios_link_data = "{\"title\":\"Nagios\",\
\"description\":\"${text}\",\
\"url\":\"${link}\"}"
$nagios_link_created_file = '/var/cache/nagios_link_created_up_1.x'

exec { 'notify_nagios_url':
  creates => $nagios_link_created_file,
  command => "/usr/bin/curl -sL -w \"%{http_code}\" \
-H 'Content-Type: application/json' -X POST -d '${nagios_link_data}' \
http://${master_ip}:8000/api/clusters/${deployment_id}/plugin_links \
-o /dev/null | /bin/grep 201 && /usr/bin/touch ${nagios_link_created_file}",
}
