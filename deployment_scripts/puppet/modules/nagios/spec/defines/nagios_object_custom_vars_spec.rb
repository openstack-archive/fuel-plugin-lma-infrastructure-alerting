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

describe 'nagios::object_custom_vars' do
    let(:title) { :name}
    let(:params) { { :prefix => 'lma_', :path => '/tmp',
                     :object_name => 'fooobj',
                     :variables => { 'foo' => 42 },
                     :use => 'tpl'
                 } }
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4'}
    end

    filename = '/tmp/lma_tpl_fooobj_name_custom_vars.cfg'
    describe 'with prefix, one variable and an inherited template' do
        it { should contain_file(filename)\
             .with_content(/register 0/) }
        it { should contain_file(filename)\
             .with_content(/use tpl/) }
        it { should contain_file(filename)\
             .with_content(/use tpl/) }
    end
end
