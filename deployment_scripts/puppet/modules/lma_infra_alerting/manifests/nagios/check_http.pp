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
# === Resource lma_infra_alerting::nagios::check_http
#
# Configure HTTP check
#
# === Parameters
# host_name: The nagios host name
# service_description: (optional) the service check name (default to $title)
# custom_address: (optional) the IP address, if not defined the address of the host is used.
# port: the HTTP port
# url: URL to GET
# username: Username to use for basic authentication
# password: Password to use for basic authentication
# string_expected_*: string to expect in the response
# response_time_*: configure the warning and critical thresholds of the response time
# timeout: seconds before connection times out
#
define lma_infra_alerting::nagios::check_http(
  $host_name = undef,
  $contact_group = $lma_infra_alerting::params::nagios_contactgroup,
  $service_description = undef,
  $custom_address = undef,
  $port = undef,
  $url = '/',
  $username = undef,
  $password = undef,
  $string_expected_in_status = '200 OK',
  $string_expected_in_content = undef,
  $string_expected_in_headers = undef,
  $response_time_warning = 2,
  $response_time_critical = 3,
  $timeout = 5,
){

  include lma_infra_alerting::params

  $prefix = $lma_infra_alerting::params::nagios_config_filename_prefix

  $base_options = "-w ${response_time_warning} -c ${response_time_critical} -t ${timeout}"
  $port_option = "-p ${port}"
  $url_option = "-u '${url}'"
  if $string_expected_in_status {
    $expect_in_status_option = "-e '${string_expected_in_status}'"
  } else {
    $expect_in_status_option = ''
  }
  if $string_expected_in_content {
    $expect_in_content_option = "-s '${string_expected_in_content}'"
  } else {
    $expect_in_content_option = ''
  }
  if $string_expected_in_headers {
    $expect_in_headers_option = "-d '${string_expected_in_headers}'"
  } else {
    $expect_in_headers_option = ''
  }

  if $custom_address {
    $hostaddress = $custom_address
    $check_command = join(["check_http_${title}_", regsubst($custom_address, '[^\w]', '_', 'G')], '')
  } else {
    $hostaddress = '$HOSTADDRESS$'
    $check_command = "check_http_${title}"
  }

  if $username and $password {
    $auth_basic_option = "-a \"${username}\":\"${password}\""
  } else {
    $auth_basic_option = ''
  }

  $command_line = rstrip(join([
      "${nagios::params::nagios_plugin_dir}/check_http -4 -I '${hostaddress}' ${base_options} ${port_option}",
      rstrip(" ${url_option} ${expect_in_status_option} ${expect_in_content_option} ${expect_in_headers_option}"),
      rstrip(" ${auth_basic_option}"),
  ], ''))
  nagios::command { $check_command:
    prefix     => $prefix,
    properties => {
      command_line => $command_line
    }
  }

  if $service_description {
    $_service_description = $service_description
  } else {
    $_service_description = $title
  }

  nagios::service { "HTTP ${title}":
    prefix     => $prefix,
    properties => {
      host_name           => $host_name,
      check_command       => $check_command,
      contact_groups      => $contact_group,
      service_description => $_service_description,
    },
    defaults   => {
      'use' => $lma_infra_alerting::params::nagios_generic_service_template,
    }
  }
}
