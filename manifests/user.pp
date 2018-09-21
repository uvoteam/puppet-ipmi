
define ipmi::user (
    Optional[String]  $username  = undef,
    Optional[Integer] $user_id   = undef,
    Boolean           $enable    = true,
    Optional[String]  $password  = undef,
    Ipmi::Role        $role      = $enable ? {
        true  => admin,
        false => no_access,
    },
    Boolean           $callin    = false,
    Boolean           $link_auth = true,
    Boolean           $ipmi_msg  = false,
    Boolean           $sol       = false,
) {
    ipmi_user { $title:
        username  => $username,
        userid    => $user_id,
        enable    => $enable,
        password  => $password,
        role      => $role,
        callin    => $callin,
        link_auth => $link_auth,
        ipmi_msg  => $ipmi_msg,
        sol       => $sol,
    }
}

