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

describe 'nagios::service' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4'}
    end

    describe 'with service_description defined' do
        let(:title) { :check_service_bar }
        let(:params) do {
            :path   => '/tmp',
            :prefix => 'lma_',
            :properties => {
                'host_name'              => 'node-1',
                'active_checks_enabled'  => false,
                'passive_checks_enabled' => true,
                'contact_groups'         => 'contact1',
                'max_check_attempts'     => 1,
                'check_interval'         => 60,
                'retry_interval'         => 30,
                'freshness_threshold'    => 65,
                'service_description'    => 'bar'
            },
            :defaults => {}
        }
        end

        it { should contain_nagios_service('check_service_bar') }
        it { should contain_nagios_command('return-unknown-check_service_bar') }
    end

    describe 'without service_description defined' do
        let(:title) { 'node-1.bar' }
        let(:params) do {
            :path   => '/tmp',
            :prefix => 'lma_',
            :properties => {
                'host_name'              => 'node-1',
                'active_checks_enabled'  => false,
                'passive_checks_enabled' => true,
                'contact_groups'         => 'contact1',
                'max_check_attempts'     => 1,
                'check_interval'         => 60,
                'retry_interval'         => 30,
                'freshness_threshold'    => 65,
            },
            :defaults => {}
        }
        end

        it { should contain_nagios_service('node-1.bar') }
        it { should contain_nagios_command('return-unknown-node-1.bar') }
    end
end

