
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
                    # XXX
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
    # FIXME: we can detect resources, that should be absent and in the
    # case of UID shortage use their slots for present resources.
    def self.prefetch resources
        insts     = instances
        taken_ids = Set.new resources.map { |name, resource| resource[:userid] }.compact
        resources.each do |name, resource|
            available_instances = insts
                .select do |instance|
                    instance.channel == (resource[:channel] ? resource[:channel] : IPMI.lan.cid)
                end
                .select do |instance|
                    resource[:userid] or not taken_ids.include? instance.userid
                end

            instance =
                if resource[:userid]
                    available_instances.find { |instance| instance.userid == resource[:userid] } \
                    or
                    fail("User slot with UID #{resource[:userid]} not found")
                else
                    available_instances.find { |instance| instance.name == name } \
                    or
                    available_instances.find { |instance| instance.userid > 2 and instance.ensure == :absent } \
                    or
                    fail("Unable to find free UID for resource Ipmi_user[#{name}]")
                end

            taken_ids << instance.userid
            resource.provider = instance
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
            user.name      = resource[:name]
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

    def flush
        unless @property_hash.empty?
            ipmi.users(@property_hash[:channel]).user(@property_hash[:userid]).tap do |user|
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

