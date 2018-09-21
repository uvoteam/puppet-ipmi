
class ipmi (
  Hash[String,Any] $users       = {},
  Hash[String,Any] $lans        = {},
  Boolean          $purge_users = false,
  Boolean          $purge_lans  = false,
  Boolean          $service     = false,
  Boolean          $ipmievd     = false,
  Boolean          $watchdog    = false,
) {
    include ::ipmi::install
    include ::ipmi::config
    include ::ipmi::service::ipmi
    include ::ipmi::service::ipmievd

    create_resources('ipmi::lan',  $lans)
    create_resources('ipmi::user', $users)

    if $purge_users {
        # we cannot properly set special users 1 and 2 to be disabled
        # so we will treat them differently
        ipmi_user { '1':
            userid    => 1,
            enable    => false,
            callin    => false,
            link_auth => false,
            ipmi_msg  => false,
            role      => no_access,
            sol       => false,
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

