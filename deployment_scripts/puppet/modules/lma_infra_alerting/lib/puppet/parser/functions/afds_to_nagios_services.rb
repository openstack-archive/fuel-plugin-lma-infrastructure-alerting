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
6. Array of alarm definitions
7. Hash table mapping metric names to the place where there are collected

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
      "given (#{arguments.size} expecting 7") if arguments.size != 7

    nodes = arguments[0]
    raise(Puppet::ParseError, "arg0 isn't an array!") if ! nodes.is_a?(Array)

    name_key = arguments[1]
    role_key = arguments[2]
    role_to_cluster = arguments[3]
    raise(Puppet::ParseError, "arg3 isn't a hash!") if ! role_to_cluster.is_a?(Hash)
    afds = arguments[4]
    raise(Puppet::ParseError, "arg4 isn't a hash!") if ! afds.is_a?(Hash)
    alarms = arguments[5]
    alarms = [] if ! alarms.is_a?(Array)
    metrics = arguments[6]
    metrics = {} if ! metrics.is_a?(Hash)

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
            default_notifications_enabled = 0
            afds_map = afds.select {|c, a| a.has_key?('apply_to_node') and a['apply_to_node'] == cluster}
            afds_map.each do |logical_cluster, a|
                if a.has_key?('alerting') and a['alerting'] != 'disabled'
                    configure=true
                    if a['alerting'] == 'enabled_with_notification'
                        default_notifications_enabled = 1
                    end
                else
                    configure=false
                end

                a['members'].each do |source, afd|
                    # collect metric names
                    m = Set.new([])
                    notifications_enabled = default_notifications_enabled
                    if afd.has_key?('alerting') and afd['alerting'] != 'disabled'
                        configure = true
                        if afd['alerting'] == 'enabled_with_notification'
                            notifications_enabled = 1
                        end
                    end
                    afd['alarms'].each do |alarm|
                        # find metric definition
                        alarm_def = alarms.select {|defi| defi['name'] == alarm}
                        next if alarm_def.empty?
                        alarm_def[0]['trigger']['rules'].each do |r|
                            m << r['metric']
                        end
                    end
                    matches = true
                    m.each do |metric_name|
                        if metrics.has_key?(metric_name) and metrics[metric_name]['collected_on'] == 'aggregator'
                            # skip the source if one metric is collected on 'aggregator'
                            matches = false
                        end

                    end
                    if configure and matches
                        result["#{ logical_cluster }.#{source} checks for #{ node } notif #{notifications_enabled}"] = {
                            'hostname' => node,
                            'services' => {"#{node}.#{logical_cluster}.#{source}" => "#{ logical_cluster }.#{ source }".gsub(/\s+/, '_')},

                            'notifications_enabled' => notifications_enabled,
                        }
                    end
                end
            end
        end
    end

    return result
  end
end
