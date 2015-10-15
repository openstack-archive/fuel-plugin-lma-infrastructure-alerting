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
  newfunction(:nodes_to_nagios_hostgroups, :type => :rvalue,  :doc => <<-EOS
    Return a Hash grouped by role with all attributes matching
    Nagios_Hostgroup resource properties (for nagios::hostgroup type).
    {
     'controller' => {
       'properties' => {
         'members' => 'node-1,node-2',
        },
      },
    }
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_nagios_hostgroups(): Wrong number of arguments " +
      "given (#{arguments.size} for 3") if arguments.size < 3

    all_nodes = arguments[0]
    raise(Puppet::ParseError, "arg0 not an array!") if ! all_nodes.is_a?(Array)
    name_key = arguments[1]
    role_key = arguments[2]
    role_to_cluster = arguments[3]
    raise(Puppet::ParseError, "arg 3 not a array!") if ! role_to_cluster.is_a?(Array)

    result = {}
    roles = [].to_set
    all_nodes.each do |node|
        role = node[role_key]
        roles.add(role)
    end

    roles.each do |role|
        nodes = []
        all_nodes.each do |node|
            if node[role_key] == role then
                nodes.push(node[name_key])
            end
        end
        result[role] = {
            'properties' => {
                'members' => nodes.sort().join(','),
            }
        }
    end
    return result
  end
end
