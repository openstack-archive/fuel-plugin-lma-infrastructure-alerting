.. _releases:

Release Notes
=============

0.10.0
------

* Changes

  * Add supprt for LDAP(S) authentication to access the Nagios web UI.
    Note that the *nagiosadmin* user is still created statically
    and is the only user who has the *admin* priviledges by default.

  * Add Support for TLS encryption to access the Nagios web UI.
    A PEM file (obtained by concatenating the SSL certificates with
    the private key) must be provided in the settings of the plugin
    to configure the TLS termination. 

* Bug Fixes
  
  * Apache cannot handle the passive checks workload for large
    deployments (`1552772
    <https://bugs.launchpad.net/lma-toolchain/+bug/1552772>`_).

0.9.0
-----

* Changes 

  * Support Nagios clustering for high availability.

* Bug Fixes

  * Specify contact_groups for HTTP checks (`#1559151
    <https://bugs.launchpad.net/lma-toolchain/+bug/1559151>`_).

  * Specify contact_groups for SSH checks (`#1559153
    <https://bugs.launchpad.net/lma-toolchain/+bug/1559153>`_).

0.8.0
-----

* Initial release of the plugin.
