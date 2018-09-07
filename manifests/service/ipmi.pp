
class ipmi::service::ipmi (
    String                  $name,
    Stdlib::Ensure::Service $ensure = $ipmi::service ? {
        true    => running,
        default => stopped,
    },
    Boolean                 $enable = $ipmi::service,
) {
    service{ $name:
        ensure     => $ensure,
        hasstatus  => true,
        hasrestart => true,
        enable     => $enable,
    }
}

