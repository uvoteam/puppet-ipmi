# facts for compatibility with older version of this module.
# XXX this does not currently implement 'ipaddress_source' and 'macaddress' facts.

IPMI.lan_channels.map do |lan|
    Facter.add("ipmi#{lan.channel}_ipaddress") do
        setcode do
            lan.ipaddr
        end
    end
    Facter.add("ipmi#{lan.channel}_subnet_mask") do
        setcode do
            lan.netmask
        end
    end
    Facter.add("ipmi#{lan.channel}_gateway") do
        setcode do
            lan.defgw_ipaddr
        end
    end
end

