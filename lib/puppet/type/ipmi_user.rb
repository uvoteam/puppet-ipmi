
require 'puppet/property/boolean'

Puppet::Type.newtype(:ipmi_user) do
    @doc = <<-'DOC'
    This represents ipmi user
    DOC

    ensurable

    # this is needed for resource discovery to work (resources can have empty username)
    # and to have convenient access to the user name parameter value
    newparam(:name) do
        desc 'Dummy parameter to hold resource title. Do not use.'

        defaultto do
            resource.title
        end
    end

    newparam(:username, :namevar => true) do
        desc 'Name for this user (namevar)'
    end

    newparam(:userid, :namevar => true) do
        desc 'User ID (integer, namevar). When creating user, will be automatically assigned first free one, if not specified.'
        munge do |value|
            value.to_i
        end
    end

    newparam(:channel, :namevar => true) do
        desc 'LAN Channel ID (integer, namevar). If not specified, first available LAN channel will be used.'
        munge do |value|
            value.to_i
        end

        defaultto do
            resource.provider.default_channel
        end
    end

    def self.title_patterns
        [
            [ /^(\S*):(\d+)@(\d+)$/,  [ [ :username ], [ :userid ], [ :channel ] ] ],
            [ /^(\S*):(\d+)$/,        [ [ :username ], [ :userid ] ] ],
            [ /^(\d+)@(\d+)$/,        [ [ :userid ], [ :channel ] ] ],
            [ /^(\d+)$/,              [ [ :userid ] ] ],
            [ /^(\S*)@(\d+)$/,        [ [ :username ], [ :channel ] ] ],
            [ /^(\S*)$/,              [ [ :username ] ] ],
        ]
    end

    newproperty(:enable, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'This defines if user should be enabled or disabled.'
    end

    newproperty(:role) do
        desc 'Privilege level of this user (admin, operator, user, callback, no_access). Defaults to no_access.'
        newvalues(:admin, :operator, :user, :callback, :no_access)
        defaultto(:no_access)
    end

    newproperty(:immutable, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'This read-only property indicates, if user name is marked as "fixed".'
        validate do |value|
            raise ArgumentError, 'IPMI does not allow to change username immutability'
        end
    end

    newproperty(:callin, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Whether this user have the same rights during call-in session as during call-back session (modem-related).'
    end

    newproperty(:link_auth, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Permission for link auth (modem-related).'
    end

    newproperty(:ipmi_msg, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Permission to send ipmi messages (whatever they are).'
    end

    newproperty(:sol, :boolean => true, :parent => Puppet::Property::Boolean) do
        desc 'Permission to use Serial Over LAN.'
    end

    newproperty(:password) do
        desc 'Password for ipmi user'
        def insync? is
            provider.password_insync? should
        end
    end
end

