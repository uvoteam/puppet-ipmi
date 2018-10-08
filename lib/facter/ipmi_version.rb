# Provide IPMI version for hiera
require 'facter'

if Facter::Core::Execution.which('ipmitool')
    require File.join(File.dirname(__FILE__), '..', 'puppet_x', 'ipmi')

    if IPMI.present?
        Facter.add('ipmi_version') do
            setcode do
                IPMI.version.to_s
            end
        end
    else
        Puppet.debug('Unable to detect IPMI presence, not collecting facts')
    end
end

