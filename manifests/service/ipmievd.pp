
class ipmi::service::ipmievd (
    Stdlib::Ensure::Service $ensure = $ipmi::ipmievd ? {
        true    => running,
        default => stopped,
    },
    Boolean                 $enable = $ipmi::ipmievd,
) {
    service{ 'ipmievd':
        ensure     => $ensure,
        hasstatus  => true,
        hasrestart => true,
        enable     => $enable,
    }
}

