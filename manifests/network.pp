# This define is used as a compatibility layer with older code.
define ipmi::network (
    Ipmi::Ipaddr      $ip          = '0.0.0.0',
    Ipmi::Ipaddr      $netmask     = '255.255.255.0',
    Ipmi::Ipaddr      $gateway     = '0.0.0.0',
    # XXX atm unsupported!
    Enum[dhcp,static] $type        = dhcp,
    Integer           $lan_channel = 1,
){
    $ensure = $ip ? {
        '0.0.0.0' => absent,
        default   => present,
    }

    ipmi::lan { "${title}":
        ensure  => $ensure,
        channel => $lan_channel,
        address => $ip,
        netmask => $netmask,
        gateway => $gateway,
    }
}

