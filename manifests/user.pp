# == Defined resource type: ipmi::user
#

define ipmi::user (
  Integer                                                       $user_id,
  Boolean                                                       $enable   = true,
  String                                                        $user     = '',
  Optional[String]                                              $password = undef,
  Optional[Enum[callback,user,operator,administrator,disabled]] $priv     = undef,
)
{
  $privilege = upcase($priv ? {
    disabled => 'no access',
    default  => $priv,
  })

  $priv_id   = $priv ? {
    callback      => 1,
    user          => 2,
    operator      => 3,
    administrator => 4,
    disabled      => 15,
  }

  Exec {
    require => Class['ipmi::install']
  }

  exec { "ipmi_user_enable_${title}":
    command     => "/usr/bin/ipmitool user enable ${user_id}",
    refreshonly => true,
  }

  exec { "ipmi_user_add_${title}":
    command => "/usr/bin/ipmitool user set name ${user_id} ${user}",
    unless  => "/usr/bin/test \"$(ipmitool user list 1 | grep '^${user_id}' | awk '{print \$2}')\" = \"${user}\"",
    notify  => [Exec["ipmi_user_priv_${title}"], Exec["ipmi_user_setpw_${title}"]],
  }

  exec { "ipmi_user_priv_${title}":
    command => "/usr/bin/ipmitool user priv ${user_id} ${priv_id} 1",
    unless  => "/usr/bin/test \"$(ipmitool user list 1 | grep '^${user_id}' | awk '{print \$6}')\" = ${privilege}",
    notify  => [Exec["ipmi_user_enable_${title}"], Exec["ipmi_user_enable_sol_${title}"], Exec["ipmi_user_channel_setaccess_${title}"]],
  }

  exec { "ipmi_user_setpw_${title}":
    command => "/usr/bin/ipmitool user set password ${user_id} \'${password}\'",
    unless  => "/usr/bin/ipmitool user test ${user_id} 16 \'${password}\'",
    notify  => [Exec["ipmi_user_enable_${title}"], Exec["ipmi_user_enable_sol_${title}"], Exec["ipmi_user_channel_setaccess_${title}"]],
  }

  $status = $enable ? {
    true  => 'enable',
    false => 'disable',
  }

  exec { "${status} ipmi user ${title}":
    command => "/usr/bin/ipmitool user ${status} ${user_id}",
    unless  => "/usr/bin/test \"$(ipmitool channel getaccess 1 ${user_id} | grep '^Enable Status' | awk '{print \$4}')\" = ${status}d",
  }

  exec { "ipmi_user_enable_sol_${title}":
    command     => "/usr/bin/ipmitool sol payload enable 1 ${user_id}",
    refreshonly => true,
  }

  exec { "ipmi_user_channel_setaccess_${title}":
    command     => "/usr/bin/ipmitool channel setaccess 1 ${user_id} callin=on ipmi=on link=on privilege=${priv}",
    unless      => "test ${user_id} = 2",
    refreshonly => true,
  }
}
