#    Copyright 2016 Mirantis, Inc.
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

file { 'ocf-ns_apache':
  ensure => present,
  path   => '/usr/lib/ocf/resource.d/fuel/ocf-ns_apache',
  source => 'puppet:///modules/lma_infra_alerting/ocf-ns_apache',
  mode   => '0755',
  owner  => 'root',
  group  => 'root',
}

# This is required so Apache and Nagios can bind to the VIP address
sysctl::value { 'net.ipv4.ip_nonlocal_bind':
  value => '1',
}
