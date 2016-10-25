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
  $vhost_listen_ip,
  $httpd_service_name = 'httpd',
  $httpd_dir = '/etc/apache2',
  $wsgi_vhost_listen_ip = undef,
  $user = $nagios::params::cgi_user,
  $password = $nagios::params::cgi_password,
  $htpasswd_file = $nagios::params::cgi_htpasswd_file,
  $http_port = $nagios::params::cgi_http_port,
  $cgi_conf_file = $nagios::params::nagios_cgi_conf_file,
  $ui_tls_enabled = false,
  $ui_certificate_filename = undef,
  $ui_certificate_hostname = undef,
  $ldap_enabled = false,
  $ldap_protocol = undef,
  $ldap_servers = [],
  $ldap_port = undef,
  $ldap_bind_dn = undef,
  $ldap_bind_password = undef,
  $ldap_user_search_base_dns = undef,
  $ldap_user_search_filter = undef,
  $ldap_user_attribute = undef,
  $ldap_authorization_enabled = false,
  $ldap_group_attribute = undef,
  $ldap_admin_group_dn = undef,
  $wsgi_process_service_checks_location = '/status',
  $wsgi_process_service_checks_script = '/usr/local/bin/nagios-process-service-checks.wsgi',
  $wsgi_processes = 2,
  $wsgi_threads = 15,
) inherits nagios::params {

  validate_integer($wsgi_processes)
  validate_integer($wsgi_threads)

  if $ldap_enabled {
    if empty($ldap_servers) {
      fail('ldap_servers list parameter is empty')
    }
    if ! is_array($ldap_servers) {
      fail('ldap_servers list parameter must be an array')
    }
    if ! $ldap_port { fail('Missing ldap_port parameter')}
    if ! $ldap_protocol { fail('Missing ldap_protocol parameter')}
    if ! $ldap_bind_dn { fail('Missing ldap_bind_dn parameter')}
    if ! $ldap_bind_password { fail('Missing ldap_bind_password parameter')}
    if ! $ldap_user_search_base_dns { fail('Missing ldap_user_search_base_dns parameter')}
    if ! $ldap_user_search_filter { fail('Missing ldap_user_search_filter parameter')}
    if ! $ldap_user_attribute { fail('Missing ldap_user_attribute parameter')}

    if $ldap_authorization_enabled {
      if ! $ldap_group_attribute {fail('Missing ldap_group_attribute parameter')}
      if ! $ldap_admin_group_dn {fail('Missing ldap_admin_group_dn parameter')}
    }
    $ldap_apache_modules = ['ldap', 'authnz_ldap']
    # LDAP url is used in apache::custom_config
    $ldap_servers_url = join(suffix($ldap_servers, ":${ldap_port}"), ' ')
    $ldap_url = "${ldap_servers_url}/${ldap_user_search_base_dns}?${ldap_user_attribute}?sub?${ldap_user_search_filter}"
  } else {
    $ldap_apache_modules = []
  }
  $default_apache_modules = [
    'php', 'cgi', 'autoindex', 'env', 'access_compat', 'deflate',
    'authn_core', 'authn_file', 'auth_basic', 'authz_user', 'wsgi']

  if $ui_tls_enabled {
    $apache_modules = concat($default_apache_modules, ['ssl', 'headers'], $ldap_apache_modules)
  } else {
    $apache_modules = concat($default_apache_modules, $ldap_apache_modules)
  }

  ## Configure apache
  class { 'apache':
    # be good citizen by not erasing other configurations
    purge_configs       => false,
    service_name        => $httpd_service_name,
    default_confd_files => false,
    default_vhost       => false,
    # prerequists for Nagios CGI
    mpm_module          => 'prefork',
    default_mods        => $apache_modules,
    # allow to use the Puppet user resource later in the manifest
    manage_group        => false,
    manage_user         => false,
    httpd_dir           => $httpd_dir,
    conf_dir            => $httpd_dir,
    server_root         => $httpd_dir,
    confd_dir           => "${httpd_dir}/conf.d",
    mod_dir             => "${httpd_dir}/mods-available",
    mod_enable_dir      => "${httpd_dir}/mods-enabled",
    vhost_dir           => "${httpd_dir}/sites-available",
    vhost_enable_dir    => "${httpd_dir}/sites-enabled",
    ports_file          => "${httpd_dir}/port.confs",
  }

  # Apache mod_status is used by the Pacemaker OCF script
  class { 'apache::mod::status':
    allow_from => [$vhost_listen_ip, $wsgi_vhost_listen_ip, '127.0.0.1'],
  }

  if $ui_tls_enabled {
    # Explicitly set HTTPS for the virtualhost to avoid random error
    # "ssl_error_rx_record_too_long"
    apache::listen { "${vhost_listen_ip}:${http_port} https": }
  } else {
    apache::listen { "${vhost_listen_ip}:${http_port}": }
  }
  if $wsgi_vhost_listen_ip {
    apache::listen { "${wsgi_vhost_listen_ip}:80": }
  }

  # Template uses these variables: http_port, vhost_listen_ip, cgi_htpasswd_file
  # nagios_command_file
  $nagios_command_file = '/var/lib/nagios3/rw/nagios.cmd'
  $verify_command = "${::apache::params::verify_command} -f ${httpd_dir}/${::apache::params::conf_file}"
  apache::custom_config { 'nagios-ui':
    content        => template("nagios/${nagios::params::apache_ui_vhost_config_tpl}"),
    verify_command => $verify_command,
    notify         => Class['apache::service'],
    require        => Class['apache'],
  }
  if $wsgi_vhost_listen_ip {
    $log_dir = "${nagios::params::data_dir}/log"
    file { $log_dir:
      ensure  => directory,
      mode    => '0650',
      require => Class['apache'],
      notify  => Class['apache::service'],
    }
    $logrotate_conf = '/etc/logrotate.d/nagios_wsgi.conf'
    file { $logrotate_conf:
      ensure  => present,
      content => template('nagios/logrotate.conf.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      require => File[$log_dir],
    }
    # Template uses these variables: cgi_htpasswd_file
    # nagios_command_file, wsgi_vhost_listen_ip, wsgi_processes, wsgi_threads,
    # wsgi_process_service_checks_script, wsgi_process_service_checks_location
    # log_dir
    apache::custom_config { 'nagios-wsgi':
      content        => template("nagios/${nagios::params::apache_wsgi_vhost_config_tpl}"),
      verify_command => $verify_command,
      require        => [Class['apache'], File[$log_dir]],
    }
    file { 'wsgi_process_service_checks_script':
      ensure  => present,
      path    => $wsgi_process_service_checks_script,
      source  => 'puppet:///modules/nagios/process-service-checks.wsgi',
      notify  => Class['apache::service'],
      require => Class['apache'],
    }
  }

  $apache_user = $apache::user
  case $::osfamily {
    'Debian': {
      # Nagios CGI is provided by a dedicated package
      $package_name = $nagios::params::nagios_cgi_package
      package { $package_name:
        ensure  => present,
        require => Class[apache],
      }

      htpasswd { $user:
        # TODO randomize salt?
        cryptpasswd => ht_md5($password, 'salt'),
        target      => $htpasswd_file,
        require     => Package[$package_name],
      }

      # Fix a permission issue with Ubuntu to allow using external commands
      # through the web UI
      user { $apache_user:
        groups  => 'nagios',
        require => Class[apache],
      }

      # Apache needs to be restarted otherwise the CGI script won't have access
      # to the Nagios FIFO file
      file { '/var/lib/nagios3/rw':
        ensure  => directory,
        mode    => '0650',
        require => Package[$package_name],
        notify  => Class['apache::service']
      }

    }
    'Redhat': {
      htpasswd { $user:
        # TODO randomize salt?
        cryptpasswd => ht_md5($password, 'salt'),
        target      => $htpasswd_file,
      }
    }
    default: {
      fail('OS Familly not supported!')
    }
  }

  # Ensure read right for Apache
  file { $htpasswd_file:
    owner   => root,
    group   => $apache_user,
    mode    => '0640',
    require => Htpasswd[$user],
  }

  # Authorize all logged users
  augeas { $cgi_conf_file:
    incl    => $cgi_conf_file,
    lens    => 'nagioscfg.lns',
    changes => [
      'set authorized_for_system_information *',
      'set authorized_for_configuration_information *',
      'set authorized_for_system_commands *',
      'set authorized_for_all_services *',
      'set authorized_for_all_hosts *',
      'set authorized_for_all_service_commands *',
      'set authorized_for_all_host_commands *',
    ],
    require => [Htpasswd[$user], Class['apache']],
    notify  => Service[$httpd_service_name],
  }
}
