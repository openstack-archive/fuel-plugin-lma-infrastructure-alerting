.. _verification:

.. raw:: latex

   \pagebreak

Plugin verification
-------------------

Depending on the number of nodes and deployment setup, deploying a Mirantis
OpenStack environment may take 20 minutes to several hours. Once the
deployment is complete, you should see a deployment success notification
message with a link to the Nagios web UI as shown below.

.. image:: ../images/deployment_notification.png
   :width: 460pt

Click :guilabel:`Nagios`. Once authenticated, you should be redirected to the
Nagios home page as shown below.

.. image:: ../images/nagios_homepage.png
   :width: 470pt

.. note:: The username is ``nagiosadmin`` by default, the password is defined
   in the settings.

.. note:: If Nagios is installed on the *management network*, you may not have
   direct access to the Nagios web UI. Extra network configuration may be
   required to create an SSH tunnel to the *management network*.