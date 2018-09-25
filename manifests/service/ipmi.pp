
class ipmi::service::ipmi (
    String                  $service = 'ipmi',
    Stdlib::Ensure::Service $ensure  = $ipmi::service_ensure ? {
        undef   => $ipmi::service ? {
            true    => running,
            default => stopped,
        },
        default => $ipmi::service_ensure,
    },
    Boolean                 $enable = $ipmi::service,
) {
    service { $service:
        ensure     => $ensure,
        hasstatus  => true,
        hasrestart => true,
        enable     => $enable,
    }
}

