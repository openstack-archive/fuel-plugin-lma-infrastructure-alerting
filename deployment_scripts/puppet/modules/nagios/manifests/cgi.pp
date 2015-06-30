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
# == Resource: nagios::cgi
#
# Install and configure Nagios web interface
#
class nagios::cgi (
  $cgi_user = $nagios::params::cgi_user,
  $cgi_password = $nagios::params::cgi_password,
  $cgi_htpasswd_file = $nagios::params::cgi_htpasswd_file,
){

  include nagios::params
  #TODO: use apache puppet module
  $apache_service_name = $nagios::params::apache_service_name

  $package_name = $nagios::params::nagios_cgi_package
  package { $package_name:
    ensure => present,
  }

  # Configure apache
  # TODO http port and vhost
  package {$apache_service_name:
    ensure => present,
  }

  service {$apache_service_name:
    ensure => running,
    require => Package[$apache_service_name],
  }

  # TODO: update cgi config to allow this specific user to access UI
  htpasswd { $cgi_user:
    # TODO randomize salt?
    cryptpasswd => ht_md5($cgi_password, 'salt'),
    target      => $cgi_htpasswd_file,
  #  notify => Service[$apache_service_name],
    require => Package[$package_name],
  }

  # TODO: CentOS compatibility
  $apache_user = 'www-data'

  user { $apache_user:
    groups => 'nagios',
    require => Package[$apache_service_name],
  }

  # fix a right issue with Ubuntu
  # TODO: CentOS compatibility
  file { '/var/lib/nagios3/rw':
    ensure => directory,
    mode => '0650',
    require => Package[$package_name],
  }

  file { $cgi_htpasswd_file:
    owner => root,
    group => $apache_user,
    mode  => '0640',
    require => Htpasswd[$cgi_user],
  }
}

