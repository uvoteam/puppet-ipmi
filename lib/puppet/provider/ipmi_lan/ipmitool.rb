
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'ipmi')
require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'random_password')

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

    class <<self
        def ipmi
            IPMI
            # XXX extremely ugly...
            #@ipmi ||= IPMI.tap { |obj| obj.ipmitoolcmd = proc { |*args| ipmitoolcmd *args } }
        end
    end

    def ipmi
        self.class.ipmi
    end

    def initialize options
        super options
        @property_flush = {}
    end

    # provider stuff
    def self.instances
        ipmi.lan_channels.map do |lan|
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
                :sol_enable         => lan.sol.enabled,
                :sol_encryption     => lan.sol.force_encryption,
                :sol_authentication => lan.sol.force_authentication,
            }

            if IPMI.has_ipmi_2?
                params[:ciphers] = lan.cipher_privs.each_with_index.map { |priv, index| (priv.nil? or priv == :no_access) ? nil : index }.compact
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
                resource.remove
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
        ipmi.lan(@property_hash[:channel].to_i).tap do |lan|
            @property_flush[:auth_admin]         = resource[:"auth_admin"]
            @property_flush[:auth_operator]      = resource[:"auth_operator"]
            @property_flush[:auth_user]          = resource[:"auth_user"]
            @property_flush[:auth_callback]      = resource[:"auth_callback"]
            @property_flush[:ipsrc]              = resource[:ipsrc]
            @propetry_flush[:address]            = resource[:address]
            @property_flush[:netmask]            = resource[:netmask]
            @propetry_flush[:gateway]            = resource[:gateway]
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
        ipmi.lan(@property_hash[:channel].to_i).tap do |lan|
            @property_flush[:auth_admin]         = [ :md5 ]
            @property_flush[:auth_operator]      = [ :md5 ]
            @property_flush[:auth_user]          = [ :md5 ]
            @property_flush[:auth_callback]      = [ :md5 ]
            @property_flush[:ipsrc]              = :static
            @propetry_flush[:address]            = '0.0.0.0'
            @property_flush[:netmask]            = '0.0.0.0'
            @propetry_flush[:gateway]            = '0.0.0.0'
            @property_flush[:backup_gateway]     = '0.0.0.0'
            @property_flush[:arp_enable]         = false
            @property_flush[:snmp_community]     = HelperRandomPassword.random_password 8
            @property_flush[:sol_enable]         = false
            @property_flush[:sol_encryption]     = true
            @property_flush[:sol_authentication] = true
            @property_flush[:ciphers]            = [ 3, 8, 12 ]
        end
    end

    def default_channel
        ipmi.lan.cid
    end

    def flush
        unless @property_flush.empty?
            ipmi.lan(@property_hash[:channel].to_i).tap do |lan|
                lan.auth                     =
                    [:admin, :operator, :user, :callback].map do |role|
                        [ role, @property_flush[:"auth_#{role}"] ] if @property_flush[:"auth_#{role}"]
                    end.compact.to_h
                lan.ipsrc                    = @property_flush[:ipsrc]                      if @property_flush.has_key?(:ipsrc) and not @property_flush[:ipsrc].nil?
                lan.ipaddr                   = @property_flush[:address]                    if @property_flush.has_key?(:address) and not @property_flush[:address].nil?
                lan.netmask                  = @property_flush[:netmask]                    if @property_flush.has_key?(:netmask) and not @property_flush[:netmask].nil?
                lan.defgw_ipaddr             = @property_flush[:gateway]                    if @property_flush.has_key?(:gateway) and not @property_flush[:gateway].nil?
                lan.bakgw_ipaddr             = @property_flush[:backup_gateway]             if @property_flush.has_key?(:backup_gateway) and not @property_flush[:backup_gateway].nil?
                if @property_flush.has_key?(:arp_enable) and not @property_flush[:arp_enable].nil?
                    lan.arp_respond          = (@property_flush[:arp_enable] != :false)
                    lan.arp_generate         = (@property_flush[:arp_enable] == :advertise)
                end
                lan.snmp                     = @property_flush[:snmp_community]             if @property_flush.has_key?(:snmp_community) and not @property_flush[:snmp_community].nil?
                lan.sol.enabled              = @property_flush[:sol_enable]                 if @property_flush.has_key?(:sol_enable) and not @property_flush[:sol_enable].nil?
                lan.sol.force_encryption     = @property_flush[:sol_encryption]             if @property_flush.has_key?(:sol_encryption) and not @property_flush[:sol_encryption].nil?
                lan.sol.force_authentication = @property_flush[:sol_authentication]         if @property_flush.has_key?(:sol_authentication) and not @property_flush[:sol_authentication].nil?
                if @property_flush[:ciphers].is_a? Array
                    if IPMI.has_ipmi_2?
                        lan.cipher_privs =
                            lan.cipher_privs.each_with_index.map do |priv, index|
                                if @property_flush[:ciphers].include?(index)
                                    :admin
                                else
                                    :no_access
                                end
                            end
                    else
                        Puppet.warning("This IPMI uses specification v#{IPMI.version} and does not support settings ciphers")
                    end
                end
            end
        end
    end
end

