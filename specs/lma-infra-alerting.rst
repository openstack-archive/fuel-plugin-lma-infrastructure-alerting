..
 This work is licensed under a Creative Commons Attribution 3.0 Unported
 License.

 http://creativecommons.org/licenses/by/3.0/legalcode

=====================================================
Fuel plugin for the OpenStack Infrastructure Alarming
=====================================================


https://blueprints.launchpad.net/fuel/+spec/lma-infra-alerting-plugin

The `LMA Infrastructure Alerting` plugin is composed of several services
running on a node (base-os role). It provides alerting functionality for the
OpenStack Infrastructure inside the `LMA toolchain` [1]_ plugins suite.


Problem description
===================

Current implementation of the `LMA toolchain` [1]_ doesn't provide the alerting
functionality.

This specification aims to address the following use cases:

* OpenStack operator(s) want to be notified when the status of a component
  within the infrastructure changes:

  * OpenStack service status has changed (for example OKAY -> FAIL)
  * Cluster (RabbitMQ, MySQL, ..)  status has changed (for example OKAY -> WARN)
  * ...

* OpenStack operators(s) want to be notified when a threshold crossing occurs
  and be able to configure alarms with their own threshold against any of the
  available metrics collected by `LMA collector`:

  * Load average is too high on a controller node.
  * File system is nearly full on a node.
  * CPU usage is too high on a controller node.
  * ...

Proposed changes
================

Implement a Fuel plugin that will install and configure the LMA infrastructure
alerting system for an OpenStack environment.

The initial implementation of this plugin plans to install and configure
Nagios [2]_ to manage alerts and send notifications to operators by email.

There are two types of alerts which are initially supported:

   * Leverage the service status determinations computed by the `LMA collector`
     plugins (OKAY, WARN, FAIL, UNKNOWN).
   * Provide the ability to configure alarms over metrics by querying the
     time series database provided by the `Influxdb-Grafana` plugin [8]_

In order to implement these features into the `LMA toolchain` it's necessary
to:

1. Plug the `LMA collector` [3]_ to this new alerting system with the native
   Hekad [4]_ NagiosOutputPlugin [5]_ with HTTP method.
   Following example shows the configuration of Heka and Nagios for the
   Nova status:

.. code::

  # Heka configuation example
  [NagiosOutput]
  url = "http://<node-nagios>/nagios3/cgi-bin/cmd.cgi"
  username = "nagiosadmin"
  password = "supersecret"
  nagios_host = openstack-services"
  nagios_service_description = "openstack.nova.status"

  # Nagios configuration
  define service {
    check_command                  return-unknown-openstack.nova.status
    check_freshness                1
    check_interval                 30
    contact_groups                 openstack-admin
    display_name                   openstack.nova.status
    host_name                      openstack-services-env9
    freshness_threshold            45
    max_check_attempts             1
    retry_interval                 30
    passive_checks_enabled         1
    active_checks_enabled          0
    process_perf_data              0
    service_description            openstack.nova.status
    use                            generic-service
  }


2. Plug Nagios on the time series database InfluxDB [6]_ by integrating or
   developing a specialized Nagios plugin like [7]_ to allow to define alarm
   over metrics.
   This imply to configure Nagios hosts for all nodes.
   Following example is the configuration of an alert on CPU usage for
   primary controller:

.. code::

  # Nagios configuration to check CPU usage of nodes
  define command {
    command_name = check_cpu_for_host
    command_line = check_influx_for_host -H $_HOSTNODE_NAME$ -m cpu -w $ARG1$ -c $ARG2$
  }

  define host {
    host_name = primary-controller
    _node_name = node-2
    address = 10.109.0.4
    contact_groups = openstack-admin
    ..
  }

  # Check CPU usage with threshold set to 75% for WARNING and 95% for critical
  define service {
    service_description = CPU usage
    host_name = primary-controller
    contact_groups = openstack-admin
    check_command = check_cpu!75!95
    ...
  }

The resulting InfluxDB 0.8 query would be :

.. code::

  select mean(value) from merge(/node-2.cpu.\d+.user/) where time > now() - 1m group by time(1m)

With InfluxDB 0.9 the corresponding tag is used to filter per node:

.. code::

  select mean(value) from merge(/cpu.\d+.user/) where node='node-2' and time > now() - 1m group by time(1m)


Alternatives
------------

There are plenty of alerting solutions but Nagios is the dominant open
source monitoring solution. Hence Nagios brings a robust and proven solution
which match perfectly both to our alerting use case and the integration within
a legacy infrastructure monitoring.

It may be possible to leverage other open source solutions to complete and/or
replace Nagios in future.

The writing of a new alerting system would be also possible either by polling
the time serie database or by performing realtime computation of metrics.
But this would require to be scalable and would need to reinvent lots of things
that already exists.

Alert severities
----------------

The service statutes computed by the `LMA collector` are mapped with the states
defined by Nagios by this (simple) way:

+---------------+----------+
| LMA collector | Nagios   |
+===============+==========+
| OKAY          | OK       |
+---------------+----------+
| WARN          | WARNING  |
+---------------+----------+
| FAIL          | CRITICAL |
+---------------+----------+
| UNKNOWN       | UNKNOWN  |
+---------------+----------+

Contacts, Alerting and Escalation
---------------------------------

The plugin allows to configure one email to receive notifications, it's up to
the user to select which kind of event he/she will receive:

* critical
* warning
* unknown
* recovery

There is no escalation configuration proposed by the plugin. The user still have
the possiblity to configure manually after the deployment of the plugin.

Limitations
-----------

Adding and removing node(s) to/from the OpenStack cluster won't re-configure
the Nagios server.

This is a limitation of the Fuel Plugin Framework which don't trigger `task`
when those actions are performed. This limitation should be addressed by a
Fuel blueprint [9]_ in the future but might be not ready for MOS 7.0.

This limitation is leading the user to adjust manually the Nagios
configuration:

 * to not receive alert notifications about a deleted node,
 * to add the new node(s) to Nagios configuration.

A possible workaround for the 'adding case' would be to use a SSH command from
the new node(s) deployed to run the appropriate Puppet manifest on the Nagios
node. This workaround may be investigated eventually but not in the first place.

Data model impact
-----------------

None

REST API impact
---------------
None

Upgrade impact
--------------

None

Security impact
---------------

None

Notifications impact
--------------------

None

Other end user impact
---------------------

None

Performance Impact
------------------

The Nagios server can have several ``active checks`` which poll servers/services
and can lead to add extra workload on these targets.

This impact is minimized here by both:
 * the usage of ``passive checks`` (ie. Nagios receive status but doesn't poll)
 * Nagios doesn't poll servers to retrieve metrics but queries the time series
   database.


Other deployer impact
---------------------

New configuration options:

* email(s) of the operator
* SMTP gateway (optional)

Developer impact
----------------

None

Infrastructure impact
---------------------

None

Implementation
==============

Assignee(s)
-----------

Primary assignee:
  Swann Croiset <scroiset@mirantis.com> (developer)

Other contributors:
  Guillaume Thouvenin <gthouvenin@mirantis.com> (developer)
  Simon Pasquier <spasquier@mirantis.com> (feature lead, developer)

Work Items
----------

* Implement the Puppet manifests for both Ubuntu and CentOS to configure Nagios

  * Nagios server: main configuration.
  * Nagios CGI (Web interface) served by Apache [10]_ and PhP [11]_.
  * Nagios Objects configuration: Commands, Services, Hosts and Contacts.

* Add support for Nagios output plugin of the LMA collector.

* Implement the Nagios plugin to querying InfluxDB for alarm evaluation over
  metrics.

* Testing.

* Write the documentation.

Dependencies
============

* Fuel 6.1 and higher.

* LMA Collector Fuel plugin.

Testing
=======

* Prepare a test plan.

* Test the plugin by deploying environments with all Fuel deployment modes and
  the LMA toolchain configured.

* Create integration tests with the LMA toolchain

Acceptance criteria
-------------------

The operator must be notified by email when the state of an
OpenStack service change (OK -> DOWN, OK -> WARN, DOWN -> OK).

Documentation Impact
====================


* Write the User Guide for this plugin: deploy and configure the solution.

* Test Plan.

* Test Report.

References
==========

.. [1] The LMA toolchain is currently composed of several Fuel plugins:

        * LMA collector plugin
        * InfluxDB-Grafana plugin
        * Elasticsearch-Kibana plugin

.. [2] http://nagios.org

.. [3] https://github.com/stackforge/fuel-plugin-lma-collector

.. [4] http://hekad.readthedocs.org/

.. [5] http://hekad.readthedocs.org/en/v0.9.2/config/outputs/nagios.html

.. [6] http://www.influxdb.com/

.. [7] https://github.com/shaharke/influx-nagios-plugin

.. [8] https://github.com/stackforge/fuel-plugin-influxdb-grafana

.. [9] https://blueprints.launchpad.net/fuel/+spec/fuel-task-notify-other-nodes

.. [10] http://httpd.apache.org

.. [11] http://php.net
