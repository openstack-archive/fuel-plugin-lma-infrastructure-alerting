.. _user_overview:

Overview
========

The **StackLight Infrastructure Alerting Plugin** is used to install and configure
Nagios which provides the alerting and escalation functionalities of the so-called
Logging, Monitoring and Alerting Toolchain of Mirantis OpenStack.

Nagios is a key component of the `LMA Toolchain project <https://launchpad.net/lma-toolchain>`_
as shown in the figure below.

.. image:: ../images/toolchain_map.*
   :align: center

.. _plugin_requirements:

Requirements
------------

+------------------------+------------------------------------------------------------------------------------------+
| **Requirement**        | **Version/Comment**                                                                      |
+========================+==========================================================================================+
| Disk space             | The plugin's specification requires to provision at least 15GB of disk space for the     |
|                        | system, 10GB for the logs and 20GB for Nagios. As a result, the installation             |
|                        | of the plugin will fail if there is less than 45GB of disk space available on the node.  |
+------------------------+------------------------------------------------------------------------------------------+
| Hardware configuration | The hardware configuration (RAM, CPU, disk) required by this plugin depends on the size  |
|                        | of your cloud environment and other parameters like the retention period of the data.    |
|                        |                                                                                          |
|                        | A typical setup would at least require a quad-core server with 8GB of RAM and fast disks |
|                        | (ideally, SSDs).                                                                         |
+------------------------+------------------------------------------------------------------------------------------+
| Mirantis OpenStack     | 8.0, 9.0                                                                                 |
+------------------------+------------------------------------------------------------------------------------------+
| The Stack Collector    | 0.10                                                                                     |
| Plugin                 |                                                                                          |
+------------------------+------------------------------------------------------------------------------------------+
| The Stackligh InfluxDB | 0.10                                                                                     |
| Grafana Plugin         | This is optional and only needed if you want to create alarms in Nagios™ for             |
|                        | time-series stored in InfluxDB.                                                          |
+------------------------+------------------------------------------------------------------------------------------+

Limitations
-----------

* If Nagios is installed on several nodes for high availability, the alerts history will be lost in case of
  a server failover.
