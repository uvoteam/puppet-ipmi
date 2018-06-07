
Facter.add('ipmi_users') do
  confine :kernel => 'Linux'
  confine { Facter::Core::Execution.which('ipmitool') }

  TO_PRIV = {
    'ADMINISTRATOR' => 'administrator',
    'OPERATOR'      => 'operator',
    'USER'          => 'user',
    'CALLBACK'      => 'callback',
    'NO ACCESS'     => 'disabled',
  }.freeze

  STATUS_TO_BOOLEAN = {
    'disabled' => false,
    'enabled'  => true,
  }.freeze

  YES_TO_BOOLEAN = {
    'Yes' => true,
    'No'  => false,
  }.freeze

  setcode do
    summary = Facter::Core::Execution.execute('ipmitool channel getaccess 1')
    summary.split(/\n\n/).map do |info|
      hash = info.lines.map(&:strip).map { |line| line.split(/\s*:\s*/, 2) }.to_h
      hash.map do |key, value|
        case key
        when 'Maximum User IDs'
          [ 'max_users', value.to_i ]
        when 'Enabled User IDs'
          [ 'users',     value.to_i ]
        when 'User ID'
          [ 'uid',       value.to_i ]
        when 'User Name'
          [ 'name',      value ]
        when 'Fixed Name'
          [ 'immutable', YES_TO_BOOLEAN[value] ]
        when 'Access Available'
          [ 'perms',     value.split(/\s*\/\s*/) ]
        when 'Link Authentication'
          [ 'link_auth', STATUS_TO_BOOLEAN[value] ]
        when 'IPMI Messaging'
          [ 'ipmi_msg',  STATUS_TO_BOOLEAN[value] ]
        when 'Privilege Level'
          [ 'priv',      TO_PRIV[value] ]
        when 'Enable Status'
          [ 'enabled',   STATUS_TO_BOOLEAN[value] ]
        else
          Facter.warn("Unknown key in 'ipmitool channel getaccess 1' output: '#{key}' => '#{value}'")
        end
      end.to_h
    end.select { |hash| hash['uid'] }.sort_by { |user| user['uid'] }
  end
end

