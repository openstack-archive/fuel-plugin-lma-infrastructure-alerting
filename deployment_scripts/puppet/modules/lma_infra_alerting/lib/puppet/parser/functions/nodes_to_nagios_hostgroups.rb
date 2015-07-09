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
      "given (#{arguments.size} for 2") if arguments.size < 2

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)
    name_key = arguments[1]

    result = {}
    hash.each do |group, nodes|
        result[group] = {'properties' => {'members' => nodes.collect{|x| x[name_key]}.sort().join(',') }}
                      end
    return result
  end
end
