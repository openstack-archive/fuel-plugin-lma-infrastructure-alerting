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
module Puppet::Parser::Functions
  newfunction(:afds_to_nagios_services, :type => :rvalue,  :doc => <<-EOS
Returns a hash that can be used to create/update nagios::service resources.

It expects 5 arguments:
1. An array of nodes, each node being described as a hash.
2. The key containing the node's name.
3. The key containing the node's role.
4. The mapping between AFD profiles and node's roles
5. The mapping between AFD profiles and alarms

*Examples:*

  $hash = afds_to_nagios_services(
    [{'name' => 'node-1', node_roles => ['primary-controller']}, {'name' => 'node-2', node_roles => ['controller']}],
    'name',
    'node_roles',
    {'control_nodes' => {'roles' => ['primary-controller', 'controller']}},
    {'control_nodes' => {'cpu' => ['alarm1'], 'fs' => ['alarm1']}}
  )

Would return:

  {
    'control_nodes.cpu, control_nodes.fs checks for node-1' => {
      'hostname' => 'node-1',
      'services' => ['control_nodes.cpu', 'control_nodes.fs'],
    },
  }
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "afds_to_nagios_services(): Wrong number of arguments " +
      "given (#{arguments.size} expecting 5") if arguments.size != 5

    nodes = arguments[0]
    raise(Puppet::ParseError, "arg0 isn't an array!") if ! nodes.is_a?(Array)

    name_key = arguments[1]
    role_key = arguments[2]
    role_to_cluster = arguments[3]
    raise(Puppet::ParseError, "arg3 isn't a hash!") if ! role_to_cluster.is_a?(Hash)
    afds = arguments[4]
    raise(Puppet::ParseError, "arg4 isn't a hash!") if ! afds.is_a?(Hash)

    result = {}

    # collect the cluster memberships for every node
    node_clusters = {}
    nodes.each do |node|
        node_name = node[name_key]
        unless node_clusters.has_key?(node_name) then
            node_clusters[node_name] = Set.new([])
        end
        role_to_cluster.each do |cluster, roles|
            node_clusters[node_name] << cluster if (roles['roles'] & node[role_key]).length > 0
        end
    end

    # collect the AFDs associated to the node using its cluster memberships
    node_clusters.each do |node, clusters|
        clusters << "default" if clusters.empty?

        clusters.each do |cluster|
            notifications_enabled = 0
            afds_map = afds.select {|c, a| a.has_key?('apply_to_node') and a['apply_to_node'] == cluster}
            afds_map.each do |logical_cluster, a|
                node_services = {}
                if a.has_key?('alerting') and a['alerting'] != 'disabled'
                    configure=true
                else
                    configure=false
                end

                if configure
                    if a['alerting'] == 'enabled_with_notification'
                        notifications_enabled = 1
                    end
                    a['alarms'].keys.each do |source|
                         node_services["#{node}.#{logical_cluster}.#{source}"] = "#{ logical_cluster }.#{ source }".gsub(/\s+/, '_')
                    end
                end

                unless node_services.empty? then
                    result["#{ logical_cluster } checks for #{ node }"] = {
                        'hostname' => node,
                        'services' => node_services,
                        'notifications_enabled' => notifications_enabled,
                    }
                end
            end
        end
    end

    return result
  end
end
