.. _troubleshooting:

Troubleshooting
---------------

If you cannot access the Nagios web UI, follow these troubleshooting tips.

1. Check that the StackLight Collector are able to connect to the Nagios
   VIP address on port *80*.

2. Check that the Nagios configuration is valid::

    [root@node-13 ~]# nagios3 -v /etc/nagios3/nagios.cfg

       [snip]

    Total Warnings: 0
    Total Errors:   0

  Here, things look okay. No serious problems were detected during the pre-flight check.

3. Check that the Nagios server is up and running::

    [root@node-13 ~]# crm resource status nagios3
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