.. _user_overview:

Overview
========

The **LMA Infrastructure Alerting Plugin** is used to install and configure
Nagios which provides the alerting and escalation functionalities of the LMA
Toolchain.

Nagios is a key component of the `LMA Toolchain project <https://launchpad.net/lma-toolchain>`_
as shown in the figure below.

.. image:: ../images/toolchain_map.*
   :align: center

.. _plugin_requirements:

Requirements
------------

+----------------------------------+---------------------------------------------------------+
| Requirement                      | Version/Comment                                         |
+==================================+=========================================================+
| Fuel                             | Mirantis OpenStack 7.0                                  |
+----------------------------------+---------------------------------------------------------+
| The LMA collector Fuel plugin    | At least 0.8.0                                          |
+----------------------------------+---------------------------------------------------------+
| The InfluxDB-Grafana Fuel plugin | At least 0.8.0                                          |
|                                  |                                                         |
|                                  | This is optional and only needed if you want to trigger |
|                                  | alarms from InfluxDB data.                              |
+----------------------------------+---------------------------------------------------------+

.. note:: Please take into consideration the information on the disks partitioning.
          By default, the LMA Infrastructure Alerting Plugin allocates:
         - 20% of the first available disk for the operating system by honoring a range of
           15GB minimum and 50GB maximum.
         -  10GB for `/var/log`.
         - At least 20 GB for the Nagios data in `/var/nagios`.

Limitations
-----------

A current limitation of this plugin is that it not possible to display in the Fuel web UI,
the URL where the Nagios interface can be reached when the deployment has completed.
Instructions are provided in the :ref:`user_guide` about how you can
obtain this URL using the `fuel` command line.





