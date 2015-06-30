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
# == Class: lma_infra_alerting::nagios::base
#
# Configure Nagios server with LMA requirements
#

class lma_infra_alerting::nagios::base (
  $http_user = $lma_infra_alerting::params::nagios_http_user,
  $http_password = $lma_infra_alerting::params::nagios_http_password,
){

  class { '::nagios':
    accept_passive_service_checks => true,
    accept_passive_host_checks => false,
    use_syslog => true,
    enable_notifications => true,
    enable_flap_detection => true,
    debug_level => 0,
    process_performance_data => false,
    check_external_commands => true,
    command_check_interval => 5,
  }

  class { 'nagios::cgi':
    cgi_user => $http_user,
    cgi_password => $http_password,
  }
}
