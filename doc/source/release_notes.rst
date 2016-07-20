.. _release_notes:

Release notes
-------------

0.10.0
++++++

The StackLight Infrastructure Alerting plugin 0.10.0 contains the following
updates:

  * Added support for LDAP(S) authentication to access the Nagios web UI.
    The *nagiosadmin* user is still created statically and is the only user
    who has the *admin* privileges by default.

  * Added Support for TLS encryption to access the Nagios web UI. A PEM file
    (obtained by concatenating the SSL certificates with the private key) must
    be provided in the settings of the plugin to configure the TLS termination.

  * Bug fixes:

    * Fixed the issue with Apache that could not handle the passive checks
      workload for large deployments. See
      `#1552772 <https://bugs.launchpad.net/lma-toolchain/+bug/1552772>`_.

0.9.0
+++++

The StackLight Infrastructure Alerting plugin 0.9.0 contains the following
updates:

  * Added support for Nagios clustering for high availability.

  * Bug fixes:

    * Specified contact_groups for HTTP checks.
      See `#1559151 <https://bugs.launchpad.net/lma-toolchain/+bug/1559151>`_.

    * Specified contact_groups for SSH checks.
      See `#1559153 <https://bugs.launchpad.net/lma-toolchain/+bug/1559153>`_.

0.8.0
+++++

The initial release of the plugin.
