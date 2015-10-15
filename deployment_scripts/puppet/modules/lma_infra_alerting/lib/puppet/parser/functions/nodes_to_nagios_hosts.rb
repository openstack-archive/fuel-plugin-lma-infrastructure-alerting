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
  newfunction(:nodes_to_nagios_hosts, :type => :rvalue,  :doc => <<-EOS
    Return a Hash grouped by host_name with all attributes matching
    Nagios_Host resource properties (for nagios::host type).

    Returns:
          {
           'node-1' => {
             'properties' => { .. nagios_host properties .. },
             'custom_vars' => { .. nagios_host custom variables .. },
           },
          }, ..
          {
           'node-2' => {
             'properties' => { .. nagios_host properties .. },
             'custom_vars' => { .. nagios_host custom variables .. },
           },
          }, ...
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_nagios_hosts(): Wrong number of arguments " +
      "given (#{arguments.size} for 6") if arguments.size < 6

    all_nodes = arguments[0]
    raise(Puppet::ParseError, "not a array!") if ! all_nodes.is_a?(Array)

    name_key = arguments[1]
    ip_key = arguments[2]
    display_name_keys = arguments[3]
    custom_vars_keys = arguments[4] or []
    role_key = arguments[5]
    #role_to_cluster = arguments[6]

    result = {}
    hostgroups = {}

    all_nodes.each do |node|
        role = node[role_key]
        name = node[name_key]
        ip = node[ip_key]
        display_name = display_name_keys.collect{ |x| node[x] }.join('_')

        if ! result[name] then
            #clusters = [].to_set
            roles = [].to_set
            all_nodes.each{|v|
                if v[name_key] == name then
                    roles.add(v[role_key])
                    #role_to_cluster.each do |cl|
                    #    cl.each{|n,v| clusters.add(n) if v.include?(role) }
                    #end
                end
            }
            #if clusters.empty? then
            #    clusters = ['default']
            #end
            result[name] = {
                'properties' => {
                    'address' => ip,
                    #'hostgroups' => clusters.to_a.concat(roles.to_a).uniq().sort().join(','),
                    'hostgroups' =>roles.to_a.sort().join(','),
                    'display_name' => display_name,
                    'alias' => display_name,
                },
                'custom_vars' => Hash[*custom_vars_keys.collect{|x| ["_#{x}", node[x]]}.flatten()],
            }
        end
    end
    return result
end
end
