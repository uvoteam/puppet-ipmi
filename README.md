Puppet IPMI Module
==================

Overview
--------

This module is a rewrite almost from scratch of [jhoblitt/puppet-ipmi](https://github.com/jhoblitt/puppet-ipmi).
Main goal of this rewrite is to achieve better user management capabilities.
I am not yet familiar with testing framework, thus tests are dropped.

The ideas behind this implementation:
* UIDs 1 and 2 are not reliable and should be just disabled.
* UID is not important, it should be chosen automatically by the system.
* Channel ID on the other hand is quite important and should be specified explicitly.

Notes:
 * When making user 'absent' we're assigning it non-empty name 'disabled${uid}', because
   1) intel rmm3 refuses to assign empty names to users.
   2) intel rmm3 refuses to set parameters on not yet created users, thus you need to set name first.
 * Intel RMM3 refuses to have several users with the same name.
 * **BUG** on Intel RMM, when you assign any number of spaces as a username, it freaks out and won't allow you to change user name anymore.
   So, such user slot is effectively lost (maybe it can be recovered by reflashing with factory reset, but I haven't tried it yet).

Compatibility
-------------

Compatibility was not of a prime concern to me, but I have added handling of
old parameter names, where it seemed feasible. Some parameters are not
supported currently:

 * ipmi::snmps (absent)
 * ipmi::network::type (noop)
 * lost facts ipmiX_ipaddress_source and ipmiX_macaddress

Basic operation
---------------

Default assumption is that you want to have all users identical on all channels and that
you use them to access web interface and manage host via java/html5 applet. But underneath everything
is configurable, so you still can manage fine details, just with less convenience.

Example:

```puppet
class { 'ipmi':
    # disable any existing IPMI users, not managed by puppet
    purge_users => true,
    # disable any other LAN channels, that are not managed by puppet
    purge_lans  => true,
    # managed users hash
    users => {
        'test1' => {
            role     => operator,
            password => 'test12',
        },
        'test2' => {
            role     => admin,
            password => 'test14',
        },
        # you can set specific user ID by separating it with colon
        'test3:5' => {
            password => 'test13',
        },
        # ...or just specify it as a parameter on it's own
        'test4' => {
            userid   => 6,
            password => 'test13',
        },
    },
    # managed lan hash
    lans => {
        'privnet' => {
            address => '192.168.1.10',
            netmask => '255.255.255.0',
            gateway => '192.168.1.1',
        },
    }
}
```

Resource ipmi_user
------------------

While define `ipmi::user` does require you to specify value of user password and provides
defaults for parameters, underlying resource `ipmi_user` allows for much more freedom.
It will manage only those properties, that you will specify.

Some properties may be set for each LAN channel individually, and thus they have several
names. Let's take a `role` property for example. When you set just `role => admin` this
does not corellate to any real property of the resource, since plain `role` is not in fact a
property, but a parameter. This parameter sets default value for the real properties with names
`role_${channel}`. These properties are enabled in run-time by the presence or absence of
corresponding LAN channel. So, for example, to have user `admin` to have access only to
channel `3` you can write:

```puppet
ipmi_user { 'admin':
    ensure => present,
    role   => no_access,
    role_3 => admin,
}
```

Or just omit `role` entirely, so that you're only managing tis property value on channel `3`.

### username

This parameter sets the name of this user. This is namevar, so, it will hold the value of `$title`,
if not specified explicitly.

### userid

This parameter specifies explicitly user id to use. If it is not set explicitly and not provided
in the `$title` of the resource (as `$username:$userid`), it will be picked from the available
user ids, that are not managed by Puppet.

The logic behind assigning UIDs is as follows:

 * first, all UIDs, that belong to resources with explicitly specified `userid` are filtered out
 * then, from remaining users, if there is already the user with required username, it is selected
 * then, if there are any `absent` resources (our definition of `absent` is quite strict), first
   of them is picked
 * if there's still no matching resource to assign, implementation will pick first user, that is
   disabled
 * and finally, if there's no way to avoid clobbering existing users, it will pick first unmanaged
   user and assign it to resource.

### ensure

This property is required for resource purging to work. Here we assume user `present` if any
of it's properties on any LAN channel do not match the `absent`, which is defined as this:

 * user name is set to "disabled${userid}"
 * enabled => false
 * role => no_access
 * callin => false
 * link_auth => false
 * ipmi_msg => false
 * sol => false

### enable

This property enables or disables user (`ipmitool user enable/disable`). Depending on implementation
may have something to do with password.

### password

This property sets the password for user.

### role, role_X

Sets user access level on the channel(s). The values are

 * no_access
 * admin
 * operator
 * user
 * callback

### callin, callin_X

This property manages modem-related call-in/call-back authentication rights.

### link_auth, link_auth_X

Allows to use this user's credentials during link authentication on given channel.

### ipmi_msg, ipmi_msg_X

Enables user to send IPMI messages (whatever they are).

### sol, sol_X

Enables SOL (Serial Over Lan) payload for this user on given channel.

Resource ipmi_lan
-----------------

The same applies to `ipmi::lan` and `ipmi_lan` resource relationship - `ipmi::lan` sets
defaults and requires you to specify address, netmask, and gateway.

However, there's no finicky pseudo-properties, only the real ones.

### channel

Parameter, that sets channel id. If you omit it, resource will try to convert title to integer.
If that fails, it will use first available lan channel (on most platforms there's only one).

### ensure

While `ipmi_user` is strict in `ensure` compliance, this resource considers itself absent
when it's IP address is set to `0.0.0.0`. This may change in the future.

### auth_admin, auth_operator, auth_user, auth_callback

These propertise define list of allowed authentication methods for given roles on this channel.
Value must be an array. Possible values are:

 * none
 * md5
 * md2
 * plain

### address, netmask, gateway, backup_gateway

These properties configure IPv4 network on this channel. IPv6 is not supported yet (I have a hard
time finding firmware, that have this functionality in working order).

### arp_enable

This property have three values:

 * true - ARP responses are enabled
 * false - ARP responses are disabled
 * advertise - gratituous ARP broadcasts are enabled

### snmp_community

Sets SNMP community string.

### sol_enable

Enable Serial Over Lan on this channel.

### sol_encryption

Force encryption in SOL on this channel.

### sol_authentication

Force authentication in SOL on this channel.

### ciphers

Sets a list of allowed ciphers to use. Recommended set is [3, 8, 12].

Contribution
============

Ideas (especially backed by PRs) are welcome - I adapted this to our use case, other people may have different needs.

Acknowledgements
================

Although almost completely rewritten, this module started from [jhoblitt/puppet-ipmi](https://github.com/jhoblitt/puppet-ipmi).

Some defaults and ideas as to what to implement and what to omit are taken from the parper [IPMI++ Security Best Practices](http://fish2.com/ipmi/bp.pdf) by Dan Farmer

