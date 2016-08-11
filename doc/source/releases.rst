.. _releases:

Release Notes
=============

0.8.2
-----

* Bug fixes

  * Fixed the issue with Apache that could not handle the passive checks
    workload for large deployments. See
    `#1552772 <https://bugs.launchpad.net/lma-toolchain/+bug/1552772>`_.

0.8.1
-----

* Bug fixes

  * Check private addresses when VxLAN is enabled (`#1518377 <https://bugs.launchpad.net/lma-toolchain/+bug/1518377>`_).
  * Specify contact_groups for HTTP checks (`#1559151
    <https://bugs.launchpad.net/lma-toolchain/+bug/1559151>`_).
  * Specify contact_groups for SSH checks (`#1559153
    <https://bugs.launchpad.net/lma-toolchain/+bug/1559153>`_).

0.8.0
-----

* Initial release of the plugin.
