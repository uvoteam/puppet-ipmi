
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
      (1..ipmi.users.maximum_users).map do |uid|
          user = ipmi.users.user(uid)
          new(
              :ensure          => (user.name.empty? and not user.enabled) ? :absent : :present,
              :name            => user.name,
              :userid          => uid,
              :role            => user.privilege,
              :immutable       => user.fixed_name,
              :callin          => user.callin,
              :link_auth       => user.link,
              :ipmi_msg        => user.ipmi,
              # XXX
              :password        => '*hidden*',
              # XXX
              :password_length => 16,
          )
      end
    end

    # connect system resources to the ones, declared in Puppet
    # The idea here is to mostly manage users by name, auto-assigning
    # them UIDs.
    # FIXME: we can detect resources, that should be absent and in the
    # case of UID shortage use their slots for present resources.
    def self.prefetch resources
        insts = instances
        taken_ids = []
        resources.each do |name, resource|
            instance = insts.find { |inst| inst.name. == name }
            instance ||= insts.find { |inst| inst.userid > 2 and inst.ensure == :absent and not taken_ids.include? inst.userid }
            if not instance
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
        ipmi.users.user(@property_hash[:userid]).tap do |user|
            user.name      = resource[:name]
            user.enabled   = true
            user.privilege = resource[:role]
            user.callin    = resource[:callin]
            user.link      = resource[:link_auth]
            user.ipmi      = resource[:ipmi_msg]
            user.password  = resource[:password]
            # common settings
            user.sol       = false
        end
    end

    def destroy
        ipmi.users.user(@property_hash[:userid]).tap do |user|
            user.name      = ''
            user.enabled   = false
            user.privilege = :no_access
            user.callin    = false
            user.link      = false
            user.ipmi      = false
            user.sol       = false
        end
    end

    def password
      '*hidden*'
    end

    def password_insync? pass, length = 16
      begin
        ipmi.users.user(@property_hash[:userid]).password? pass, length
        true
      rescue Puppet::ExecutionFailure => err
        false
      end
    end

    def password= new_pass, length = 16
        IPMI.users.user(@property_hash[:userid]).password = new_pass
    end

    def callin= value
        ipmi.users.user(@property_hash[:userid]).callin = value
    end

    def link_auth= value
        ipmi.users.user(@property_hash[:userid]).link = value
    end

    def ipmi_msg= value
        ipmi.users.user(@property_hash[:userid]).ipmi = value
    end

    def role= value
        ipmi.users.user(@property_hash[:userid]).privilege = value
    end
end

