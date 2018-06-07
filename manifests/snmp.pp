# == Defined resource type: ipmi::snmp
#

define ipmi::snmp (
  String  $snmp        = 'public',
  Integer $lan_channel = 1,
)
{
  exec { "ipmi_set_snmp_${lan_channel}":
    command => "/usr/bin/ipmitool lan set ${lan_channel} snmp ${snmp}",
    onlyif  => "/usr/bin/test \"$(ipmitool lan print ${lan_channel} | grep 'SNMP Community String' | sed -e 's/.* : //g')\" != \"${snmp}\"",
    require => Class['ipmi::install'],
  }
}
