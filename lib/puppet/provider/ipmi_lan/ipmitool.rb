
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
        ipmi.lan_channels.map do |lan|
            new(
                # XXX user-style strict checking?
                :ensure             => lan.address == '0.0.0.0' ? :absent : :present,
                :channel            => lan.cid.to_s,
                :auth_admin         => lan.auth[:admin].sort,
                :auth_operator      => lan.auth[:operator].sort,
                :auth_user          => lan.auth[:user].sort,
                :auth_callabck      => lan.auth[:callback].sort,
                :address            => lan.ipaddr,
                :netmask            => lan.netmask,
                :gateway            => lan.defgw_ipaddr,
                :backup_gateway     => lan.bakgw_ipaddr,
                :arp_enable         => (lan.arp_respond ? (lan.arp_generate ? :advertise : :true) : :false),
                :snmp_community     => lan.snmp,
                :sol_enable         => lan.sol.enabled,
                :sol_encryption     => lan.sol.force_encryption,
                :sol_authentication => lan.sol.force_authentication,
                :ciphers            => lan.cipher_privs.each_with_index.map { |priv, index| (priv.nil? or priv == :no_access) ? nil : index }.compact,
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
        ipmi.lan(@property_hash[:channel]).tap do |lan|
            lan.auth                     = {
                :admin    => [ :md5 ],
                :operator => [ :md5 ],
                :user     => [ :md5 ],
                :callback => [ :md5 ],
            }
            lan.ipaddr                   = '0.0.0.0'
            lan.netmask                  = '0.0.0.0'
            lan.defgw_ipaddr             = '0.0.0.0'
            lan.bakgw_ipaddr             = '0.0.0.0'
            lan.arp_enable               = false
            lan.arp_gratituous           = false
            lan.snmp                     = 'PiecKek9Ob'
            lan.sol.enabled              = false
            lan.sol.force_encryption     = true
            lan.sol.force_authentication = true
            lan.cipher_privs             =
                lan.cipher_privs.each_with_index.map do |priv, index|
                    if [3, 8, 12].include? index
                        :admin
                    else
                        :no_access
                    end
                end
        end
    end

    def flush
        unless @property_hash.empty?
            ipmi.lan(@property_hash[:channel]).tap do |lan|
                lan.auth                     =
                    [:admin, :operator, :user, :callback].map do |role|
                        [ role, @property_hash[:"auth_#{role}"] ] if @property_hash[:"auth_#{role}"]
                    end.compact.to_h
                lan.ipaddr                   = @property_hash[:address]                    if @property_hash.has_key? :address
                lan.netmask                  = @property_hash[:netmask]                    if @property_hash.has_key? :netmask
                lan.defgw_ipaddr             = @property_hash[:gateway]                    if @property_hash.has_key? :gateway
                lan.bakgw_ipaddr             = @property_hash[:backup_gateway]             if @property_hash.has_key? :backup_gateway
                lan.arp_enable               = (@property_hash[:arp_enable] != :false)     if @property_hash.has_key? :arp_enable
                lan.arp_gratituous           = (@property_hash[:arp_enable] == :advertise) if @property_hash.has_key? :arp_enable
                lan.snmp                     = @property_hash[:snmp_community]             if @property_hash.has_key? :snmp_community
                lan.sol.enabled              = @property_hash[:sol_enable]                 if @property_hash.has_key? :sol_enable
                lan.sol.force_encryption     = @property_hash[:sol_encryption]             if @property_hash.has_key? :sol_encryption
                lan.sol.force_authentication = @property_hash[:sol_authentication]         if @property_hash.has_key? :sol_authentication
                if @property_hash.has_key? :ciphers
                    lan.cipher_privs =
                        lan.cipher_privs.each_with_index.map do |priv, index|
                            if @property_hash[:ciphers].include?(index)
                                :admin
                            else
                                :no_access
                            end
                        end
                end
            end
        end
    end
end

