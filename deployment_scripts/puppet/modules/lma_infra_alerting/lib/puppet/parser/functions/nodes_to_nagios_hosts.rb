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
      "given (#{arguments.size} for 4") if arguments.size < 4

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)

    name_key = arguments[1]
    ip_key = arguments[2]
    display_name_keys = arguments[3]
    custom_vars_keys = arguments[4] or []

    result = {}
    hash.each do |role, nodes|
      nodes.each do |value|
          ip = value[ip_key]
          name = value[name_key]
          display_name = display_name_keys.collect{ |x| value[x] }.join('_')
          if ! result[name] then
            result[name] = {
                'properties' => {
                  'address' => ip,
                  # Note: due to incompatible behavior between ruby 1.8.7 and 1.9.3
                  # the select method return an Array or a Hash.
                  'hostgroups' => Hash[hash.select{|k,v| v.count{|n| n[name_key] == name} > 0 }].keys(),
                  'display_name' => display_name,
                  'alias' => display_name,
                },
                'custom_vars' => Hash[*custom_vars_keys.collect{|x| ["_#{x}", value[x]]}.flatten()],
            }
          end
      end
    end
    return result
  end
end
