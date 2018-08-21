
Puppet::Type.newtype(:ipmi_user) do
    @doc = <<-'DOC'
    This represents ipmi user
    DOC

    ensurable

    newparam(:name, :namevar => true) do
        desc 'Name for this user (namevar)'
    end

    newparam(:userid, :namevar => true) do
        desc 'User ID (integer, namevar). When creating user, will be automatically assigned first free one, if not specified.'
    end

    def self.title_patterns
        [
            [ /^(\S+):(\d+)$/,  [ [ :name, :userid ] ] ],
            [ /^(\d+)$/,        [ [ :userid ] ] ],
            [ /^(\S+)$/,        [ [ :name ] ] ],
        ]
    end

    newproperty(:role) do
        desc 'Privilege level of this user (admin, operator, user, callback, no_access). Defaults to no_access.'
        newvalues(:admin, :operator, :user, :callback, :no_access)
        defaultto(:no_access)
    end

    newproperty(:immutable) do
        desc 'This read-only property indicates, if user name is marked as "fixed".'
        validate do |value|
            raise ArgumentError, 'IPMI does not allow to change username immutability'
        end
    end

    newproperty(:callin) do
        desc 'Whether this user have the same rights during call-in session as during call-back session (modem related).'
    end

    newproperty(:link_auth) do
        desc 'Permission for link auth (modem related).'
    end

    newproperty(:ipmi_msg) do
        desc 'Permission to send ipmi messages (whatever they are).'
    end

    newproperty(:password) do
        desc 'Password for ipmi user'
        def insync? is
            provider.password_insync? should
        end
    end

    newparam(:password_length) do
        desc 'Password length'
        newvalues(16, 20)
        defaultto(16)
    end
end

