
Puppet::Type.newtype(:ipmi_lan) do
    @doc <<-'DOC'
    This represents ipmi LAN channel
    DOC

    ensurable

    newparam(:channel, :namevar => true) do
        desc 'Channel ID (integer, namevar).'
    end

    newproperty(:authtypes) do # TODO: array matching or something
        desc 'Sets enabled authentication methods (none, md5, md2, plain) for given roles (admin, operator, user, callback). This should be a hash { role => [ method, method, ... ], ... }'
        validate do |value|
            value.keys.find do |role|
                ! [:admin, :operator, :user, :callback].include? role
            end
            and
            value.values.flatten.find do |authtype|
                ! [:none, :md5, :md2, :plain].include? authtype
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

    newproperty(:arp_enable, :boolean => true, parent => Puppet::Property::Boolean) do
        desc 'Enable ARP responses for channel'
        defaultto :true
    end


    newproperty(:arp_gratituous, :boolean => true, parent => Puppet::Property::Boolean) do
        desc 'Send ARP announcements for channel'
        defaultto :false
    end

    newproperty(:snmp_community) do
        desc 'SNMP community string'
    end

    newproperty(:sol_enable, :boolean => true, parent => Puppet::Property::Boolean) do
        desc 'Enable Serial Over LAN'
        defaultto :false
    end

    newproperty(:sol_encryption, :boolean => true, parent => Puppet::Property::Boolean) do
        desc 'Force encryption for SOL'
        defaultto :true
    end

    newproperty(:sol_authentication, :boolean => true, parent => Puppet::Property::Boolean) do
        desc 'Force authentication for SOL'
        defaultto :true
    end

    newproperty(:ciphers, :array_matchisg => :all) do
        desc 'List of ciphers to enable'

        def insync? is
            provider.ciphers_insync? should
        end

        validate do |value|
            value.find { |id| ! id.is_a? Integer }
        end
    end
end

