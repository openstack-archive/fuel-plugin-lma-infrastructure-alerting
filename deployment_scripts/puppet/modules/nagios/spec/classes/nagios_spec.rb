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

describe 'nagios' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '14.4',
         :concat_basedir => '/tmp'}
    end

    describe 'with default' do
        it { should contain_package('nagios3') }
        it { should contain_file('/var/nagios') }
        it { should contain_file('/var/nagios/cache') }
        it { should contain_file('/var/nagios/archives') }
        it { should contain_augeas('/etc/nagios3/nagios.cfg') }
    end

    describe 'with files to purge' do
        let(:params) do
            {:config_files_to_purge => ['foo.cfg']}
        end

        it { should contain_file(
            '/etc/nagios3/conf.d/foo.cfg').with('ensure' => 'absent') }
    end
end

