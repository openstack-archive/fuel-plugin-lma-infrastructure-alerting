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
class nagios::params {
  $config_dir = '/etc/nagios3/conf.d'
  $main_conf_file = '/etc/nagios3/nagios.cfg'
  $nagios_service_name = 'nagios3'

  # plugins
  $nagios_plugin_package = 'nagios-plugins'
  $nagios_plugin_dir = '/usr/lib/nagios/plugins'

  # CGI
  $nagios_cgi_package = 'nagios3-cgi'
  $cgi_htpasswd_file = '/etc/nagios3/htpasswd.users'
  $cgi_user = 'nagiosadmin'
  $cgi_password = undef
  $cgi_http_port = '80'
  $apache_vhost_config_tpl = 'apache_vhost_ubuntu.conf.erb'

  # Nagios server configurations
  $nagios_debug = false
  $command_check_interval = '60s'
  $interval_length = '60'
  $service_freshness_check_interval = '60'
  $host_freshness_check_interval = '60'
  $additional_freshness_latency = '15'
  $log_rotation_method = 'd'
  $max_concurrent_checks = 0 # no limit

  # default Nagios contact
  $default_contact_groups = ['admins']
  $default_contact_email = 'root@localhost'
  $default_contact_alias = 'Admin'

  $service_notification_period = '24x7'
  $host_notification_period = '24x7'
  $service_notification_options = 'w,u,c,r'
  $host_notification_options = 'd,r'
  $service_notification_commands = ['notify-service-by-email-with-long-service-output']
  $host_notification_commands = ['notify-host-by-email']
}
