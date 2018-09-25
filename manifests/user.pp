
define ipmi::user (
    Optional[String]     $username  = undef,
    Optional[Integer]    $userid    = undef,
    Boolean              $enable    = true,
    Optional[String]     $password  = undef,
    Optional[Ipmi::Role] $role      = undef,
    Boolean              $callin    = false,
    Boolean              $link_auth = true,
    Boolean              $ipmi_msg  = false,
    Boolean              $sol       = false,

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

