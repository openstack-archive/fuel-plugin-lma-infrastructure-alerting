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
  $user = $nagios::params::cgi_user,
  $password = $nagios::params::cgi_password,
  $htpasswd_file = $nagios::params::cgi_htpasswd_file,
  $http_port = $nagios::params::cgi_http_port,
  $vhost_listen_ip = '*',
) inherits nagios::params {


  ## Configure apache
  class { 'apache':
    default_confd_files => false,
    default_vhost       => false,
    # be good citizen
    mpm_module          => 'prefork',
    default_mods        => ['php', 'cgi'],
    purge_configs       => false,
    manage_group        => false,
    manage_user         => false,
  }
  apache::listen { $http_port: }

  # Template uses these variables: http_port, vhost_listen_ip, cgi_htpasswd_file
  apache::custom_config { 'nagios':
    content => template("nagios/${nagios::params::apache_vhost_config_tpl}"),
  }

  $package_name = $nagios::params::nagios_cgi_package
  package { $package_name:
    ensure  => present,
    require => Class[apache],
  }

  # TODO: update cgi config to allow this specific user to access UI
  htpasswd { $user:
    # TODO randomize salt?
    cryptpasswd => ht_md5($password, 'salt'),
    target      => $htpasswd_file,
    require => Package[$package_name],
  }

  # Fix a permission issue with Ubuntu
  # to allow using external commands through the web UI
  if $::osfamily == 'Debian' {
    $apache_user = $apache::user
    user { $apache_user:
      groups => 'nagios',
      require => Class[apache],
    }
    file { '/var/lib/nagios3/rw':
      ensure => directory,
      mode => '0650',
      require => Package[$package_name],
    }

    file { $cgi_htpasswd_file:
      owner => root,
      group => $apache_user,
      mode  => '0640',
      require => Htpasswd[$user],
    }
  }
}
