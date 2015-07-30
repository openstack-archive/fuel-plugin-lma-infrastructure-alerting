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
# host_name : The nagios host name
# custom_var_address: (optional) the name of the custom variable used for the IP,
#                     if not defined use the address of the host.
#
define lma_infra_alerting::nagios::check_http(
  $host_name = undef,
  $custom_var_address = undef,
  $port = undef,
  $url = '/',
  $string_expected_in_status = '200 OK',
  $string_expected_in_content = '',
  $string_expected_in_header = '',
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
     $expect_in_status_option = ""
  }
  if $string_expected_in_content {
     $expect_in_content_option = "-s '${string_expected_in_content}'"
  } else {
     $expect_in_content_option = ""
  }
  if $string_expected_in_headers {
     $expect_in_headers_option = "-d '${string_expected_in_headers}'"
  } else {
     $expect_in_headers_option = ""
  }

  if $custom_var_address {
    $up_var= upcase($custom_var_address)
    $hostaddress = "\$_HOST${up_var}\$"
    $check_command = "check_http_${name}_${custom_var_address}"
  } else {
    $hostaddress = '$HOSTADDRESS$'
    $check_command = "check_http_${name}"
  }

  $command = {
    "${check_command}" => {
      properties => {
        command_line => rstrip("${nagios::params::nagios_plugin_dir}/check_http -4 -I '${hostaddress}' ${base_options} ${port_option} ${url_option} ${expect_in_status_option} ${expect_in_content_option} ${expect_in_headers_option}"),
      }
    }
  }

  create_resources(nagios::command, $command, {'prefix' => $prefix})

  $service_check = {
    "HTTP ${name}" => {
      properties => {
        host_name => $host_name,
        check_command => $check_command,
      }
    }
  }

  $default_services = {
    prefix => $prefix,
    defaults => {
      'use' => $lma_infra_alerting::params::nagios_generic_service_template,
    },
  }
  create_resources(nagios::service, $service_check, $default_services)
}
