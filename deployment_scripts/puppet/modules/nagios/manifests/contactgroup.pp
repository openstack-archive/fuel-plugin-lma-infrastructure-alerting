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
# == Resource: nagios::contactgroup
#
# Create contact_group Nagios object
#
define nagios::contactgroup (
  $path = $nagios::params::config_dir,
  $prefix = '',
  $onefile = true,
  $ensure = present,
){

  if $onefile {
    $target = "${path}/${prefix}contactgroups.cfg"
  }else{
    $target = "${path}/${prefix}contactgroup_${name}.cfg"
  }
  nagios_contactgroup{ $name:
    ensure => $ensure,
    target => $target,
    notify => Class['nagios::server_service'],
  }

  if ! defined(File[$target]){
    file { $target:
      ensure => $ensure,
      mode   => '0644',
      notify => Class['nagios::server_service'],
    }
  }
}
