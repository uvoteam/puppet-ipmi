
define ipmi::lan (
    Optional[Integer]     $channel            = undef,
    Ipmi::Ipsrc           $ip_source          = static,
    Ipmi::Ipaddr          $address,
    Ipmi::Ipaddr          $netmask,
    Ipmi::Ipaddr          $gateway,
    Ipmi::Ipaddr          $backup_gateway     = '0.0.0.0',
    Ipmi::Arp             $arp                = true,
    # just a random string to override the default value
    Optional[String]      $snmp               = 'WabNuojV',
    Array[Ipmi::Authtype] $auth_admin         = [ md5 ],
    Array[Ipmi::Authtype] $auth_operator      = [ md5 ],
    Array[Ipmi::Authtype] $auth_user          = [ md5 ],
    Array[Ipmi::Authtype] $auth_callback      = [ md5 ],
    # this needs overrides on per-vendor basis, so, we lookup these parameters.
    Optional[Boolean]     $sol                = lookup(["ipmi::lan::${title}::sol", 'ipmi::lan::sol'],
                                                       { default_value => false }),
    Optional[Boolean]     $sol_encryption     = lookup(["ipmi::lan::${title}::sol_encryption", 'ipmi::lan::sol_encryption'],
                                                       { default_value => true }),
    Optional[Boolean]     $sol_authentication = lookup(["ipmi::lan::${title}::sol_authentication", 'ipmi::lan::sol_authentication'],
                                                       { default_value => true }),
    Array[Integer]        $ciphers            = lookup(["ipmi::lan::${title}::ciphers", 'ipmi::lan::ciphers'],
                                                       { default_value => [ 3, 8, 12 ] }),
) {
    ipmi_lan { $title:
        channel            => $channel,
        auth_admin         => $auth_admin,
        auth_operator      => $auth_operator,
        auth_user          => $auth_user,
        auth_callback      => $auth_callback,
        ip_source          => $ip_source,
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

