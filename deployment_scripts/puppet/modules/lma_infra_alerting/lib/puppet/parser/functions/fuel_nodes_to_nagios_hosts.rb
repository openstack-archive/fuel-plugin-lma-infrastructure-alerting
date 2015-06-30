module Puppet::Parser::Functions
  newfunction(:fuel_nodes_to_nagios_hosts, :type => :rvalue,  :doc => <<-EOS
    Return a Hash grouped by node name with all attributes matching
    Nagios_Host resource properties (for nagios::host type).
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_host(): Wrong number of arguments " +
      "given (#{arguments.size} for 2") if arguments.size < 2

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)

    ip_key = arguments[1]

    result = {}
    hash.each do |role, node|
      node.each do |value|
          ip = value[ip_key]
          name = value['name']
          user_name = value['user_node_name']
          group = value['role']
          group = 'controller' if value['role'] == 'primary-controller'
          if ! result[name] then
            result[name] = {'properties' => {
                'address' => ip,
                'hostgroups' => group,
                'display_name' => "#{name}_#{user_name}",
                'alias' => "#{name}_#{user_name}",
              }
            }
          else
            result[name]['properties']['hostgroups'] = [result[name]['properties']['hostgroups'].split(',').sort().join(','), group].sort().join(',')
          end
      end
    end
    return result
  end
end

