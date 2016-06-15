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
require 'spec_helper'

describe 'lma_infra_alerting::nagios' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4',
         :concat_basedir => '/tmp'}
    end

    describe 'with global and node clusters' do
        let(:params) do
            {:http_password => 'foo', :http_port => '999',
             :nagios_ui_address => '1.1.1.1',
             :nagios_address => '2.3.3.3'
            }
        end
        it { should contain_class('nagios') }
        it { should create_class('nagios::cgi') }
        it { should create_cron('update lma infra alerting') }
        it { should create_file('/usr/local/bin/update-lma-configuration') }
    end
end

