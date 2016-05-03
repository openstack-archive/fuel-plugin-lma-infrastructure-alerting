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
  newfunction(:nodes_to_nagios_hostgroups, :type => :rvalue,  :doc => <<-EOS
Returns a hash that can be used to create/update nagios::hostgroup resources.
Nagios hostgroups are mapped to the roles defined in the current environment.

It expects 3 arguments:
1. An array of nodes, each node being described as a hash.
2. The key containing the node's name.
3. The key containing the node's role.

*Examples:*

  $hash = nodes_to_nagios_hostgroups(
    [{'name' => 'node-1', 'node_roles' => ['controller']}, {'name' => 'node-2', node_roles => ['controller']}],
    'name', 'node_roles'
  )

Would return:

  {'controller' => {'properties' => {'members' => 'node-1,node-2'}}}

    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_nagios_hostgroups(): Wrong number of arguments " +
      "given (#{arguments.size} for 3") if arguments.size != 3

    nodes = arguments[0]
    raise(Puppet::ParseError, "arg0 is not an array!") if ! nodes.is_a?(Array)
    name_key = arguments[1]
    role_key = arguments[2]

    result = {}
    roles = Set.new([])
    nodes.each do |node|
        roles.merge(node[role_key])
    end

    roles.each do |role|
        result[role] = {
            'properties' => {
                'members' => nodes.select{|x| x[role_key].include?(role)}.collect{|x| x[name_key]}.sort().join(','),
            }
        }
    end

    return result
  end
end
