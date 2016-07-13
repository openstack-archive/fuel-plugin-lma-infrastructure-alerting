.. _usage:

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