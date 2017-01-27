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

$fuel_version = 0 + hiera('fuel_version')

# Initialize network-related variables
$network_scheme   = hiera_hash('network_scheme')
$network_metadata = hiera_hash('network_metadata')
prepare_network_config($network_scheme)

$hiera_file      = '/etc/hiera/plugins/lma_infrastructure_alerting.yaml'
$alerting_vip    = $network_metadata['vips']['infrastructure_alerting_mgmt_vip']['ipaddr']
$alerting_ui_vip = $network_metadata['vips']['infrastructure_alerting_ui']['ipaddr']
$listen_address  = get_network_role_property('infrastructure_alerting', 'ipaddr')

# If any of the VIP addresses is located in the management network, we should
# configure the management vrouter as the default gateway so that the Apache
# process can connect to remote services such as LDAP.
# TODO(pasquier-s): do the same when network templates are used.
$vip_networks = concat(
  get_routable_networks_for_network_role($network_scheme, 'infrastructure_alerting'),
  get_routable_networks_for_network_role($network_scheme, 'infrastructure_alerting_ui')
)
$management_vrouter = hiera('management_vrouter_vip')
$apache_ns_gateway = inline_template(
  '<%= require "ipaddr"; @vip_networks.any?{ |x| IPAddr.new(x).include?(@management_vrouter) } ? @management_vrouter : "" %>'
)

$plugin      = hiera('lma_infrastructure_alerting')
$tls_enabled = $plugin['tls_enabled']

$apache_httpd_dir = '/etc/apache2-nagios'

if $tls_enabled {
  $nagios_ui_hostname = $plugin['nagios_hostname']
  if $plugin['nagios_ssl_cert'] and $plugin['nagios_ssl_cert']['content'] {
    $nagios_ui_ssl_cert = $plugin['nagios_ssl_cert']['content']
    $nagios_ui_ssl_cert_path = "${apache_httpd_dir}/certs/${$plugin['nagios_ssl_cert']['name']}"

    file { $apache_httpd_dir:
      ensure => directory,
      mode   => '0755',
    } ->
    file { "${apache_httpd_dir}/certs":
      ensure => directory,
      mode   => '0750',
    } ->
    file { $nagios_ui_ssl_cert_path:
      ensure  => present,
      mode    => '0600',
      content => $nagios_ui_ssl_cert,
    }
  }
}

$kibana_port = hiera('lma::elasticsearch::apache_port', 80)
$es_port = hiera('lma::elasticsearch::rest_port', 9200)
$grafana_port = hiera('lma::influxdb::grafana_port', 8000)
$influxdb_port = hiera('lma::influxdb::influxdb_port', 8086)
$password = $plugin['nagios_password']

$ldap_enabled               = $plugin['ldap_enabled'] or false
$ldap_protocol              = $plugin['ldap_protocol_for_nagios']
$ldap_servers               = split($plugin['ldap_servers'], '\s+')
$ldap_bind_dn               = $plugin['ldap_bind_dn']
$ldap_bind_password         = $plugin['ldap_bind_password']
$ldap_user_search_base_dns  = $plugin['ldap_user_search_base_dns']
$ldap_user_search_filter    = $plugin['ldap_user_search_filter']
$ldap_user_attribute        = $plugin['ldap_user_attribute']
$ldap_authorization_enabled = $plugin['ldap_authorization_enabled'] or false
$ldap_group_attribute       = $plugin['ldap_group_attribute']
$ldap_admin_group_dn        = $plugin['ldap_admin_group_dn']

if empty($plugin['ldap_server_port']) {
  if downcase($ldap_protocol) == 'ldap' {
    $ldap_port = 389
  } else {
    $ldap_port = 636
  }
} else {
  $ldap_port = $plugin['ldap_server_port']
}

$elasticsearch_kibana = hiera_hash('elasticsearch_kibana', {})
if ! empty($elasticsearch_kibana) {
  $kibana_username = $elasticsearch_kibana["kibana_username"]
  $kibana_password = $elasticsearch_kibana["kibana_password"]
}

$calculated_content = inline_template('---
lma::corosync_roles:
  - infrastructure_alerting
  - primary-infrastructure_alerting
lma::infrastructure_alerting::listen_address: <%= @listen_address %>
lma::infrastructure_alerting::vip: <%= @alerting_vip %>
lma::infrastructure_alerting::vip_ns: infrastructure_alerting
lma::infrastructure_alerting::kibana_port: <%= @kibana_port %>
lma::infrastructure_alerting::kibana_username: <%= @kibana_username %>
lma::infrastructure_alerting::kibana_password: <%= @kibana_password %>
lma::infrastructure_alerting::es_port: <%= @es_port %>
lma::infrastructure_alerting::grafana_port: <%= @grafana_port %>
lma::infrastructure_alerting::influxdb_port: <%= @influxdb_port %>
lma::infrastructure_alerting::cluster_ip: 127.0.0.1
lma::infrastructure_alerting::apache_dir: <%= @apache_httpd_dir %>
lma::infrastructure_alerting::apache_ns_gateway: "<%= @apache_ns_gateway %>"
lma::infrastructure_alerting::nagios_ui:
  vip: <%= @alerting_ui_vip %>
  tls_enabled: <%= @tls_enabled %>
<% if @tls_enabled -%>
  apache_port: 443
  hostname: <%= @nagios_ui_hostname %>
  ssl_cert_path: <%= @nagios_ui_ssl_cert_path %>
<% else -%>
  apache_port: 80
<% end -%>
lma::infrastructure_alerting::authnz:
    password: <%= @password %>
    ldap_enabled: <%= @ldap_enabled %>
    ldap_authorization_enabled: <%= @ldap_authorization_enabled %>
<% if @ldap_enabled -%>
    ldap_servers:
<% @ldap_servers.each do |s| -%>
        - "<%= s %>"
<% end -%>
    ldap_protocol: <%= @ldap_protocol %>
    ldap_port: <%= @ldap_port %>
    ldap_bind_dn: >-
      <%= @ldap_bind_dn %>
    ldap_bind_password: >-
      <%= @ldap_bind_password %>
    ldap_user_search_base_dns: >-
      <%= @ldap_user_search_base_dns %>
    ldap_user_attribute: >-
      <%= @ldap_user_attribute %>
    ldap_user_search_filter: >-
      <%= @ldap_user_search_filter %>
    ldap_group_attribute: >-
      <%= @ldap_group_attribute %>
<% if @ldap_authorization_enabled -%>
    ldap_admin_group_dn: >-
      <%= @ldap_admin_group_dn %>
<% end -%>
<% end -%>
')

file { $hiera_file:
  ensure  => file,
  content => $calculated_content,
}

if $fuel_version >= 9.0 {
  class { '::osnailyfacter::netconfig::hiera_default_route' :}
}

# Purge the Nagios services from previous 0.10.x version.
# Nagios will be correctly (re)configured by nagios.pp manifest.
$purge = prefix(['lma_services.cfg', 'lma_services_commands.cfg'],
  '/etc/nagios3/conf.d/')
file { $purge:
  ensure => absent,
  backup => '.bak-version-0.10.x',
}

# Remove the crontab to avoid concurrent execution during an upgrade
cron { 'update lma infra alerting':
    ensure   => absent,
}
