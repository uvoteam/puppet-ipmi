
class ipmi::service::ipmievd (
    Stdlib::Ensure::Service $ensure = $ipmi::ipmievd_service_ensure ? {
        undef   => $ipmi::ipmievd ? {
            true    => running,
            default => stopped,
        },
        default => $ipmi::ipmievd_service_ensure,
    },
    Boolean                 $enable = $ipmi::ipmievd,
) {
    service { 'ipmievd':
        ensure     => $ensure,
        hasstatus  => true,
        hasrestart => true,
        enable     => $enable,
    }
}

