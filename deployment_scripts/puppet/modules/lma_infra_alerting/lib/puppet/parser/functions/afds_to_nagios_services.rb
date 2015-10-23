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
4. The mapping between clusters and node's roles
4. The mapping between cluster and the AFD alarms

*Examples:*

  $hash = afds_to_nagios_services(
    [{'name' => 'node-1', role => 'primary-controller'}, {'name' => 'node-2', role => 'controller'}],
    'name', 'role',
    [{'control_nodes' => ['primary-controller', 'controller']}],
    [{'control_nodes' => [{'cpu' => ['alarm1']}, {'fs' => ['alarm1']}]}]
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
    raise(Puppet::ParseError, "arg3 isn't an array!") if ! role_to_cluster.is_a?(Array)
    afds = arguments[4]
    raise(Puppet::ParseError, "arg4 isn't an array!") if ! afds.is_a?(Array)

    result = {}

    # collect the cluster memberships for every node
    node_clusters = {}
    nodes.each do |node|
        node_name = node[name_key]
        unless node_clusters.has_key?(node_name) then
            node_clusters[node_name] = Set.new([])
        end
        role_to_cluster.each do |x|
            x.each do |cluster, roles|
                node_clusters[node_name] << cluster if roles.include?(node[role_key])
            end
        end
    end

    # collect the AFDs associated to the node using its cluster memberships
    node_clusters.each do |node, clusters|
        clusters << "default" if clusters.empty?

        node_services = {}
        clusters.each do |cluster|
            afds.each do |x|
                (x[cluster] || []).each do |y|
                    y.keys.sort.each do |source|
                        node_services["#{node}.#{cluster}.#{source}"] = "#{ cluster }.#{ source }".gsub(/\s+/, '_')
                    end
                end
            end
        end

        unless node_services.empty? then
            result["#{ clusters.to_a.sort.join(', ') } checks for #{ node }"] = {
                'hostname' => node,
                'services' => node_services
            }
        end
    end

    return result
  end
end
