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

file { 'ocf-ns_nagios':
  ensure => present,
  path   => '/usr/lib/ocf/resource.d/fuel/ocf-ns_nagios',
  source => 'puppet:///modules/lma_infra_alerting/ocf-ns_nagios',
  mode   => '0755',
  owner  => 'root',
  group  => 'root',
}

# This is required so Apache and Nagios can bind to the VIP address
exec { 'net.ipv4.ip_nonlocal_bind':
  command => '/sbin/sysctl -w net.ipv4.ip_nonlocal_bind=1',
  unless  => '/sbin/sysctl -n net.ipv4.ip_nonlocal_bind | /bin/grep 1',
}

# Apache2 resources for Pacemaker
pacemaker_wrappers::service { 'apache2':
  primitive_type => 'ocf-ns_apache',
  parameters     => {
    'ns'         => 'infrastructure_alerting',
    'status_url' => 'http://localhost:8001/server-status',
  },
  metadata       => {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  },
  operations     => {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'start'   => {
      'timeout' => '60'
    },
    'stop'    => {
      'timeout' => '60'
    },
  },
  prefix         => false,
  use_handler    => false,
  require        => [File['ocf-ns_apache'], Exec['net.ipv4.ip_nonlocal_bind']],
}

cs_rsc_colocation { 'infrastructure_alerting_vip-with-apache2':
  ensure     => present,
  score      => 'INFINITY',
  primitives => [
    'vip__infrastructure_alerting_mgmt_vip',
    'apache2'
  ],
  require    => Cs_resource['apache2'],
}

service { 'apache2':
  ensure  => 'running',
  require => Cs_rsc_colocation['infrastructure_alerting_vip-with-apache2'],
}

# Nagios resources for Pacemaker
pacemaker_wrappers::service { 'nagios3':
  primitive_type => 'ocf-ns_nagios',
  parameters     => {
    'ns'         => 'infrastructure_alerting',
  },
  metadata       => {
    'migration-threshold' => '3',
    'failure-timeout'     => '120',
  },
  operations     => {
    'monitor' => {
      'interval' => '30',
      'timeout'  => '60'
    },
    'start'   => {
      'timeout' => '60'
    },
    'stop'    => {
      'timeout' => '60'
    },
  },
  prefix         => false,
  use_handler    => false,
  require        => [File['ocf-ns_nagios'], Exec['net.ipv4.ip_nonlocal_bind']],
}

cs_rsc_colocation { 'infrastructure_alerting_vip-with-nagios':
  ensure     => present,
  score      => 'INFINITY',
  primitives => [
    'vip__infrastructure_alerting_mgmt_vip',
    'nagios3'
  ],
  require    => Cs_resource['nagios3'],
}

service { 'nagios3':
  ensure  => 'running',
  require => Cs_rsc_colocation['infrastructure_alerting_vip-with-apache2'],
}
