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
require 'spec_helper'

describe 'nodes_to_nagios_hostgroups' do

    describe 'with empty node list' do
        it { should run.with_params([], 'name', 'node_roles').and_return({}) }
    end

    describe 'with node list' do
        nodes = [
            {"fqdn" => "node-1.test.domain.local",
             "internal_address" => "10.109.2.5",
             "internal_netmask" => "255.255.255.0",
             "name" => "node-1",
             "node_roles" => ["influxdb_grafana","infrastructure_alerting"],
             "storage_address" => "10.109.4.2",
             "storage_netmask" => "255.255.255.0",
             "swift_zone" => "1",
             "uid" => "1",
             "user_node_name" => "slave-03_alerting"},
            {"fqdn" => "node-3.test.domain.local",
             "internal_address" => "10.109.2.4",
             "internal_netmask" => "255.255.255.0",
             "name" => "node-3",
             "public_address" => "10.109.1.4",
             "public_netmask" => "255.255.255.0",
             "node_roles" => ["primary-controller"],
             "storage_address" => "10.109.4.3",
             "storage_netmask" => "255.255.255.0",
             "swift_zone" => "3",
             "uid" => "3",
             "user_node_name" => "slave-01_controller"},
            {"fqdn" => "node-4.test.domain.local",
             "internal_address" => "10.109.2.7",
             "internal_netmask" => "255.255.255.0",
             "name" => "node-4",
             "node_roles" => ["elasticsearch_kibana"],
             "storage_address" => "10.109.4.5",
             "storage_netmask" => "255.255.255.0",
             "swift_zone" => "4",
             "uid" => "4",
             "user_node_name" => "Untitled (79:a7)"},
            {"fqdn" => "node-2.test.domain.local",
             "internal_address" => "10.109.2.6",
             "internal_netmask" => "255.255.255.0",
             "name" => "node-2",
             "node_roles" => ["cinder", "compute"],
             "storage_address" => "10.109.4.4",
             "storage_netmask" => "255.255.255.0",
             "swift_zone" => "2",
             "uid" => "2",
             "user_node_name" => "slave-02_compute_cinder"},
            {"fqdn" => "node-9.test.domain.local",
             "internal_address" => "10.109.2.6",
             "internal_netmask" => "255.255.255.0",
             "name" => "node-9",
             "node_roles" => ["compute"],
             "storage_address" => "10.109.4.9",
             "storage_netmask" => "255.255.255.0",
             "swift_zone" => "9",
             "uid" => "9",
             "user_node_name" => "slave-09_compute"}
        ]

        it { should run.with_params(nodes, 'name', 'node_roles').and_return(
            {"influxdb_grafana" => { "properties" => {"members" => "node-1"}},
            "infrastructure_alerting" => { "properties" => {"members" => "node-1"}},
            "primary-controller" => { "properties" => {"members" => "node-3"}},
            "elasticsearch_kibana" =>  { "properties" => {"members" => "node-4"}},
            "cinder" => { "properties" => {"members" => "node-2"}},
            "compute" => { "properties" => {"members" => "node-2,node-9"}}}
        )}
    end

end
