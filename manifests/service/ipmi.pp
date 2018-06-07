# == Class: ipmi::service::ipmi
#
# This class should be considered private.
#
class ipmi::service::ipmi (
  Enum[runnig,stopped] $ensure = running,
  Boolean              $enable = true,
  String               $ipmi_service_name = 'ipmi',
) {
  service{ $ipmi_service_name:
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    enable     => $enable,
  }
}
