
require 'puppet/property/boolean'
require 'puppet/parameter/boolean'

Puppet::Type.newtype(:ipmi_user) do
    @doc = <<-'DOC'
    This represents ipmi user.
    You can optionally define userid, either as resource param, or as part of title:
    "${username}:${userid}"
    DOC

    # we add ensure parameter here only to be able to use resource purging.
    # otherwise we could just sync all parameters.
    ensurable

    # this is needed for resource discovery to work (resources can have empty username)
    # and to have convenient access to the user name parameter value
    newparam(:name) do
        desc 'Dummy parameter to hold resource title. Do not use.'

        defaultto do
            resource.title
        end
    end

    newparam(:userid, :namevar => true) do
        desc 'User ID (integer, namevar). When creating user, will be automatically assigned first free one, if not specified.'
        munge do |value|
            value.to_i
        end
    end

    newproperty(:username) do
        desc 'Name for this user (namevar)'
    end

    def self.title_patterns
        [
            [ /^(\S*):(\d+)$/,        [ [ :username ], [ :userid ] ] ],
            [ /^(\d+)$/,              [ [ :userid ] ] ],
            [ /^(\S*)$/,              [ [ :username ] ] ],
        ]
    end

    newproperty(:enable, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'This defines if user should be enabled or disabled.'
    end

    newproperty(:immutable, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'This read-only property indicates, if user name is marked as "fixed".'
        validate do |value|
            raise ArgumentError, 'IPMI does not allow to change username immutability'
        end
    end

    newproperty(:password) do
        desc 'Password for ipmi user'

        def should_to_s value
            '*' * value.length
        end

        def insync? is
            provider.password_insync? should
        end
    end

    newparam(:role) do
        desc 'Privilege level of this user (admin, operator, user, callback, no_access). Defaults to no_access.'
        newvalues(:admin, :operator, :user, :callback, :no_access)
        defaultto(:no_access)
    end

    newparam(:callin, :boolean => true, :parent => Puppet::Parameter::Boolean) do
        desc 'Whether this user have the same rights during call-in session as during call-back session (modem-related).'
    end

    newparam(:link_auth, :boolean => true, :parent => Puppet::Parameter::Boolean) do
        desc 'Permission for link auth (modem-related).'
    end

    newparam(:ipmi_msg, :boolean => true, :parent => Puppet::Parameter::Boolean) do
        desc 'Permission to send ipmi messages (whatever they are).'
    end

    newparam(:sol, :boolean => true, :parent => Puppet::Parameter::Boolean) do
        desc 'Permission to use Serial Over LAN.'
    end

    [*(0..11), 15].each do |cid|
        feature :"lan_channel_#{cid}", "IPMI have LAN channel with ID #{cid}"

        newproperty(:"role_#{cid}", :required_features => :"lan_channel_#{cid}") do
            desc "Privilege level of this user on channel #{cid}."
            newvalues(:admin, :operator, :user, :callback, :no_access)
            defaultto { resource[:role] }
        end

        newproperty(:"callin_#{cid}", :required_features => :"lan_channel_#{cid}", :boolean => true, :parent => Puppet::Property::Boolean) do
            desc "Permission for call-in on channel #{cid}."
            defaultto { resource[:callin] }
        end

        newproperty(:"link_auth_#{cid}", :required_features => :"lan_channel_#{cid}", :boolean => true, :parent => Puppet::Property::Boolean) do
            desc "Permission for link auth on channel #{cid}."
            defaultto { resource[:link_auth] }
        end

        newproperty(:"ipmi_msg_#{cid}", :required_features => :"lan_channel_#{cid}", :boolean => true, :parent => Puppet::Property::Boolean) do
            desc "Permission to send ipmi messages on channel #{cid}."
            defaultto { resource[:ipmi_msg] }
        end

        newproperty(:"sol_#{cid}", :required_features => :"lan_channel_#{cid}", :boolean => true, :parent => Puppet::Property::Boolean) do
            desc "Permission to use Serial Over LAN on channel #{cid}."
            defaultto { resource[:sol] }
        end
    end
end

