.. _user_installation:

Installation Guide
==================

LMA Infrastructure Alerting Fuel Plugin install using the RPM file of the Fuel Plugins Catalog
----------------------------------------------------------------------------------------------

To install the LMA Infrastructure Alerting Fuel Plugin using the RPM file of the Fuel Plugins
Catalog, you need to follow these steps:

1. Download the RPM file from the `Fuel Plugins Catalog <https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/>`_.

2. Copy the RPM file to the Fuel Master node::

    [root@home ~]# scp lma_infrastructure_alerting-0.8-0.8.0-0.noarch.rpm /
    root@<Fuel Master node IP address>:

3. Install the plugin using the `Fuel CLI <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#using-fuel-cli>`_::

    [root@fuel ~]# fuel plugins --install /
    lma_infrastructure_alerting-0.8-0.8.0-0.noarch.rpm

4. Verify that the plugin is installed correctly::

    [root@fuel ~]# fuel plugins --list
    id | name                        | version | package_version
    ---|-----------------------------|---------|----------------
    1  | lma_infrastructure_alerting | 0.8.0   | 3.0.0


LMA Infrastructure Alerting Fuel Plugin software components
-----------------------------------------------------------

List of software components installed by the plugin

+-----------+---------------------------------------------+
| Component | Version                                     |
+===========+=============================================+
| Nagios    | v3.5.1 for Ubuntu (64-bit)                  |
+-----------+---------------------------------------------+
| Apache    | Version coming from the Ubuntu distribution |
+-----------+---------------------------------------------+
