
define ipmi::user (
    Optional[String]     $username  = undef,
    Optional[Integer]    $userid    = undef,
    Optional[String]     $password  = undef,
    Optional[Boolean]    $enable    = lookup(["ipmi::user::${username}::enable", "ipmi::user::${userid}::enable", 'ipmi::user::enable'],
                                             { default_value => true }),
    Optional[Ipmi::Role] $role      = lookup(["ipmi::user::${username}::role", "ipmi::user::${userid}::role", 'ipmi::user::role'],
                                             { default_value => undef }),
    Optional[Boolean]    $callin    = lookup(["ipmi::user::${username}::callin", "ipmi::user::${userid}::callin", 'ipmi::user::callin'],
                                             { default_value => false }),
    Optional[Boolean]    $link_auth = lookup(["ipmi::user::${username}::link_auth", "ipmi::user::${userid}::link_auth", 'ipmi::user::link_auth'],
                                             { default_value => false }),
    Optional[Boolean]    $ipmi_msg  = lookup(["ipmi::user::${username}::ipmi_msg", "ipmi::user::${userid}::ipmi_msg", 'ipmi::user::ipmi_msg'],
                                             { default_value => false }),
    Optional[Boolean]    $sol       = lookup(["ipmi::user::${username}::sol", "ipmi::user::${userid}::sol", 'ipmi::user::sol'],
                                             { default_value => false }),

    # Compatibility with previous code
    Optional[Integer] $user_id = $userid,
    Optional[Integer] $priv    = undef,
    Optional[String]  $user    = undef,
) {
    # Compatibility parameter mapping
    $user_name = $username ? {
        String[1] => $username,
        default   => $user,
    }

    $user_role = $role ? {
        undef => $priv ? {
            undef => $enable ? {
                true  => admin,
                false => no_access,
            },
            1 => callback,
            2 => user,
            3 => operator,
            4 => admin,
        },
        default => $role,
    }

    # Set parameters on user resource
    ipmi_user { $title:
        username  => $user_name,
        userid    => $user_id,
        enable    => $enable,
        password  => $password,
        role      => $user_role,
        callin    => $callin,
        link_auth => $link_auth,
        ipmi_msg  => $ipmi_msg,
        sol       => $sol,
    }
}

