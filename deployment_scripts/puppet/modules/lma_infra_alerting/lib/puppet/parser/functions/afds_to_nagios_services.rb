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
module Puppet::Parser::Functions
  newfunction(:afds_to_nagios_services, :type => :rvalue,  :doc => <<-EOS
    Return a Hash grouped by node name with all attributes matching
    lma_infra_alerting::nagios::services

    Returns:
          {
           'host for node-1' => {
             'hostname' => 'node-1',
             'services' => ['controller.fs', 'controller.cpu'],
           },
          }, ..
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_nagios_hosts(): Wrong number of arguments " +
      "given (#{arguments.size} for 6") if arguments.size < 6

    all_nodes = arguments[0]
    raise(Puppet::ParseError, "not a array!") if ! all_nodes.is_a?(Array)

    name_key = arguments[1]
    role_key = arguments[2]
    role_to_cluster = arguments[3]
    afds = arguments[4]
    resource = arguments[5]
    result = {}

    # get roles per node
    nodes = {}
    all_nodes.each do |node|
        name = node[name_key]
        role = node[role_key]
        if ! nodes[name] then
            nodes[name] = [].to_set
        end
        nodes[name].add(role)
    end
    nodes.each do |node, roles|
        cluster_names = [].to_set
        has_default = false
        # get cluster names for the node
        roles.each do |role|
            role_to_cluster.each do |v|
                v.each { |name, t|
                    cluster_names.add(name) if t.include?(role)
                }
            end
            cluster_names.add("default") if cluster_names.empty?
        end
        # get afds for the node
        afds_node = [].to_set
        cluster_names.each do |cluster|
            afds.select {|a| a.has_key?(cluster)}.each{|c| c[cluster].each{|i| i.keys().each{|source| afds_node.add("#{node}.#{cluster}.#{source}")}}}
        end
        # format result for puppet resource
        result["#{resource} for #{node}"] = {
            'hostname' => node,
            'services' => afds_node.to_a,
        }
    end

    return result
    end
end
