.. _plugin_requirements:

.. raw:: latex

   \pagebreak

Requirements
------------

The StackLight Infrastructure Alerting plugin 1.0.0 has the following
requirements:

+------------------------+------------------------------------------------------------------------------------------+
| **Requirement**        | **Version/Comment**                                                                      |
+========================+==========================================================================================+
| Disk space             | The plugin's specification requires provisioning at least 15 GB of disk space for the    |
|                        | system, 10 GB for the logs, and 20 GB for Nagios. Therefore, the installation            |
|                        | of the plugin will fail if there is less than 45 GB of disk space available on the node. |
+------------------------+------------------------------------------------------------------------------------------+
| Hardware configuration | The hardware configuration (RAM, CPU, disk) required by this plugin depends on the size  |
|                        | of your cloud environment and other parameters like the retention period of the data.    |
|                        |                                                                                          |
|                        | A typical setup would at least require a quad-core server with 8 GB of RAM and fast disks|
|                        | (ideally, SSDs).                                                                         |
+------------------------+------------------------------------------------------------------------------------------+
| Mirantis OpenStack     | 8.0, 9.0                                                                                 |
+------------------------+------------------------------------------------------------------------------------------+
| The StackLight         | 0.10                                                                                     |
| Collector Plugin       |                                                                                          |
+------------------------+------------------------------------------------------------------------------------------+
| The StackLight InfluxDB| 0.10                                                                                     |
| Grafana Plugin         |                                                                                          |
|                        | This is optional and only needed if you want to create alarms in Nagios for              |
|                        | time-series stored in InfluxDB.                                                          |
+------------------------+------------------------------------------------------------------------------------------+
