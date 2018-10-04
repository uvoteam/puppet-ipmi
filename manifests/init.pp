
class ipmi (
  Hash[String,Any] $users       = {},
  Hash[String,Any] $lans        = {},
  Boolean          $purge_users = false,
  Boolean          $purge_lans  = false,
  Boolean          $service     = false,
  Boolean          $ipmievd     = false,
  Boolean          $watchdog    = false,

  # Compatibility with older code
  Hash[String,Any]                  $networks               = {},
  # XXX unsupported!
  Hash[String,Any]                  $snmps                  = {},
  Optional[Stdlib::Ensure::Service] $service_ensure         = undef,
  Optional[Stdlib::Ensure::Service] $ipmievd_service_ensure = undef,
) {
    include ::ipmi::install
    include ::ipmi::config
    include ::ipmi::service::ipmi
    include ::ipmi::service::ipmievd

    create_resources('ipmi::lan',  $lans)
    create_resources('ipmi::user', $users)
    # compatibility wrapper
    create_resources('ipmi::network', $networks)

    if $purge_users {
        # we cannot properly set special users 1 and 2 to be disabled
        # so we will treat them differently
        ipmi_user { '1':
            userid    => 1,
            enable    => false,
            callin    => lookup(['ipmi::user::1::callin', 'ipmi::user::callin'], { default_value => false }),
            link_auth => false,
            ipmi_msg  => false,
            role      => no_access,
            sol       => lookup(['ipmi::user::1::sol', 'ipmi::user::sol'], { default_value => false }),
        }

        ipmi_user { '2':
            userid    => 2,
            enable    => false,
            sol       => false,
        }

        resources { 'ipmi_user':
            purge => true,
        }
    }

    if $purge_lans {
        resources { 'ipmi_lan':
            purge => true,
        }
    }

    Class['ipmi::install'] -> [ Class['ipmi::config'], Class['ipmi::service::ipmi'], Class['ipmi::service::ipmievd'] ]
    Class['ipmi::config'] ~> Class['ipmi::service::ipmi']
}

