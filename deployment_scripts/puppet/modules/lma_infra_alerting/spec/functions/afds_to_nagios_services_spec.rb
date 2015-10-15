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

describe 'afds_to_nagios_services' do
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
    afds = [
        {"controller"=>
            [{"system"=>["cpu-critical-controller", "cpu-warning-controller"]},
            {"fs"=>["fs-critical", "fs-warning"]}]},
        {"compute"=>
            [{"system"=>["cpu-critical-compute", "cpu-warning-compute"]},
            {"fs"=>["fs-critical", "fs-critical-compute", "fs-warning"]}]},
        {"storage"=>
            [{"system"=>["cpu-critical-storage", "cpu-warning-storage"]},
            {"fs"=>["fs-critical-storage", "fs-warning-storage"]}]},
        {"default"=>
            [{"cpu"=>["cpu-critical-default"]},
            {"fs"=>["fs-critical", "fs-warning"]}]}
    ]
    describe 'with all args' do
        it { should run.with_params(all_nodes, 'name', 'role', role_to_cluster, afds, 'host').and_return(
                           {"host for node-1"=>{
                                "hostname"=>"node-1",
                                "services"=>["node-1.default.cpu", "node-1.default.fs"]},
                            "host for node-3"=>{
                                "hostname"=>"node-3",
                                "services"=>["node-3.controller.system", "node-3.controller.fs"]},
                            "host for node-4"=>{
                                "hostname"=>"node-4",
                                "services"=>["node-4.default.cpu", "node-4.default.fs"]},
                            "host for node-2"=>{
                                "hostname"=>"node-2",
                            "services"=>["node-2.storage.system", "node-2.storage.fs", "node-2.compute.system", "node-2.compute.fs"]}})
          }
    end
end
