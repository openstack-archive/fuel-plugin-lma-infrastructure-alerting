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

describe 'nagios::contact' do
    let(:title) { :fooContact}
    let(:params) { { :prefix => 'lma_', :path => '/tmp',
                     :send_from => 'sender@foo.bar',
                     :smtp_auth => 'login',
                     :smtp_user => 'foouser',
                     :smtp_password => 'foo\'@',
                     :smtp_host => '1.1.1.1:99',
                 } }
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :operatingsystemrelease => '12.4'}
    end

    filename = '/tmp/lma_contacts.cfg'
    notification_smtp_filename = '/tmp/cmd_notify-service-by-smtp-with-long-service-output.cfg'
    describe 'with prefix, smtp params' do
        it { should contain_file(notification_smtp_filename)\
             .with_content(/foo'"'"'@/) }
        it { should contain_file(notification_smtp_filename)\
             .with_content(/-S smtp-auth=login/) }
        it { should contain_file(notification_smtp_filename)\
             .with_content(/-S smtp-auth-user='foouser'/) }
        it { should contain_file(notification_smtp_filename)\
             .with_content(/-r 'sender@foo.bar'/) }
        it { should contain_file(notification_smtp_filename)\
             .with_content(/smtp:\/\/1.1.1.1:99/) }
        it { should contain_file(filename) }
        it { should contain_nagios_contact('fooContact') }
    end
end

