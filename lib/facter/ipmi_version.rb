# Provide IPMI version for hiera
require 'facter'

if Facter::Core::Execution.which('ipmitool')
    require File.join(File.dirname(__FILE__), '..', 'puppet_x', 'ipmi')

    Facter.add('ipmi_version') do
        setcode do
            IPMI.version.to_s
        end
    end
end

