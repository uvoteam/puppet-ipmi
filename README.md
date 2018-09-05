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

