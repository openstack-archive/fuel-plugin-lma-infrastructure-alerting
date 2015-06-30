module Puppet::Parser::Functions
  newfunction(:nagios_filter_per_state, :type => :rvalue,  :doc => <<-EOS
    Return a Hash filter by ensure property
    EOS
 ) do |arguments|

    raise(Puppet::ParseError, "nagios_filter_per_ensure(): Wrong number of arguments " +
      "given (#{arguments.size} for 2") if arguments.size < 2

    hash = arguments[0]
    raise(Puppet::ParseError, "not a hash!") if ! hash.is_a?(Hash)
    state = arguments[1]

    result = {}
    hash.each do |group, node|
      if node['ensure'] == state
          result[group] = node
      end
    end
    return result
  end
end


