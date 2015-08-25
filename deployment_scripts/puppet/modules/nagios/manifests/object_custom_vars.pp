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
# == Resource: nagios::object_custom_vars
#
# Manage a Nagios Object template to set custom variables
#
# This is a workaround for the puppet issue
# https://tickets.puppetlabs.com/browse/PUP-1067
#
# == Parameters
# path: the directory conf.d of nagios
# prefix: an optional prefix of the filename(s)
# object_name: one of nagios object: 'host', 'service', ..
# variable: a Hash of variables (keys must start wih '_')
# use: (optional) a nagios template object name already existing
#
define nagios::object_custom_vars(
  $path = $nagios::params::config_dir,
  $prefix = '',
  $object_name = undef,
  $variables = {},
  $use = false,
  $ensure = present,
){

  validate_hash($variables)
  validate_string($object_name)
  if $object_name == '' {
    fail('object_name parameter must be set')
  }

  file { "${path}/${prefix}tpl_${object_name}_${name}_custom_vars.cfg":
    ensure  => $ensure,
    content => template('nagios/object_custom_vars.erb'),
    mode    => '0644',
  }
}
