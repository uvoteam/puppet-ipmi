
class ipmi::config (
    Stdlib::Absolutepath $file,
    Boolean              $watchdog = $ipmi::watchdog,
){
    $watchdog_real = $watchdog ? {
        true    => 'yes',
        default => 'no',
    }

    augeas { 'configure ipmi watchdog':
        context => "/files${file}",
        changes => [
            "set IPMI_WATCHDOG ${watchdog_real}",
        ],
    }
}

