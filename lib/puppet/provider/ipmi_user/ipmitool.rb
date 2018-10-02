
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ipmi')

module IPMIUserResourceFilter
    def assign_resources instances
        self.reject do |resource|
            instance = instances.find { |instance| yield instance, resource }

            unless instance.nil?
                Puppet.debug "Assigning #{instance.userid} to Ipmi_user[#{resource[:name]}]"
                resource.provider = instance
                instances.delete_if { |i| i.eql? instance }
            end
        end.extend(IPMIUserResourceFilter)
    end
end

Puppet::Type.type(:ipmi_user).provide(:ipmitool) do
    commands :ipmitoolcmd => 'ipmitool'

    # XXX will this work in the absence of ipmitool?
    IPMI.lan_cids.each do |cid|
        has_feature :"lan_channel_#{cid}"
    end

    class <<self
        def ipmi
            IPMI
#            # XXX extremely ugly...
#            @ipmi ||= IPMI.tap { |obj| obj.ipmitoolcmd = proc { |*args| ipmitoolcmd *args } }
        end
    end

    def ipmi
        self.class.ipmi
    end

    def initialize options
        super options
        @property_flush = {}
    end

    def random_password
        ('a'..'z').to_a.shuffle[0,15].join
    end

    # provider stuff
    def self.instances
        ipmi.users.map do |user|
            params = {
                :name      => "#{user.name}:#{user.uid}",
                :username  => user.name,
                :enable    => user.enabled,
                :userid    => user.uid,
                :immutable => user.fixed_name,
                :password  => '*hidden*',
            }

            absent = user.name == "disabled#{user.uid}" and
                     not user.enabled

            ipmi.lan_cids.each do |cid|
                user = ipmi.users(cid).user(user.uid)
                params[:"role_#{cid}"]      = user.privilege
                params[:"callin_#{cid}"]    = user.callin
                params[:"link_auth_#{cid}"] = user.link
                params[:"ipmi_msg_#{cid}"]  = user.ipmi
                params[:"sol_#{cid}"]       = user.sol
                absent &&= (user.privilege == :no_access  and
                            not user.callin               and
                            not user.link                 and
                            not user.ipmi                 and
                            not user.sol)
            end

            params[:ensure] = absent ? :absent : :present

            new(params)
        end
    end

    # Connect system resources to the ones, declared in Puppet
    # The idea here is to mostly manage users by name, auto-assignin them UIDs.
    def self.prefetch resources
        insts           = instances
        present, absent = resources.values.partition { |resource| resource.should(:ensure) == :present }
        fixed, variable = present.partition { |resource| resource[:userid] }

        # First we're placing any present resources with defined userid.
        fixed.extend(IPMIUserResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.userid == resource[:userid] }
            .each do |resource|
                fail("User slot with UID #{resource[:userid]} required for Ipmi_user[#{resource[:name]}] not found or already taken")
            end

        # Then we're assigning present resources with matching username.
        # Then search for any absent resources, that we can reuse.
        # While at that, we try to preserve as much existing data as possible, thus three rules instead of one.
        # XXX check roles?
        variable.extend(IPMIUserResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.username == resource[:username] }
            .assign_resources(insts) { |instance, resource| instance.userid > 2 and instance.ensure == :absent }
            .assign_resources(insts) { |instance, resource| instance.userid > 2 and not instance.enable }
            .assign_resources(insts) { |instance, resource| instance.userid > 2 }
            .each do |resource|
                fail("Unable to find free UID for resource Ipmi_user[#{resource[:name]}]")
            end

        # After present resources, we assign absent resources with matching userid or username.
        # And any still unassigned resources we just delete, since there's no way to determine their positioning.
        absent.extend(IPMIUserResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.userid == resource[:userid] }
            .assign_resources(insts) { |instance, resource| instance.username == resource[:username] }
            .each do |resource|
                debug "Deleting absent resource Ipmi_user[#{resource[:name]}]"
                resource.remove
            end
    end

    # create default property accessors
    mk_resource_methods

    ( [:username, :enable, :password] + ipmi.lan_cids.flat_map do |cid|
        [:"role_#{cid}", :"callin_#{cid}", :"link_auth_#{cid}", :"ipmi_msg_#{cid}", :"sol_#{cid}"]
    end ).each do |method_name|
        define_method "#{method_name}=" do |new_value|
            @property_flush[method_name] = new_value
        end
    end

    # property methods
    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        ipmi.users.user(@property_hash[:userid]).tap do |user|
            @property_flush[:username] = resource[:username]
            @property_flush[:enable]   = true
            @property_flush[:password] = resource[:password]
            ipmi.lan_cids.each do |cid|
                @property_flush[:"role_#{cid}"]      = resource[:"role_#{cid}"]
                @property_flush[:"callin_#{cid}"]    = resource[:"callin_#{cid}"]
                @property_flush[:"link_auth_#{cid}"] = resource[:"link_auth_#{cid}"]
                @property_flush[:"ipmi_msg_#{cid}"]  = resource[:"ipmi_msg_#{cid}"]
                @property_flush[:"sol_#{cid}"]       = resource[:"sol_#{cid}"]
            end
        end
    end

    def destroy
        ipmi.users.user(@property_hash[:userid]).tap do |user|
            @property_flush[:username] = "disabled#{user.uid}"
            @property_flush[:enable]   = false
            @property_flush[:password] = random_password
            ipmi.lan_cids.each do |cid|
                @property_flush[:"role_#{cid}"]      = :no_access
                @property_flush[:"callin_#{cid}"]    = false
                @property_flush[:"link_auth_#{cid}"] = false
                @property_flush[:"ipmi_msg_#{cid}"]  = false
                @property_flush[:"sol_#{cid}"]       = false
            end
        end
    end

    def password_insync? pass
        begin
            ipmi.users.user(@property_hash[:userid]).password? pass, 20
            true
        rescue Puppet::ExecutionFailure => err
            begin
                ipmi.users.user(@property_hash[:userid]).password? pass, 16
                true
            rescue Puppet::ExecutionFailure => err
                false
            end
        end
    end

    def lan_list
        ipmi.lan_cids
    end

    def flush
        unless @property_flush.empty?
            ipmi.users.user(@property_hash[:userid]).tap do |user|
                # we're not trying to set username to the same value, since it will fail on RMM with 'conflicting name'
                user.name      = @property_flush[:username]     if @property_flush.has_key? :username and @property_flush[:username] != user.name
                user.password  = @property_flush[:password], 20 if @property_flush.has_key? :password
                # enable manipulates password, thus if it does not exist, it may fail
                user.enabled   = @property_flush[:enable]       if @property_flush.has_key? :enable
                ipmi.lan_cids.each do |cid|
                    ipmi.users(cid).user(@property_hash[:userid]).tap do |user|
                        user.privilege = @property_flush[:"role_#{cid}"]      if @property_flush.has_key? :"role_#{cid}"
                        user.callin    = @property_flush[:"callin_#{cid}"]    if @property_flush.has_key? :"callin_#{cid}"
                        user.link      = @property_flush[:"link_auth_#{cid}"] if @property_flush.has_key? :"link_auth_#{cid}"
                        user.ipmi      = @property_flush[:"ipmi_msg_#{cid}"]  if @property_flush.has_key? :"ipmi_msg_#{cid}"
                        user.sol       = @property_flush[:"sol_#{cid}"]       if @property_flush.has_key? :"sol_#{cid}"
                    end
                end
            end
        end
    end
end

