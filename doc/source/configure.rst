.. _configure_plugin:

Plugin configuration
--------------------

To configure the **StackLight Intrastructure Alerting Plugin**, you need to follow these steps:

1. `Create a new environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment/start-create-env.html>`_.

2. Click on the *Settings* tab of the Fuel web UI and select the *Other* category.

3. Scroll down through the settings until you find the *StackLight Infrastructure
   Alerting Plugin* section.

4. Tick the *StackLight Infrastructure Alerting Plugin* box and fill-in the required
   fields as indicated below.

   .. image:: ../images/lma_infrastructure_alerting_settings.png
      :width: 800
      :align: center

   a. Override the Nagios web interface self-generated password if you choose to do so.
   #. Check the boxes corresponding to the type of notification you would
      like to be alerted for by email (*CRITICAL*, *WARNING*, *UNKNOWN*, *RECOVERY*).
   #. Specify the recipient email address for the alerts.
   #. Specify the sender email address for the alerts.
   #. Specify the SMTP server address and port.
   #. Specify the SMTP authentication method.
   #. Specify the SMTP username and password (required if the authentication
      method isn't *None*).

5. Tick the *Enable TLS for Nagios* box if you want to encrypt your
   Nagios web UI credentials (username, password). Then, fill-in the required
   fields as indicated below.

   .. image:: ../images/tls_settings.png
      :width: 800
      :align: center

   a. Specify the DNS name of the Nagios web UI. This parameter is used
      to create a link from within the Fuel dashboard to the Nagios web UI.
   #. Specify the location of a PEM file, which contains the certificate
      and the private key of the server, that will be used in TLS handchecks
      with the client.

6. Tick the *Use LDAP for Nagios Authentication* box if you want to authenticate
   via LDAP to the Nagios Web UI. Then, fill-in the required fields as indicated below.

   .. image:: ../images/ldap_auth.png
      :width: 800
      :align: center

   a. Select the *LDAPS* button if you want to enable LDAP authentication
      over SSL.
   #. Specify one or several LDAP server addresses separated by a space. Those
      addresses must be accessible from the node where Nagios is installed.
      Note that addresses external to the *management network* are not routable
      by default (see the note below).
   #. Specify the LDAP server port number or leave it empty to use the defaults.
   #. Specify the *Bind DN* of a user who has search priviliges on the LDAP server.
   #. Specify the password of the user identified by *Bind DN* above.
   #. Specify the *Base DN* in the Directory Information Tree (DIT) from where
      to search for users.
   #. Specify a valid *search filter* to search for users. The search should
      return a unique user entry.

   You can further restrict access to the Nagios web UI to those users who
   are member of a specific LDAP group. Note however that with the Nagios
   web UI there is no notion of privileged (admin) access.

   a. Tick the *Enable group-based authorization* to restrict the access to
      a group of users.
   #. Specify the LDAP attribute in the user entry to identify the
      the group of users.
   #. Specify the DN of the LDAP group that has access to the Nagios web UI.

7. `Configure your environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment.html>`_.

   .. note:: By default, StackLight is configured to use the *management network*,
      of the so-called `Default Node Network Group
      <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment/network-settings.html>`_.
      While this default setup may be appropriate for small deployments or
      evaluation purposes, it is recommended not to use this network
      for StackLight in production. It is instead recommended to create a network
      dedicated to StackLight. Using a dedicated network for StackLight should
      improve performances and reduce the monitoring footprint.
      It will also facilitate access to the Nagios web UI
      after deployment.

8. Click the *Nodes* tab and assign the *Infrastructure_Alerting* role
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

9. `Adjust the disk partitioning if necessary
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment/customize-partitions.html>`_.

   By default, the StackLight Infrastructure Alerting Plugin allocates:

     * 20% of the first available disk for the operating system
       by honoring a range of 15GB minimum and 50GB maximum,
     * 10GB for */var/log*,
     * At least 20 GB for the Nagios data in ``/var/nagios``.

   The deployment will fail if the above requirements are not met.

10. `Deploy your environment
    <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/deploy-environment.html>`_.