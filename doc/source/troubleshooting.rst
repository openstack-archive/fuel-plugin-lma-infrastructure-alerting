.. _troubleshooting:

.. raw:: latex

   \pagebreak

Troubleshooting
---------------

If you cannot access the Nagios web UI, use the following troubleshooting tips.

#. Verify that the StackLight Collector is able to connect to the Nagios VIP
   address on port ``80``.

#. Verify that the Nagios configuration is valid:

   .. code-block:: console

      [root@node-13 ~]# nagios3 -v /etc/nagios3/nagios.cfg

         [snip]

      Total Warnings: 0
      Total Errors:   0

  No serious problems were detected during the pre-flight check.

#. Verify that the Nagios server is up and running:

   .. code-block:: console

      [root@node-13 ~]# crm resource status nagios3
      resource nagios3 is NOT running

#. If Nagios is not running, start it:

   .. code-block:: console

      [root@node-13 ~]# crm resource start nagios3

#. Verify that Apache is up and running:

   .. code-block:: console

      [root@node-13 ~]# crm resource status apache2-nagios

#. If Apache is not running, start it::

    [root@node-13 ~]# crm resource start apache2-nagios

#. Look for errors in the Nagios ``/var/nagios/nagios.log`` log file:

#. Look for errors in the Apache log files:

   * ``/var/log/apache2/nagios_error.log``
   * ``/var/log/apache2/nagios_wsgi_access.log``
   * ``/var/log/apache2/nagios_wsgi_error.log``

Nagios may report a host or service state as *UNKNOWN*, for example:

  * 'UNKNOWN: No datapoint have been received ever'
  * 'UNKNOWN: No datapoint have been received over the last X seconds'

Both cases indicate that Nagios does not receive regular passive checks from
the StackLight Collector. This may be due to different issues, for example:

  * The 'hekad' process fails to communicate with Nagios
  * The 'collectd' and/or 'hekad' process have crashed
  * One or several alarm rules are misconfigured

For solutions, see the `Troubleshooting tips
<http://fuel-plugin-lma-collector.readthedocs.io/en/latest/configuration.html#troubleshooting>`_
of the *StackLight Collector Plugin User Guide*.