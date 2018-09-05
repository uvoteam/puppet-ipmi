
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ipmi')

Puppet::Type.type(:ipmi_lan).provide(:ipmitool) do
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
        ipmi.lan_channels.map do |channel|
            new(
                # XXX user-style strict checking?
                :ensure             => channel.address == '0.0.0.0' ? :absent : :present,
                :channel            => channel.cid.to_s,
                :auth_admin         => channel.auth[:admin].sort,
                :auth_operator      => channel.auth[:operator].sort,
                :auth_user          => channel.auth[:user].sort,
                :auth_callabck      => channel.auth[:callback].sort,
                :address            => channel.ipaddr,
                :netmask            => channel.netmask,
                :gateway            => channel.defgw_ipaddr,
                :backup_gateway     => channel.bakgw_ipaddr,
                :arp_enable         => (channel.arp_respond ? (channel.arp_generate ? :advertise : :true) : :false),
                :snmp_community     => channel.snmp,
                :sol_enable         => channel.sol.enabled,
                :sol_encryption     => channel.sol.force_encryption,
                :sol_authentication => channel.sol.force_authentication,
                :ciphers            => channel.cipher_privs.each_with_index.map { |priv, index| (priv.nil? or priv == :no_access) ? nil : index }.compact,
            )
        end
    end

    # connect system resources to the ones, declared in Puppet
    def self.prefetch resources
        instances.each do |instance|
            if resource = resources[instance.name]
                resource.provider = instance
            end
        end
    end

    # create default property accessors
    mk_resource_methods

    # property methods
    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        ipmi.lan(@property_hash[:channel]).tap do |lan|
            lan.auth                     =
                [:admin, :operator, :user, :callback].map do |role|
                    [ role, resource[:"auth_#{role}"] ] if resource[:"auth_#{role}"]
                end.compact.to_h
            lan.ipaddr                   = resource[:address]
            lan.netmask                  = resource[:netmask]
            lan.defgw_ipaddr             = resource[:gateway]
            lan.bakgw_ipaddr             = resource[:backup_gateway]
            lan.arp_enable               = resource[:arp_enable] != :false
            lan.arp_gratituous           = resource[:arp_enable] == :advertise
            lan.snmp                     = resource[:snmp_community]
            lan.sol.enabled              = resource[:sol_enable]
            lan.sol.force_encryption     = resource[:sol_encryption]
            lan.sol.force_authentication = resource[:sol_authentication]
            lan.cipher_privs             =
                lan.cipher_privs.each_with_index.map do |priv, index|
                    unless priv.nil?
                        if resource[:ciphers].include?(index)
                            :admin
                        else
                            :no_access
                        end
                    end
                end
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

