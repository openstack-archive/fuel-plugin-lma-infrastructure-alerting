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
# Configure Nagios server and Nagios CGI
# Add services status monitoring and contact for notifications
#
require 'spec_helper'

describe 'nodes_to_nagios_hosts' do
    all_nodes = [
    {"fqdn"=>"node-1.test.domain.local",
     "internal_address"=>"10.109.2.5",
     "internal_netmask"=>"255.255.255.0",
     "name"=>"node-1",
     "role"=>"influxdb_grafana",
     "storage_address"=>"10.109.4.2",
     "storage_netmask"=>"255.255.255.0",
     "swift_zone"=>"1",
     "uid"=>"1",
     "user_node_name"=>"slave-03_alerting"},
    {"fqdn"=>"node-1.test.domain.local",
     "internal_address"=>"10.109.2.5",
     "internal_netmask"=>"255.255.255.0",
     "name"=>"node-1",
     "role"=>"infrastructure_alerting",
     "storage_address"=>"10.109.4.2",
     "storage_netmask"=>"255.255.255.0",
     "swift_zone"=>"1",
     "uid"=>"1",
     "user_node_name"=>"slave-03_alerting"},
    {"fqdn"=>"node-3.test.domain.local",
     "internal_address"=>"10.109.2.4",
     "internal_netmask"=>"255.255.255.0",
     "name"=>"node-3",
     "public_address"=>"10.109.1.4",
     "public_netmask"=>"255.255.255.0",
     "role"=>"primary-controller",
     "storage_address"=>"10.109.4.3",
     "storage_netmask"=>"255.255.255.0",
     "swift_zone"=>"3",
     "uid"=>"3",
     "user_node_name"=>"slave-01_controller"},
    {"fqdn"=>"node-4.test.domain.local",
     "internal_address"=>"10.109.2.7",
     "internal_netmask"=>"255.255.255.0",
     "name"=>"node-4",
     "role"=>"elasticsearch_kibana",
     "storage_address"=>"10.109.4.5",
     "storage_netmask"=>"255.255.255.0",
     "swift_zone"=>"4",
     "uid"=>"4",
     "user_node_name"=>"Untitled (79:a7)"},
    {"fqdn"=>"node-2.test.domain.local",
     "internal_address"=>"10.109.2.6",
     "internal_netmask"=>"255.255.255.0",
     "name"=>"node-2",
     "role"=>"cinder",
     "storage_address"=>"10.109.4.4",
     "storage_netmask"=>"255.255.255.0",
     "swift_zone"=>"2",
     "uid"=>"2",
     "user_node_name"=>"slave-02_compute_cinder"},
    {"fqdn"=>"node-2.test.domain.local",
     "internal_address"=>"10.109.2.6",
     "internal_netmask"=>"255.255.255.0",
     "name"=>"node-2",
     "role"=>"compute",
     "storage_address"=>"10.109.4.4",
     "storage_netmask"=>"255.255.255.0",
     "swift_zone"=>"2",
     "uid"=>"2",
     "user_node_name"=>"slave-02_compute_cinder"}
    ]

    role_to_cluster = [
           {"controller"=>["primary-controller", "controller"]},
           {"compute"=>["compute"]},
           {"storage"=>["cinder", "ceph-osd"]}
    ]

    describe 'with all args' do
        it { should run.with_params(all_nodes, 'name', 'internal_address',
                                    ['name', 'user_node_name'],
                                    ['role', 'fqdn'], 'role', role_to_cluster).and_return(
        {"node-1"=>{
            "properties"=>{"address"=>"10.109.2.5", "hostgroups"=>"influxdb_grafana,infrastructure_alerting", "display_name"=>"node-1_slave-03_alerting", "alias"=>"node-1_slave-03_alerting"},
            "custom_vars"=>{"_role"=>"influxdb_grafana", "_fqdn"=>"node-1.test.domain.local"}},
        "node-3"=>{
            "properties"=>{"address"=>"10.109.2.4", "hostgroups"=>"primary-controller", "display_name"=>"node-3_slave-01_controller", "alias"=>"node-3_slave-01_controller"},
            "custom_vars"=>{"_role"=>"primary-controller", "_fqdn"=>"node-3.test.domain.local"}},
        "node-4"=>{
            "properties"=>{"address"=>"10.109.2.7", "hostgroups"=>"elasticsearch_kibana", "display_name"=>"node-4_Untitled (79:a7)", "alias"=>"node-4_Untitled (79:a7)"},
            "custom_vars"=>{"_role"=>"elasticsearch_kibana", "_fqdn"=>"node-4.test.domain.local"}},
        "node-2"=>{
            "properties"=>{"address"=>"10.109.2.6", "hostgroups"=>"cinder,compute", "display_name"=>"node-2_slave-02_compute_cinder", "alias"=>"node-2_slave-02_compute_cinder"},
            "custom_vars"=>{"_role"=>"cinder", "_fqdn"=>"node-2.test.domain.local"}}
        }
                                    )
            }
    end
end

