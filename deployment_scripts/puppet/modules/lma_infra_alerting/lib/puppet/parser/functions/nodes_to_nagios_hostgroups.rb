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

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)
    name_key = arguments[1]
    group_key = arguments[2]
    group_map = arguments[3]

    result = {}
    hash.each do |role, node|
      node.each do |value|
          name = value[name_key]
          group = value[group_key]
          if group_map and ! group_map.empty?
              if group_map.include? group
                  group = group_map[group]
              end
          end
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


