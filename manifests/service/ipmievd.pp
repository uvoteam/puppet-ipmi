# == Class: ipmi::service::ipmievd
#
# This class should be considered private.
#
class ipmi::service::ipmievd (
  Enum[running,stopped] $ensure = running,
  Boolean               $enable = true,
) {
  service{ 'ipmievd':
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    enable     => $enable,
  }
}
