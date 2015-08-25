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
# == Resource: nagios::command
#
# Manage a Nagios command object
#
# == Parameters
# path: the directory conf.d of nagios
# prefix: an optional prefix of the filename(s)
# onefile: all objects are defined in one file if true else one file per service and cmd.
# properties: properties of the nagios_host resource.

define nagios::command (
  $path = $nagios::params::config_dir,
  $prefix = '',
  $onefile = true,
  $properties = {},
  $defaults = {},
  $ensure = present,
){

  validate_hash($properties, $defaults)
  $opts = {}

  if $onefile {
    $target = "${path}/${prefix}commands.cfg"
  }else{
    $target = "${path}/${prefix}command_${name}.cfg"
  }
  $opts['target'] = $target
  $opts['notify'] = Class['nagios::server_service']
  $opts['ensure'] = $ensure

  if $properties['command_name'] == undef {
    $opts['command_name'] = $name
  }

  $params = {
    "${name}" => merge($properties, $opts),
  }

  create_resources(nagios_command, $params, $defaults)

  if ! defined(File[$target]){
    file { $target:
      ensure  => $ensure,
      mode    => '0644',
      require => Nagios_Command[$name],
      notify  => Class['nagios::server_service'],
    }
  }
}
