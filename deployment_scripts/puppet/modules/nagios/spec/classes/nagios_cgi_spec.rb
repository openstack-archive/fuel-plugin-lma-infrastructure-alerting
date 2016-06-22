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
require 'spec_helper'

describe 'nagios::cgi' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4',
         :concat_basedir => '/tmp'}
    end

    describe 'with default' do
        let(:params) do
            {:vhost_listen_ip => '1.1.1.1',
             :htpasswd_file => '/tmp/htpass',
             :user => 'nagiosuser',
            }
        end
        it { should contain_class('apache') }
        it { should contain_file('/tmp/htpass') }
        it { should contain_htpasswd('nagiosuser') }
        it { should contain_apache__custom_config('nagios-ui') }
    end
    describe 'with default' do
        let(:params) do
            {:vhost_listen_ip => '1.1.1.1',
             :wsgi_vhost_listen_ip => '2.2.2.2',
            }
        end
        it { should contain_class('apache') }
        it { should contain_apache__custom_config('nagios-ui') }
        it { should contain_apache__custom_config('nagios-wsgi') }
        it { should contain_file('wsgi_process_service_checks_script') }
    end
    describe 'with default httpd_dir' do
        let(:params) do
            {:vhost_listen_ip => '1.1.1.1',
             :httpd_dir => '/etc/apache2-nagios',
            }
        end
        it {
            should contain_class('apache').with(
                :conf_dir => '/etc/apache2-nagios',
                :server_root => '/etc/apache2-nagios',
                :httpd_dir => '/etc/apache2-nagios',
            )
        }
    end
end
