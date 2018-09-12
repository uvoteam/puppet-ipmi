
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ipmi')

module IPMIResourceFilter
    def assign_resources instances
        self.reject do |resource|
            instance = instances
                .select { |instance| instance.channel == resource[:channel] }
                .find   { |instance| yield instance, resource }

            unless instance.nil?
                Puppet.debug "Assigning #{instance.userid}@#{instance.channel} to Ipmi_user[#{resource[:name]}]"
                resource.provider = instance
                instances.delete_if { |i| i.eql? instance }
            end
        end.extend(IPMIResourceFilter)
    end
end

Puppet::Type.type(:ipmi_user).provide(:ipmitool) do
    commands :ipmitoolcmd => 'ipmitool'

    class <<self
        def ipmi
            # XXX extremely ugly...
            @ipmi ||= IPMI.tap { |obj| obj.ipmitoolcmd = proc { |*args| ipmitoolcmd *args } }
        end
    end

    def ipmi
        self.class.ipmi
    end

    # provider stuff
    def self.instances
        ipmi.lan_channels.flat_map do |channel|
            (1..ipmi.users(channel.cid).maximum_users).map do |uid|
                user = ipmi.users(channel.cid).user(uid)
                new(
                    :name      => "#{user.name}:#{uid}@#{channel.cid}",
                    # we're forcing all parameters to be as in absent state, otherwise we consider user present
                    :ensure    => (
                        user.name == "disabled#{uid}" and
                        not user.enabled              and
                        user.privilege == :no_access  and
                        not user.callin               and
                        not user.link                 and
                        not user.ipmi                 and
                        not user.sol
                    ) ? :absent : :present,
                    :username  => user.name,
                    :enable    => user.enabled,
                    :userid    => uid,
                    :channel   => channel.cid,
                    :role      => user.privilege,
                    :immutable => user.fixed_name,
                    :callin    => user.callin,
                    :link_auth => user.link,
                    :ipmi_msg  => user.ipmi,
                    :sol       => user.sol,
                    :password  => '*hidden*',
                )
            end
        end
    end

    # Connect system resources to the ones, declared in Puppet
    # The idea here is to mostly manage users by name, auto-assignin them UIDs.
    def self.prefetch resources
        insts           = instances
        present, absent = resources.values.partition { |resource| resource.should(:ensure) == :present }
        fixed, variable = present.partition { |resource| resource[:userid] }

        # First we're placing any present resources with defined userid.
        fixed.extend(IPMIResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.userid == resource[:userid] }
            .each do |resource|
                fail("User slot with UID #{resource[:userid]} required for Ipmi_user[#{resource[:name]}] not found or already taken")
            end

        # Then we're assigning present resources with matching username.
        # Then search for any absent resources, that we can reuse.
        # While at that, we try to preserve as much existing data as possible, thus three rules instead of one.
        variable.extend(IPMIResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.username == resource[:username] }
            .assign_resources(insts) { |instance, resource| instance.userid > 2 and instance.ensure == :absent }
            .assign_resources(insts) { |instance, resource| instance.userid > 2 and instance.role == :no_access and not instance.enable }
            .assign_resources(insts) { |instance, resource| instance.userid > 2 }
            .each do |resource|
                fail("Unable to find free UID for resource Ipmi_user[#{resource[:name]}]")
            end

        # After present resources, we assign absent resources with matching userid or username.
        # And any still unassigned resources we just delete, since there's no way to determine their positioning.
        absent.extend(IPMIResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.userid == resource[:userid] }
            .assign_resources(insts) { |instance, resource| instance.username == resource[:username] }
            .each do |resource|
                debug "Deleting absent resource Ipmi_user[#{resource[:name]}]"
                resource.remove
            end
    end

    # create default property accessors
    mk_resource_methods

    # property methods
    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).tap do |user|
            user.name      = resource[:username]
            user.enabled   = true
            user.privilege = resource[:role]
            user.password  = resource[:password]
            user.callin    = resource[:callin]
            user.link      = resource[:link_auth]
            user.ipmi      = resource[:ipmi_msg]
            user.sol       = resource[:sol]
        end
    end

    def destroy
        ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).tap do |user|
            user.name      = "disabled#{user.uid}"
            user.enabled   = false
            user.privilege = :no_access
            user.callin    = false
            user.link      = false
            user.ipmi      = false
            user.sol       = false
        end
    end

    def password_insync? pass
        begin
            ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).password? pass, 20
            true
        rescue Puppet::ExecutionFailure => err
            begin
                ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).password? pass, 16
                true
            rescue Puppet::ExecutionFailure => err
                false
            end
        end
    end

    def default_channel
        ipmi.lan.cid
    end

    def flush
        unless @property_hash.empty?
            ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).tap do |user|
                user.name      = @property_hash[:username]     if @property_hash.has_key? :username
                user.enabled   = @property_hash[:enable]       if @property_hash.has_key? :enable
                user.privilege = @property_hash[:role]         if @property_hash.has_key? :role
                user.password  = @property_hash[:password], 20 if @property_hash.has_key? :password
                user.callin    = @property_hash[:callin]       if @property_hash.has_key? :callin
                user.link      = @property_hash[:link_auth]    if @property_hash.has_key? :link_auth
                user.ipmi      = @property_hash[:ipmi_msg]     if @property_hash.has_key? :ipmi_msg
                user.sol       = @property_hash[:sol]          if @property_hash.has_key? :sol
            end
        end
    end
end

