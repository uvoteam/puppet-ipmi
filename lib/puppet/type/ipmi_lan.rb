
Puppet::Type.newtype(:ipmi_lan) do
    @doc <<-'DOC'
    This represents ipmi LAN channel.
    DOC

    ensurable

    newparam(:channel, :namevar => true) do
        desc 'Channel ID (integer, namevar).'
        validate do |value|
            /^\d+$/ =~ value
        end
    end

    [:admin, :operator, :user, :callback].each do |role|
        newproperty(:"auth_#{role}", :array_matching => :all) do
            desc "Allows authentication methods (none, md5, md2, plain) for role #{role}"

            #validate do |value|
            #    debug "validating auth_#{role} (value = [#{value.first.class.name}])"
            #    value.is_a?(Array) and (value - [:none, :md5, :md2, :plain]).empty?
            #end

            newvalues(:none, :md5, :md2, :plain)

            munge do |value|
                value.sort.uniq
            end
        end
    end

    newproperty(:address) do
        desc 'IP address for the channel'
        validate do |value|
            /^\d+\.\d+\.\d+\.\d+$/ =~ value
        end
    end

    newproperty(:netmask) do
        desc 'Network mask for the channel'
        validate do |value|
            /^\d+\.\d+\.\d+\.\d+$/ =~ value
        end
    end

    newproperty(:gateway) do
        desc 'Default gateway address for the channel'
        validate do |value|
            /^\d+\.\d+\.\d+\.\d+$/ =~ value
        end
    end

    newproperty(:backup_gateway) do
        desc 'Backup gateway address for the channel'
        validate do |value|
            /^\d+\.\d+\.\d+\.\d+$/ =~ value
        end
    end

    newproperty(:arp_enable) do
        newvalues(:false, :true, :advertise)
        desc 'Enable ARP responses for channel (true, false, advertise)'
    end

    newproperty(:snmp_community) do
        desc 'SNMP community string'
    end

    newproperty(:sol_enable, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Enable Serial Over LAN'
    end

    newproperty(:sol_encryption, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Force encryption for SOL'
    end

    newproperty(:sol_authentication, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Force authentication for SOL'
    end

    newproperty(:ciphers, :array_matchisg => :all) do
        desc 'List of ciphers to enable'

        validate do |value|
            debug "called validate on: #{value}"
            not value.find { |id| debug "validating #{value} of type #{value.class.name}"; /^\d+$/ =~ id }
        end

        munge do |value|
            debug "called munge on: #{value}"
            value.map(&:to_i).sort.uniq
        end
    end
end

