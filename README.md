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
 * **BUG** intel rmm3 authenticator dies, when you assign any number of spaces as a username. And won't let you change the name back. Basically, this operation bricks your ipmi.
