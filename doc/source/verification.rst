.. _verification:

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