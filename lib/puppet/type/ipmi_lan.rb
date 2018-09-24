
require 'puppet/property/boolean'

Puppet::Type.newtype(:ipmi_lan) do
    @doc = <<-'DOC'
    This represents ipmi LAN channel.
    DOC

    ensurable

    newparam(:name) do
        desc 'Dummy title-holder parameter. Do not use.'

        defaultto do
            resource.title
        end
    end

    newparam(:channel, :namevar => true) do
        desc 'Channel ID (integer, namevar).'

        validate do |value|
            value.is_a? Integer or /^\d+$/ =~ value
        end

        # This must be a string value to be able to serve as an aliased resource title.
        # And that is required for purging to work.
        munge do |value|
            value.to_s
        end

        defaultto do
            resource.provider.default_channel.to_s
        end
    end

    def self.title_patterns
        [
            [ /^(\d)$/, [ [ :channel ] ] ],
            [ /^(.*)$/, [ [ :name ] ] ],
        ]
    end

    [:admin, :operator, :user, :callback].each do |role|
        newproperty(:"auth_#{role}", :array_matching => :all) do
            desc "Allows authentication methods (none, md5, md2, plain) for role #{role}"

            newvalues(:none, :md5, :md2, :plain)

            def insync is
                (is - should).empty?
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

    newproperty(:ciphers, :array_matching => :all) do
        desc 'List of ciphers to enable'

        validate do |value|
            value.is_a? Integer or /^\d+$/ =~ value
        end

        munge do |value|
            value.to_i
        end

        def insync? is
            (is - should).empty?
        end
    end
end

