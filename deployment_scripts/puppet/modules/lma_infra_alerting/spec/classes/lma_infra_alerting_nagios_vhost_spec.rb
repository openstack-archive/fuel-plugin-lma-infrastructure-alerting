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

describe 'lma_infra_alerting::nagios::vhost' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4',
         :concat_basedir => '/tmp'}
    end

    describe 'with global and node clusters' do
        let(:params) do
            {:global_clusters => ['nova', 'cinder', 'keystone'],
             :node_clusters => ['controller', 'compute', 'storage'],
            }
        end
        it { should contain_lma_infra_alerting__nagios__vhost_cluster_status('global') }
        it { should contain_lma_infra_alerting__nagios__vhost_cluster_status('nodes') }
    end
end

