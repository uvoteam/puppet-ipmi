
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ipmi')
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'random_password')
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'coerce_boolean')

module IPMILANResourceFilter
    def assign_resources instances
        self.reject do |resource|
            instance = instances.find { |instance| yield instance, resource }

            unless instance.nil?
                Puppet.debug "Assigning #{instance.channel} to Ipmi_lan[#{resource[:name]}]"
                resource.provider = instance
                instances.delete_if { |i| i.eql? instance }
            end
        end.extend(IPMILANResourceFilter)
    end
end

Puppet::Type.type(:ipmi_lan).provide(:ipmitool) do
    commands :ipmitoolcmd => 'ipmitool'

    def initialize options
        super options
        @property_flush = {}
    end

    # provider stuff
    def self.instances
        IPMI.lan_channels.map do |lan|
            params = {
                :name               => lan.cid.to_s,
                # XXX user-style strict checking?
                :ensure             => (lan.ipaddr == '0.0.0.0') ? :absent : :present,
                :channel            => lan.cid.to_s,
                :auth_admin         => lan.auth[:admin].sort,
                :auth_operator      => lan.auth[:operator].sort,
                :auth_user          => lan.auth[:user].sort,
                :auth_callback      => lan.auth[:callback].sort,
                :ip_source          => lan.ipsrc,
                :address            => lan.ipaddr,
                :netmask            => lan.netmask,
                :gateway            => lan.defgw_ipaddr,
                :backup_gateway     => lan.bakgw_ipaddr,
                :arp_enable         => (lan.arp_respond ? (lan.arp_generate ? :advertise : :true) : :false),
                :snmp_community     => lan.snmp,
            }

            if IPMI.has_ipmi_2?
                params[:sol_enable]         = HelperCoerceBoolean.from_boolean(lan.sol.enabled)
                params[:sol_encryption]     = HelperCoerceBoolean.from_boolean(lan.sol.force_encryption)
                params[:sol_authentication] = HelperCoerceBoolean.from_boolean(lan.sol.force_authentication)
                params[:ciphers]            = lan.cipher_privs.each_with_index.map { |priv, index| (priv.nil? or priv == :no_access) ? nil : index }.compact
            end

            new(params)
        end
    end

    # connect system resources to the ones, declared in Puppet
    def self.prefetch resources
        insts           = instances
        present, absent = resources.values.partition { |resource| resource.should(:ensure) == :present }

        present.extend(IPMILANResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.channel == resource[:channel] }
            .each do |resource|
                fail("Requested LAN channel #{resource[:channel]} does not exist or is already taken")
            end

        absent.extend(IPMILANResourceFilter)
            .assign_resources(insts) { |instance, resource| instance.channel == resource[:channel] }
            .each do |resource|
                debug "Deleting absent resource Ipmi_lan[#{resource[:name]}]"
                # FIXME I've found no reliable way to remove resource from catalog at this stage.
                # So, I mark it as virtual, so puppet will not apply it. But this is fragile.
                resource.remove
                resource.virtual = true
            end
    end

    # create default property accessors
    mk_resource_methods

    [:auth_admin, :auth_operator, :auth_user, :auth_callback, :ip_source, :address, :netmask, :gateway,
     :backup_gateway, :arp_enable, :snmp_community, :sol_enable, :sol_encryption, :sol_authentication,
     :ciphers].each do |method_name|
        define_method "#{method_name}=" do |new_value|
            @property_flush[method_name] = new_value
        end
    end

    # property methods
    def exists?
        @property_hash[:ensure] == :present
    end

    def create
        IPMI.lan(@property_hash[:channel].to_i).tap do |lan|
            @property_flush[:auth_admin]         = resource[:"auth_admin"]
            @property_flush[:auth_operator]      = resource[:"auth_operator"]
            @property_flush[:auth_user]          = resource[:"auth_user"]
            @property_flush[:auth_callback]      = resource[:"auth_callback"]
            @property_flush[:ipsrc]              = resource[:ipsrc]
            @property_flush[:address]            = resource[:address]
            @property_flush[:netmask]            = resource[:netmask]
            @property_flush[:gateway]            = resource[:gateway]
            @property_flush[:backup_gateway]     = resource[:backup_gateway]
            @property_flush[:arp_enable]         = resource[:arp_enable]
            @property_flush[:snmp_community]     = resource[:snmp_community]
            @property_flush[:sol_enable]         = resource[:sol_enable]
            @property_flush[:sol_encryption]     = resource[:sol_encryption]
            @property_flush[:sol_authentication] = resource[:sol_authentication]
            @property_flush[:ciphers]            = resource[:ciphers]
        end
    end

    def destroy
        IPMI.lan(@property_hash[:channel].to_i).tap do |lan|
            @property_flush[:auth_admin]         = [ :md5 ]
            @property_flush[:auth_operator]      = [ :md5 ]
            @property_flush[:auth_user]          = [ :md5 ]
            @property_flush[:auth_callback]      = [ :md5 ]
            @property_flush[:ipsrc]              = :static
            @property_flush[:address]            = '0.0.0.0'
            @property_flush[:netmask]            = '0.0.0.0'
            @property_flush[:gateway]            = '0.0.0.0'
            @property_flush[:backup_gateway]     = '0.0.0.0'
            @property_flush[:arp_enable]         = :false
            @property_flush[:snmp_community]     = HelperRandomPassword.random_password 8
            @property_flush[:sol_enable]         = :false
            @property_flush[:sol_encryption]     = :true
            @property_flush[:sol_authentication] = :true
            @property_flush[:ciphers]            = [ 3, 8, 12 ]
        end
    end

    def default_channel
        IPMI.lan.cid
    end

    def flush
        unless @property_flush.empty?
            IPMI.lan(@property_hash[:channel].to_i).tap do |lan|
                lan.auth                     =
                    [:admin, :operator, :user, :callback].map do |role|
                        [ role, @property_flush[:"auth_#{role}"] ] if not @property_flush[:"auth_#{role}"].nil?
                    end.compact.to_h
                lan.ipsrc                    = @property_flush[:ipsrc]                                                  if not @property_flush[:ipsrc].nil?
                lan.ipaddr                   = @property_flush[:address]                                                if not @property_flush[:address].nil?
                lan.netmask                  = @property_flush[:netmask]                                                if not @property_flush[:netmask].nil?
                lan.defgw_ipaddr             = @property_flush[:gateway]                                                if not @property_flush[:gateway].nil?
                lan.bakgw_ipaddr             = @property_flush[:backup_gateway]                                         if not @property_flush[:backup_gateway].nil?
                if not @property_flush[:arp_enable].nil?
                    lan.arp_respond          = (@property_flush[:arp_enable] != :false)
                    lan.arp_generate         = (@property_flush[:arp_enable] == :advertise)
                end
                lan.snmp                     = @property_flush[:snmp_community]                                         if not @property_flush[:snmp_community].nil?
                if IPMI.has_ipmi_2?
                    lan.sol.enabled              = HelperCoerceBoolean.to_boolean(@property_flush[:sol_enable])         if not @property_flush[:sol_enable].nil?
                    lan.sol.force_encryption     = HelperCoerceBoolean.to_boolean(@property_flush[:sol_encryption])     if not @property_flush[:sol_encryption].nil?
                    lan.sol.force_authentication = HelperCoerceBoolean.to_boolean(@property_flush[:sol_authentication]) if not @property_flush[:sol_authentication].nil?
                    if @property_flush[:ciphers].is_a? Array
                        lan.cipher_privs =
                            lan.cipher_privs.each_with_index.map do |priv, index|
                                if @property_flush[:ciphers].include?(index)
                                    :admin
                                else
                                    :no_access
                                end
                            end
                    end
                elsif [:sol_enable, :sol_encryption, :sol_authentication, :ciphers].find { |option| not @property_flush[option].nil? }
                    Puppet.warning("This IPMI uses specification v#{IPMI.version} and does not support settings ciphers or SOL")
                end
            end
        end
    end
end

