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

describe 'afds_to_nagios_services' do
    all_nodes = [
    {"fqdn" => "node-5.test.domain.local",
     "internal_address" => "10.109.5.5",
     "internal_netmask" => "255.255.255.0",
     "name" => "node-5",
     "node_roles" => ["elasticsearch_kibana"],
     "storage_address" => "10.109.10.2",
     "storage_netmask" => "255.255.255.0",
     "swift_zone" => "1",
     "uid" => "5",
     "user_node_name" => "slave-03_alerting"},
    {"fqdn" => "node-1.test.domain.local",
     "internal_address" => "10.109.2.5",
     "internal_netmask" => "255.255.255.0",
     "name" => "node-1",
     "node_roles" => ["influxdb_grafana", "infrastructure_alerting"],
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
    {"fqdn" => "node-42.test.domain.local",
     "internal_address" => "10.109.2.42",
     "internal_netmask" => "255.255.255.0",
     "name" => "node-2",
     "node_roles" => ["foo-role"],
     "storage_address" => "10.109.4.42",
     "storage_netmask" => "255.255.255.0",
     "swift_zone" => "2",
     "uid" => "42",
     "user_node_name" => "slave-42_foo-role"},
    ]

    role_to_cluster = {
        "controller" => {"roles" => ["primary-controller", "controller"]},
        "compute" => {"roles" => ["compute"]},
        "storage" => {"roles" => ["cinder", "ceph-osd"]},
        "elasticsearch" => {"roles" => ["elasticsearch_kibana"]},
        "foo" => {"roles" => ["foo-role"]}
    }
    afds = {
        "controller" => {
            "apply_to_node" => "controller",
            "alerting" => "enabled_with_notification",
            "alarms" => {
                "system-ctrl" => ["cpu-critical-controller", "cpu-warning-controller"],
                "fs" => ["fs-critical", "fs-warning"]
            }
        },
        "compute" => {
            "apply_to_node" => "compute",
            "alerting" => "enabled_with_notification",
            "alarms" => {
                "system-compute" => ["cpu-critical-compute", "cpu-warning-compute"],
                "fs" => ["fs-critical", "fs-critical-compute", "fs-warning"]
            }
        },
        "storage" => {
            "apply_to_node" => "storage",
            "alerting" => "enabled_with_notification",
            "alarms" => {
                "system-storage" => ["cpu-critical-storage", "cpu-warning-storage"],
                "fs" => ["fs-critical-storage", "fs-warning-storage"]
            }
        },
        "elasticsearch-cluster" => {
            "apply_to_node" => "elasticsearch",
            "alerting" => "enabled",
            "alarms" => {
                "cpu" => ["cpu-critical-es"],
                "fs" => ["fs-critical-es", "fs-warning-es"]
            }
        },
        "default" => {
            "apply_to_node" => "default",
            "alerting" => "enabled",
            "alarms" => {
                "cpu" => ["cpu-critical-default"],
                "fs" => ["fs-critical", "fs-warning"]
            }
        },
        "bar-cluster" => {
            "apply_to_node" => "bar",
            "alerting" => "disabled",
            "alarms" => {
                "cpu" => ["cpu-critical-default"],
                "fs" => ["fs-critical", "fs-warning"]
            }
        }
    }
    describe 'with arguments' do
        it { should run.with_params(all_nodes, 'name', 'node_roles', role_to_cluster, afds).and_return(
           {
               "default checks for node-1" => {
                "hostname" => "node-1",
                "notifications_enabled" => 0,
                "services" => {
                    "node-1.default.cpu" => "default.cpu",
                    "node-1.default.fs" => "default.fs",
                }},
            "controller checks for node-3" => {
                "hostname" => "node-3",
                "notifications_enabled" => 1,
                "services" => {
                    "node-3.controller.fs" => "controller.fs",
                    "node-3.controller.system-ctrl" => "controller.system-ctrl"
                }},
            "elasticsearch-cluster checks for node-4" => {
                "hostname" => "node-4",
                "notifications_enabled" => 0,
                "services" => {
                    "node-4.elasticsearch-cluster.cpu" => "elasticsearch-cluster.cpu",
                    "node-4.elasticsearch-cluster.fs" => "elasticsearch-cluster.fs"
                }},
            "elasticsearch-cluster checks for node-5" => {
                "hostname" => "node-5",
                "notifications_enabled" => 0,
                "services" => {
                    "node-5.elasticsearch-cluster.cpu" => "elasticsearch-cluster.cpu",
                    "node-5.elasticsearch-cluster.fs" => "elasticsearch-cluster.fs"
                }},
            "compute checks for node-2" => {
                "hostname" => "node-2",
                "notifications_enabled" => 1,
                "services" => {
                    "node-2.compute.fs" => "compute.fs",
                    "node-2.compute.system-compute" => "compute.system-compute",
                }},
            "storage checks for node-2" => {
                "hostname" => "node-2",
                "notifications_enabled" => 1,
                "services" => {
                    "node-2.storage.fs" => "storage.fs",
                    "node-2.storage.system-storage" => "storage.system-storage"
                }}
           })
        }
    end
end
