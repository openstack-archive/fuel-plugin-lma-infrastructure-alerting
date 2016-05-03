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
  newfunction(:nodes_to_nagios_hosts, :type => :rvalue,  :doc => <<-EOS
Returns a hash that can be used to create/update nagios::host resources.

It expects 5 arguments:
1. An array of nodes, each node being described as a hash.
2. The key containing the node's name.
3. The key containing the network role to resolve node's IP address.
4. The list of keys that will be used to build the node's display name.
5. The list of keys that will be used to build the node's custom variables.

*Example:*

  $hash = nodes_to_nagios_hostgroups(
    [{'name' => 'node-1', node_roles => ['controller'],
      'network_roles' => {'management' => '10.20.0.5'}, 'user_node_name' => 'foo', 'uid' => '1'},
     {'name' => 'node-2', 'node_roles' => ['compute', 'cinder'],
      'network_roles' => {'management' => '10.20.0.4', 'storage' => '10.20.2.4'}, 'user_node_name' => 'bar', 'uid' => '2'},
    'name',
    'management',
    ['name', 'user_node_name'],
    ['uid']
  )

Would return:

  {
    'node-1' => {
      'properties' => {
        'address' => '10.20.0.5',
        'display_name' => 'node-1_foo'
        'alias' => 'node-1_foo'
      },
      'custom_vars' => {
        '_uid' => '1'
      }
    },
    'node-2' => {
      'properties' => {
        'address' => '10.20.0.4',
        'display_name' => 'node-2_bar'
        'alias' => 'node-2_bar'
      },
      'custom_vars' => {
        '_uid' => '2'
      }
    },
  }
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_nagios_hosts(): Wrong number of arguments " +
      "given (#{arguments.size} expecting 5") if arguments.size != 5

    nodes = arguments[0]
    raise(Puppet::ParseError, "arg0 isn't a array!") if ! nodes.is_a?(Array)

    name_key = arguments[1]
    ip_key = arguments[2]
    display_name_keys = arguments[3]
    custom_vars_keys = arguments[4] or []

    result = {}

    nodes.each do |node|
        node_name = node[name_key]

        display_name = display_name_keys.collect{ |x| node[x] }.join('_')
        custom_vars = {}
        custom_vars_keys.each do |x|
            custom_vars["_#{x}"] = node[x].is_a?(Array) ? node[x].join(',') : node[x].to_s()
        end

        result[node_name] = {
            'properties' => {
                'address' => node['network_roles'][ip_key],
                'display_name' => display_name,
                'alias' => display_name,
            },
            'custom_vars' => custom_vars
        }
    end

    return result
end
end
