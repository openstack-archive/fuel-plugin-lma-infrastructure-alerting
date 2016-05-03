#    Copyright 2016 Mirantis, Inc.
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
  newfunction(:get_check_http_params, :type => :rvalue,  :doc => <<-EOS
Returns a list of hashes that can be used to create/update
lma_infra_alerting::nagios::check_http resources.

It expects 2 arguments:
- Hash of nodes, each node being described as a hash.
- The network role mapping to the checked IP address.
- The prefix for the service name.

Example:

  $hash = :get_check_http_params(
    {'node-1' => {'network_roles' => {'influxdb_vip' => '10.109.2.3'}},
     'node-2' => {'network_roles' => {'influxdb_vip' => '10.109.2.4'}}},
    'influxdb_vip',
    'Grafana'
  )

Would return:

  {'Grafana_node-1' => {'host_name' => 'node-1', 'custom_address' => '10.109.2.3'},
   'Grafana_node-2' => {'host_name' => 'node-2', 'custom_address' => '10.109.2.4'}}

    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "get_check_http_params(): Wrong number of arguments " +
      "given (#{arguments.size} for 3") if arguments.size != 3

    nodes = arguments[0]
    raise(Puppet::ParseError, "arg0 is not a hash!") if ! nodes.is_a?(Hash)
    network_role = arguments[1]
    key_prefix = arguments[2]

    result = {}
    nodes.keys.sort.each do |k|
        ip = nodes[k]['network_roles'][network_role]
        raise Puppet::ParseError, "Can't find network role #{network_role} for node #{k}" if ip.nil?
        result["#{key_prefix}_#{k}"] = {'host_name' => k, 'custom_address' => ip}
    end

    return result
  end
end
