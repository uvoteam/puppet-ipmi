
class ipmi::service::ipmi (
    String                  $service = 'ipmi',
    Stdlib::Ensure::Service $ensure  = $ipmi::service ? {
        true    => running,
        default => stopped,
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

