# This define is used as a compatibility layer with older code.
define ipmi::network (
    Ipmi::Ipaddr      $ip          = '0.0.0.0',
    Ipmi::Ipaddr      $netmask     = '255.255.255.0',
    Ipmi::Ipaddr      $gateway     = '0.0.0.0',
    Enum[dhcp,static] $type        = dhcp,
    Integer           $lan_channel = 1,
){
    ipmi::lan { "${title}":
        channel   => $lan_channel,
        ip_source => $type,
        address   => $ip,
        netmask   => $netmask,
        gateway   => $gateway,
    }
}

