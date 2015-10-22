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

describe 'lma_infra_alerting::nagios::services' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4'}
    end

    describe 'with services as array' do
        let(:title) { 'foo on node-1' }
        let(:params) do {
          :ensure   => true,
          :hostname => 'node-1',
          :notifications_enabled => true,
          :services => ['foo', 'bar'],
        }
        end
        it { should contain_nagios__service('foo') }
        it { should contain_nagios__service('bar') }
    end

    describe 'with services as hashes' do
        let(:title) { 'foo and bar on node-1' }
        let(:params) do {
          :ensure   => true,
          :hostname => 'node-1',
          :notifications_enabled => false,
          :services => {
              'foo on node-1' => 'compute.cpu',
              'bar on node-1' => 'compute.fs',
          }
        }
        end
        it { should contain_nagios__service('foo on node-1') }
        it { should contain_nagios__service('bar on node-1') }
    end
end
