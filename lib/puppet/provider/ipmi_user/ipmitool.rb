
require 'set'

require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ipmi')

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
                    :name            => "#{user.name}:#{uid}@#{channel.cid}",
                    # we're forcing all parameters to be as in absent state, otherwise we consider user present
                    :ensure          => (
                        user.name      == ''         and
                        user.enabled   == false      and
                        user.privilege == :no_access and
                        user.callin    == false      and
                        user.link      == false      and
                        user.ipmi      == false      and
                        user.sol       == false
                    ) ? :absent : :present,
                    :username        => user.name,
                    :enable          => user.enabled,
                    :userid          => uid,
                    :channel         => channel.cid,
                    :role            => user.privilege,
                    :immutable       => user.fixed_name,
                    :callin          => user.callin,
                    :link_auth       => user.link,
                    :ipmi_msg        => user.ipmi,
                    :sol             => user.sol,
                    :password        => '*hidden*',
                )
            end
        end
    end

    # connect system resources to the ones, declared in Puppet
    # The idea here is to mostly manage users by name, auto-assigning
    # them UIDs.
    # FIXME: refactor this shit
    def self.prefetch resources
        insts           = instances
        present, absent = resources.values.partition { |resource| resource.should(:ensure) == :present }
        fixed, variable = present.partition { |resource| resource[:userid] }
        taken_ids       = Set.new

        # First we're placing any present resources with defined userid
        fixed.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.userid == resource[:userid] }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        end.each do |resource|
            fail("User slot with UID #{resource[:userid]} not found or already taken")
        end

        # Then we're assigning present resources with matching username
        variable.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.username == resource[:username] }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        # Then we're assigning to any truly absent resources
        end.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.userid > 2 and instance.ensure == :absent }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        # Then to 'relaxed' absent resources
        end.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.userid > 2 and instance.username == '' and not instance.enable }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        # And finally anything goes to satisfy present resource needs
        end.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.userid > 2 }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        end.each do |resource|
            fail("Unable to find free UID for resource Ipmi_user[#{name}]")
        end

        # After present resources, we assign absent resources with userid
        absent.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.userid == resource[:userid] }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        # After that - with matching name
        end.reject do |resource|
            instance = insts
                .select { |instance| instance.channel == resource[:channel] }
                .select { |instance| not taken_ids.include? "#{instance.userid}@#{instance.channel}" }
                .find   { |instance| instance.username == resource[:username] }

            unless instance.nil?
                taken_ids << "#{instance.userid}@#{instance.channel}"
                resource.provider = instance
            end
        # And finally just drop any 'absent' stragglers
        end.each do |resource|
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
            user.callin    = resource[:callin]
            user.link      = resource[:link_auth]
            user.ipmi      = resource[:ipmi_msg]
            user.password  = resource[:password]
            user.sol       = resource[:sol]
        end
    end

    def destroy
        ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).tap do |user|
            user.enabled   = false
            user.name      = ''
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
                # XXX username
                user.password  = @property_hash[:password]  if @property_hash.has_key? :password
                user.privilege = @property_hash[:role]      if @property_hash.has_key? :role
                user.enabled   = @property_hash[:enable]    if @property_hash.has_key? :enable
                user.callin    = @property_hash[:callin]    if @property_hash.has_key? :callin
                user.link      = @property_hash[:link_auth] if @property_hash.has_key? :link_auth
                user.ipmi      = @property_hash[:ipmi_msg]  if @property_hash.has_key? :ipmi_msg
                user.sol       = @property_hash[:sol]       if @property_hash.has_key? :sol
            end
        end
    end
end

