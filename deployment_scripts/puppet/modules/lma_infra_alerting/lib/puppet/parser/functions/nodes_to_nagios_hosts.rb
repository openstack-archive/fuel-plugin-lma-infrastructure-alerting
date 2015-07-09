module Puppet::Parser::Functions
  newfunction(:nodes_to_nagios_hosts, :type => :rvalue,  :doc => <<-EOS
    Return a Hash grouped by host_name with all attributes matching
    Nagios_Host resource properties (for nagios::host type).
    {
     'node-1' => {
       'properties' => { .. nagios_host properties .. },
       'custom_vars' => { .. nagios_host custom variables .. },
     },
    }
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nodes_to_nagios_hosts(): Wrong number of arguments " +
      "given (#{arguments.size} for 6") if arguments.size < 6

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)

    name_key = arguments[1]
    ip_key = arguments[2]
    group_key = arguments[3]
    display_name_keys = arguments[4]
    alias_keys = arguments[5]
    custom_vars_keys = arguments[6]
    group_map = arguments[7]

    result = {}
    hash.each do |role, node|
      node.each do |value|
          ip = value[ip_key]
          name = value[name_key]
          display_name_list = []
          value.each{ |k, v|
              if display_name_keys.include? k
                  display_name_list << v
              end
          }
          display_name = display_name_list.join('_')
          group = value[group_key]
          if group_map and ! group_map.empty?
              if group_map.include? group
                  group = group_map[group]
              end
          end
          if ! result[name] then
            result[name] = {
                'properties' => {
                  'address' => ip,
                  'hostgroups' => group,
                  'display_name' => display_name,
                  'alias' => display_name,
                }
            }
            custom_vars = {}
            if ! custom_vars_keys.empty?
                value.each{|k, v|
                    custom_vars["_#{k}"] = v if custom_vars_keys.include? k
                }
                result[name]['custom_vars'] = custom_vars
            end
          else
            result[name]['properties']['hostgroups'] = [result[name]['properties']['hostgroups'].split(',').sort().join(','), group].sort().join(',')
          end
      end
    end
    return result
  end
end

