.. _user_guide:

User Guide
==========

.. _plugin_configuration:

Plugin configuration
--------------------

To configure the **StackLight Intrastructure Alerting Plugin**, you need to follow these steps:

1. `Create a new environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment/start-create-env.html>`_.

2. Click on the *Settings* tab of the Fuel web UI and select the *Other* category.

3. Scroll down through the settings until you find the *StackLight Infrastructure
   Alerting Plugin* section. You should see a page like this.

   .. image:: ../images/lma_infrastructure_alerting_settings.png
      :width: 800
      :align: center

4. Tick the *StackLight Infrastructure Alerting Plugin* box and fill-in the required
   fields as indicated below.

   a. Override the Nagios web interface self-generated password if you choose to do so.
   #. Check the boxes corresponding to the type of notification you would
      like to be alerted for by email (*CRITICAL*, *WARNING*, *UNKNOWN*, *RECOVERY*).
   #. Specify the recipient email address for the alerts.
   #. Specify the sender email address for the alerts.
   #. Specify the SMTP server address and port.
   #. Specify the SMTP authentication method.
   #. Specify the SMTP username and password (required if the authentication method isn't *None*).

5. `Configure your environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment.html>`_.

   .. note:: By default, StackLight is configured to use the *management network*,
      of the so-called `Default Node Network Group
      <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment/network-settings.html>`_.
      While this default setup may be appropriate for small deployments or
      evaluation purposes, it is recommended not to use this network
      for StackLight in production. Instead it is recommended to create a network
      dedicated to StackLight. Using a dedicated network for  monitoring should
      improve the performance of StackLight and minimize the monitoring footprint
      on the control-plane. It will also facilitate access to the Nagios web UI
      after deployment. Please refer to the *StackLight Deployment Guide*
      for further information about that subject.

6. Click the *Nodes* tab and assign the *Infrastructure_Alerting* role
   to the node(s) where you want to install the plugin.

   You can see in the example below that the *Infrastructure_Alerting*
   role is assigned to three nodes along side with the
   *Elasticsearch_Kibana* role and the *InfluxDB_Grafana* role.
   Here, the three plugins of the LMA toolchain backend servers are
   installed on the same node.

   .. image:: ../images/lma_infrastructure_alerting_role.png
      :width: 800
      :align: center

   .. note:: Nagios clustering for high availability requires that you assign
      the *Infrastructure_Alerting* role to three different nodes.
      Note also that it is possible to add or remove nodes with the
      *Infrastructure_Alerting* role after deployment.

7. `Adjust the disk partitioning if necessary
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment/customize-partitions.html>`_.

   By default, the StackLight Infrastructure Alerting Plugin allocates:

     * 20% of the first available disk for the operating system
       by honoring a range of 15GB minimum and 50GB maximum,
     * 10GB for */var/log*,
     * At least 20 GB for the Nagios data in ``/var/nagios``.

   The deployment will fail if the above requirements are not met.

8. `Deploy your environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/deploy-environment.html>`_.

.. _plugin_install_verification:

Plugin verification
-------------------

Be aware, that depending on the number of nodes and deployment setup,
deploying a Mirantis OpenStack environment may typically take between
20 minutes to several hours. Once your deployment is complete,
you should see a deployment success notification message with
a link to the Nagios web UI as shown below.

.. image:: ../images/deployment_notification.png
   :align: center
   :width: 800

Click on the *Nagios* link.

Once you are authenticated,
you should be redirected to the **Nagios Home Page** as shown below.

.. image:: ../images/nagios_homepage.png
   :align: center
   :width: 800

.. note:: *username* is ``nagiosadmin`` by default, *password* is defined
   in the settings.

.. note:: Be aware that if Nagios is installed on the *management network*,
   you may not have direct access to the Nagios web UI. Some extra network
   configuration may be required to create an SSH tunnel to the *management network*.

Using Nagios
------------

The StackLight Infrastructure Alerting Plugin configures Nagios
to display the health status of all the nodes and services running
in the OpenStack environment. The alarms (or service checks in Nagios
terms) are created in **passive mode** which means that the actual
checks are not performed by Nagios itself, but by the Collector
and Aggregator agents of the LMA toolchain.

The best place to get an overview of your OpenStack environment
is to go the **Services Dashboard**.
If you click the *Services* link in the left panel of the
Nagios web UI, you should see a page like this:

.. image:: ../images/nagios_services.png
   :align: center
   :width: 800

In this dashboard, there are two 'virtual hosts' representing
the health status of the so-called **global clusters** and
**node clusters** entities:

  * *00-global-clusters-env${ENVID}* is used to represent the
    aggregated health status of global clusters like 'Nova',
    'Keystone' or 'RabbiMQ' to name a few.

  * *00-node-clusters-env${ENVID}* is used to represent the
    aggregated health status of  node clusters like
    'Controller', 'Compute' and 'Storage'.

Following the 'virtual hosts' sections, there is a list
of checks received for each of the nodes provisioned in the
environment. These checks may vary depending on the role of
the node being monitored.

Alerting for the global cluster entities is enabled by default.
Alerting for the nodes and clusters of nodes is disabled
by default to avoid the alert fatigue since those alerts should
not be representative of a critical condition affecting
the overall health status of the global cluster entities.
If you nonetheless want to enable those alerts, we can go
to the service details page and click on the *Enable notifications
for this service* link within the *Service Commands* panel as shown below.

.. image:: ../images/nagios_enable_notifs.png
   :align: center
   :width: 800

Finally, you should pay attention to the fact that there is
a direct dependency between the configuraton of the passive
checks in Nagios and the `configuration of the alarms in
the Collectors
<http://fuel-plugin-lma-collector.readthedocs.io/en/latest/alarms.html>`_.
A change in ``/etc/hiera/override/alarming.yaml`` or
``/etc/hiera/override/gse_filters.yaml`` on any of the
nodes monitored by StackLight would require to reconfigure Nagios.
It also implies that these two files should be maintained
rigourously identical on all the nodes of the environment
**including those where Nagios is installed**. Fortunately,
StackLight provides Puppet artefacts to help you out with
that task. To reconfigure the passive checks in Nagios
when ``/etc/hiera/override/alarming.yaml`` or
``/etc/hiera/override/gse_filters.yaml`` are modified
you should run the command shown bellow on all the nodes where
Nagios is installed::

  # puppet apply --modulepath=/etc/fuel/plugins/lma_infrastructure_alerting-<version>/puppet/modules:\
  /etc/puppet/modules \
  /etc/fuel/plugins/lma_infrastructure_alerting-<version>/puppet/manifests/nagios.pp

Configuring service checks using the InfluxDB metrics
-----------------------------------------------------

You could also configure Nagios to perform active checks,
which are not performed by StakLight by default, using the
metrics stored in InfluxDB's time-series.
For example, you could define active checks to be notified
when the CPU activity of particular process is too high.

Let's assume the following scenario.

  * You want to monitor the Elasticsearch server
  * The CPU activity of the Elasticsearch server is captured
    in a time-series stored in InfluxDB.
  * You want to receive an alert at the 'warning' level
    when the CPU load exceeds 30% of system activity.
  * You want to receive an alert at the 'critical' level
    when the CPU load exceeds 50% of system activity.

The steps to create such an alarms in Nagios would be as follow:

1. Connect to each of the nodes running Nagios.

2. Install the Nagios plugin for querying InfluxDB::

    [root@node-13 ~]# pip install influx-nagios-plugin

3. Define the command and the service check in the ``/etc/nagios3/conf.d/influxdb_services.conf`` file::

    # Replace <INFLUXDB_HOST>, <INFLUXDB_USER> and <INFLUXDB_PASSWORD> by
    # the appropriate values for your deployment
    define command {
      command_line /usr/local/bin/check_influx \
          -h <INFLUXDB_HOST> -u <INFLUXDB_USER> -p <INFLUXDB_PASSWORD> -d lma \
          -q "select max(value) from lma_components_cputime_syst \
          where time > now() - 5m and service='$ARG1$' \
          group by time(5m) limit 1" \
          -w $ARG2$ -c $ARG3$
      command_name check_cpu_metric
    }

    define service {
      service_description Elasticsearch system CPU
      host                node-13
      check_command       check_cpu_metric!elasticsearch!30!50:
      use                 generic-service
    }

4. Verify that the Nagios configuration is valid::

    [root@node-13 ~]# nagios3 -v /etc/nagios3/nagios.cfg

       [snip]

    Total Warnings: 0
    Total Errors:   0

  Here, things look okay. No serious problems were detected during the pre-flight check.

5. Restart the Nagios server::

    [root@node-13 ~]# crm resource restart nagios3

6. Go to the Nagios Web UI to verify that the service check has been added.

You can define additional service checks for different nodes or
node groups using the same ``check_influx`` command.
You will just need to provide these three required arguments for defining new service checks:

  * A valid InfluxDB query that should return only one row with a single value.
    Check the `InfluxDB documentation <https://docs.influxdata.com/influxdb/v0.10/query_language/>`_
    to learn how to use the InfluxDB's query language.
  * A range specification for the warning threshold.
  * A range specification for the critical threshold.

.. note:: Threshold ranges are defined following the `Nagios format
   <https://nagios-plugins.org/doc/guidelines.html#THRESHOLDFORMAT>`_.

Using an external SMTP server with STARTTLS
-------------------------------------------

If your SMTP server requires STARTTLS, you need to make some
manual adjustements to the Nagios configuration after the deployment of
your environment.

.. note:: Prior to enabling STARTTLS, you need to configure the *SMTP Authentication method*
   parameter in the plugin's settings to use either *Plain*, *Login* or *CRAM-MD5*.

1. Login to the *LMA Infrastructure Alerting* node.

2. Edit the
   ``/etc/nagios3/conf.d/cmd_notify-service-by-smtp-with-long-service-output.cfg``
   file to add the ``-S smtp-use-starttls`` option to the `mail` command. For
   example::

    define command{
      command_name    notify-service-by-smtp-with-long-service-output
      command_line    /usr/bin/printf "%b" "***** Nagios *****\n\n"\
        "Notification Type: $NOTIFICATIONTYPE$\n\n"\
        "Service: $SERVICEDESC$\nHost: $HOSTALIAS$\nAddress: $HOSTADDRESS$\n"\
        "State: $SERVICESTATE$\n\nDate/Time: $LONGDATETIME$\n\n"\
        "Additional Info:\n\n$SERVICEOUTPUT$\n$LONGSERVICEOUTPUT$\n" | \
        /usr/bin/mail -s "** $NOTIFICATIONTYPE$ "\
        "Service Alert: $HOSTALIAS$/$SERVICEDESC$ is $SERVICESTATE$ **" \
        -r 'nagios@localhost' \
        -S smtp="smtp://<SMTP_HOST>" \
        -S smtp-auth=<SMTP_AUTH_METHOD> \
        -S smtp-auth-user='<SMTP_USER>' \
        -S smtp-auth-password='<SMTP_PASSWORD>' \
        -S smtp-use-starttls \
        $CONTACTEMAIL$
    }

   .. note:: If the server certificate isn't present in the standard directory (eg
     ``/etc/ssl/certs`` on Ubuntu), you can specify its location by adding the ``-S
     ssl-ca-file=<FILE>`` option.

     If you want to disable the verification of the SSL/TLS server
     certificate altogether, you should add the ``-S ssl-verify=ignore`` option instead.

3. Verify that the Nagios configuration is correct::

    [root@node-13 ~]# nagios3 -v /etc/nagios3/nagios.cfg

4. Restart the Nagios service::

    [root@node-13 ~]# crm resource restart nagios3

Troubleshooting
---------------

If you cannot access the Nagios web UI, follow these troubleshooting tips.

1. Check that the StackLight Collector are able to connect to the Nagios
   VIP address on port *8001*.

2. Check that the Nagios configuration is valid::

    [root@node-13 ~]# nagios3 -v /etc/nagios3/nagios.cfg

       [snip]

    Total Warnings: 0
    Total Errors:   0

  Here, things look okay. No serious problems were detected during the pre-flight check.

3. Check that the Nagios server is up and running::

    [root@node-13 ~]# crm resource status nagios3
    resource nagios3 is NOT running
    resource nagios3 is NOT running

4. If Nagios is not running, start it::

    [root@node-13 ~]# crm resource start nagios3

5. Check that Apache is up and running::

    [root@node-13 ~]# crm resource status apache2-nagios

6. If Apache is not running, start it::

    [root@node-13 ~]# crm resource start apache2-nagios

7. Look for errors in the Nagios log file:
   
   * ``/var/nagios/nagios.log``.

8. Look for errors in the Apache log files:
   
   * ``/var/log/apache2/nagios_error.log``
   * ``/var/log/apache2/nagios_wsgi_access.log``
   * ``/var/log/apache2/nagios_wsgi_error.log``

Finally, Nagios may report a host or service state as *UNKNOWN*.
Two cases can be distinguished:

  * 'UNKNOWN: No datapoint have been received ever',
  * 'UNKNOWN: No datapoint have been received over the last X seconds'.

Both cases indicate that Nagios doesn't receive regular passive checks from
the StackLight Collector. This may be due to different problems:

  * The 'hekad' process fails to communicate with Nagios,
  * The 'collectd' and/or 'hekad' process have crashed,
  * One or several alarm rules are misconfigured.

To remedy to the above situations, follow the `troubleshooting tips
<http://fuel-plugin-lma-collector.readthedocs.io/en/latest/configuration.html#troubleshooting>`_
of the *StackLight Collector Plugin User Guide*.
