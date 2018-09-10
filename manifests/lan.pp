
define ipmi::lan (
    Optional[Integer]     $channel            = undef,
    Ipmi::Ipaddr          $address,
    Ipmi::Ipaddr          $netmask,
    Ipmi::Ipaddr          $gateway,
    Ipmi::Ipaddr          $backup_gateway     = '0.0.0.0',
    Ipmi::Arp             $arp                = true,
    Optional[String]      $snmp               = undef,
    Boolean               $sol                = false,
    Boolean               $sol_encryption     = true,
    Boolean               $sol_authentication = true,
    Array[Integer]        $ciphers            = [3, 8, 12],
    Array[Ipmi::Authtype] $auth_admin         = [ md5 ],
    Array[Ipmi::Authtype] $auth_operator      = [ md5 ],
    Array[Ipmi::Authtype] $auth_user          = [ md5 ],
    Array[Ipmi::Authtype] $auth_callback      = [ md5 ],
) {
    ipmi_lan { $title:
        channel            => $channel,
        auth_admin         => $auth_admin,
        auth_operator      => $auth_operator,
        auth_user          => $auth_user,
        auth_callback      => $auth_callback,
        address            => $address,
        netmask            => $netmask,
        gateway            => $gateway,
        backup_gateway     => $backup_gateway,
        arp_enable         => $arp,
        snmp_community     => $snmp,
        sol_enable         => $sol,
        sol_encryption     => $sol_encryption,
        sol_authentication => $sol_authentication,
        ciphers            => $ciphers,
    }
}

