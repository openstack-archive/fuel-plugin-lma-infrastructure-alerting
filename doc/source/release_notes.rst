.. _release_notes:

Release notes
-------------

Version 1.0.0
+++++++++++++

The StackLight Infrastructure Alerting plugin 1.0.0 contains the following
updates:

* Fixed an issue to allow the configuration of a list of LDAP servers. See
  `#1624002 <https://bugs.launchpad.net/lma-toolchain/+bug/1624002>`_.
* Modified the cron job to use a specific version of the plugin. See
  `#1622628 <https://bugs.launchpad.net/lma-toolchain/+bug/1622628>`_.
* Added support for wildcard SSL certificates. See
  `#1608665 <https://bugs.launchpad.net/lma-toolchain/+bug/1608665>`_.
* Fixed the UI issue with the LDAP protocol radio button. See
  `#1599778 <https://bugs.launchpad.net/lma-toolchain/+bug/1599778>`_.

Version 0.10.0
++++++++++++++

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

Version 0.9.0
+++++++++++++

The StackLight Infrastructure Alerting plugin 0.9.0 contains the following
updates:

  * Added support for Nagios clustering for high availability.

  * Bug fixes:

    * Specified contact_groups for HTTP checks.
      See `#1559151 <https://bugs.launchpad.net/lma-toolchain/+bug/1559151>`_.

    * Specified contact_groups for SSH checks.
      See `#1559153 <https://bugs.launchpad.net/lma-toolchain/+bug/1559153>`_.

Version 0.8.0
+++++++++++++

The initial release of the plugin.
