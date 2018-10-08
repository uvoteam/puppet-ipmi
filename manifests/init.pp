
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
        # We cannot properly set special users 1 and 2 to be disabled, so we define them here.
        # User parameters may vary on vendor and are taken from hiera.
        ipmi::user { '1':
            userid => 1,
        }

        ipmi::user { '2':
            userid => 2,
        }

        if ($::facts['boardmanufacturer'] == 'Dell Inc.' and $::facts['ipmi_version'] == '2.0') {
            # Some versions of iDRAC's have broken UID 16, that could not be assigned a password.
            # Here name 'broken16' is used for this user to not be detected as 'absent'.
            # The only instance of iDRAC's that I have on hand that have only 10 UIDs is the one
            # with IPMIv1.5, thus the exception.
            ipmi::user { 'broken16':
                userid => 16,
            }
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

