# == Class: ipmi
#
# Please refer to https://github.com/jhoblitt/puppet-ipmi#usage for
# parameter documentation.
#
class ipmi (
  Enum[running,stopped] $service_ensure         = running,
  Enum[running,stopped] $ipmievd_service_ensure = stopped,
  Boolean               $watchdog               = false,
  Hash[String,Any]      $snmps                  = {},
  Hash[String,Any]      $users                  = {},
  Boolean               $block_unmanaged_users  = false,
  Hash[String,Any]      $networks               = {},
) inherits ipmi::params {
  include ::ipmi::install
  include ::ipmi::config

  class { '::ipmi::service::ipmi':
    ensure            => $service_ensure,
    enable            => $service_ensure ? {
      running => true,
      default => false,
    }
    ipmi_service_name => $ipmi::params::ipmi_service_name,
  }

  class { '::ipmi::service::ipmievd':
    ensure => $ipmievd_service_ensure,
    enable => $ipmievd_service_ensure ? {
      running => true,
      default => false,
    },
  }

  Class['::ipmi::install'] ~> Class['::ipmi::config'] ~> Class['::ipmi::service::ipmi'] ~> Class['::ipmi::service::ipmievd']

  if $snmps {
    create_resources('ipmi::snmp', $snmps)
  }

  if $users {
    create_resources('ipmi::user', $users)
  }

  if $block_unmanaged_users {
    unless empty($facts['ipmi_users']) {
      $not_defined_users = $users.reduce($facts['ipmi_users']) |$user_list, $kv| {
        $user_name = $kv[0]
        $user_id   = $kv[1][user_id]
        $user_list.filter |$user| { !( (!$user_id and $user_name == $user['name'] ) or $user['uid'] == $user_id ) }
      }

      $not_defined_users.each |$userdata| {
        $uid = $userdata['uid']
        ::ipmi::user { "disabled${uid}":
          user   => $userdata['name'],
          enable => false,
        }
      }
    }
  }

  if $networks {
    create_resources('ipmi::network', $networks)
  }
}
