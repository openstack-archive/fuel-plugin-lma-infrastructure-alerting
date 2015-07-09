module Puppet::Parser::Functions
  newfunction(:fuel_nodes_to_nagios_hostgroups, :type => :rvalue,  :doc => <<-EOS
    Return a Hash grouped by node name with all attributes matching
    Nagios_Host resource properties (for nagios::hostgroup type).
    {
     'controller' => {
       'properties' => {
         'members' => 'node-1,node-2',
        },
      },
    }
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_host(): Wrong number of arguments " +
      "given (#{arguments.size} for 2") if arguments.size < 1

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)

    result = {}
    hash.each do |role, node|
      node.each do |value|
          name = value['name']
          group = value['role']
          group = 'controller' if value['role'] == 'primary-controller'
          if ! result[group] then
            result[group] = {'properties' => {
                'members' => name,
              }
            }
          else
            result[group]['properties']['members'] = [result[group]['properties']['members'].split(',').sort().join(','), name].sort().join(',')
          end
      end
    end
    return result
  end
end


