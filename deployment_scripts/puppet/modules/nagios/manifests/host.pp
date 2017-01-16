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
# == Resource: nagios::host
#
# Manage a Nagios host object
#
# == Parameters
# path: the directory conf.d of nagios
# prefix: an optional prefix of the filename(s)
# onefile: all objects are defined in one file if true else one file per service and cmd.
# properties: properties of the nagios_host resource.

define nagios::host (
  $path = $nagios::params::config_dir,
  $prefix = '',
  $onefile = true,
  $properties = {},
  $defaults = {},
  $ensure = present,
  $custom_vars = {},
){

  validate_hash($properties, $defaults)
  $opts = {}

  if is_array($properties['contact_groups']){
    $opts['contact_groups'] = join(sort($properties['contact_groups']), ',')
  }elsif $properties['contact_groups'] {
    $opts['contact_groups'] = $properties['contact_groups']
  }

  if $onefile {
    $target = "${path}/${prefix}hosts.cfg"
  }else{
    $target = "${path}/${prefix}host_${name}.cfg"
  }
  $opts['target'] = $target
  $opts['ensure'] = $ensure
  $opts['notify'] = Class['nagios::server_service']

  if $properties['host_name'] == undef {
    $opts['host_name'] = $name
    $host_name = $name
  }else{
    $host_name = $properties['host_name']
  }
  if $properties['display_name'] == undef {
    $opts['display_name'] = $name
  }

  $final_params = merge($properties, $opts)
  if ! empty($custom_vars){
    # override inheritance
    $new_use = "custom-vars-${host_name}"
    if $final_params['use']{
      $original_use = $final_params['use']
    }elsif $defaults['use']{
      $original_use = $defaults['use']
    }else{
      $original_use = undef
    }
    $final_params['use'] = $new_use
    nagios::object_custom_vars{ $host_name:
      object_name => 'host',
      variables   => $custom_vars,
      use         => $original_use,
      prefix      => $prefix,
    }
  }

  $params = {
    "${host_name}" => $final_params,
  }

  create_resources(nagios_host, $params, $defaults)

  if ! defined(File[$target]){
    file { $target:
      ensure  => $properties['ensure'],
      mode    => '0644',
      require => Nagios_Host[$host_name],
      notify  => Class['nagios::server_service'],
    }
  }
}
