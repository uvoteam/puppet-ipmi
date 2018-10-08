# facts for compatibility with older version of this module.
# XXX this does not currently implement 'macaddress' fact.
require 'facter'

if Facter::Core::Execution.which('ipmitool')
    require File.join(File.dirname(__FILE__), '..', 'puppet_x', 'ipmi')

    if IPMI.present?
        IPMI.lan_channels.map do |lan|
            Facter.add("ipmi#{lan.cid}_ipaddress_source") do
                setcode do
                    lan.ipsrc
                end
            end
            Facter.add("ipmi#{lan.cid}_ipaddress") do
                setcode do
                    lan.ipaddr
                end
            end
            Facter.add("ipmi#{lan.cid}_subnet_mask") do
                setcode do
                    lan.netmask
                end
            end
            Facter.add("ipmi#{lan.cid}_gateway") do
                setcode do
                    lan.defgw_ipaddr
                end
            end
        end
    else
        Puppet.debug('Unable to detect IPMI presence, not collecting facts')
    end
end

