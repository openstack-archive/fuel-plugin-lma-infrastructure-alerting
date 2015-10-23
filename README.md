Logging, Monitoring and Alerting (LMA) Infrastructure Alerting Plugin for Fuel
==============================================================================

Overview
--------

The `LMA Infrastructure Alerting` plugin is composed of several services
running on a node (base-os role). It provides the alerting functionality for
the OpenStack Infrastructure inside the LMA toolchain.

The LMA toolchain is currently composed of these Fuel plugins:

        * [LMA collector Plugin](https://github.com/openstack/fuel-plugin-lma-collector)
        * [InfluxDB-Grafana Plugin](https://github.com/openstack/fuel-plugin-influxdb-grafana)
        * [Elasticsearch-Kibana Plugin](https://github.com/openstack/fuel-plugin-elasticsearch-kibana)

Requirements
------------

| Requirement                               | Version/Comment  |
| ----------------------------------------- | -----------------|
| Mirantis OpenStack compatility            | 7.0 or higher    |
| LMA Collector Fuel plugin                 | 0.8 or higher    |
| InfluxDB-Grafana Fuel plugin (optional)   | 0.8 or higher    |

Recommendations
---------------

None.

Limitations
-----------

Adding and removing node to/from an environment won't reconfigure the Nagios
server.
This limitation is due to the missing ability of Fuel Plugin Framework to apply
plugin tasks (puppet apply) when these operations occur.


Installation Guide
==================

LMA Infrastructure Alerting Plugin install from the RPM file
------------------------------------------------------------

To install the LMA Infrastructure Alerting Plugin from the RPM file of the plugin, follow these steps:

1. Download the plugin from the [Fuel Plugins
   Catalog](https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/).

2. Copy the plugin file to the Fuel Master node. Follow the [Quick start
   guide](https://software.mirantis.com/quick-start/) if you don't have a running
   Fuel Master node yet.

   ```
   scp lma_infrastructure_alerting-0.8-0.8.0-0.noarch.rpm root@<the Fuel Master node IP address>:
   ```

3. Install the plugin using the `fuel` command line:

   ```
   fuel plugins --install lma_infrastructure_alerting-0.8-0.8.0-0.noarch.rpm
   ```

4. Verify that the plugin is installed correctly:

   ```
   fuel plugins
   ```

LMA Infrastructure Alerting Plugin install from source
------------------------------------------------------

To install the LMA Infrastructure Alerting Plugin from source, you first need to prepare an
environement to build the RPM file of the plugin.
The recommended approach is to build the RPM file directly onto the Fuel Master
node so that you won't have to copy that file later.

**Prepare an environment for building the plugin on the Fuel Master Node**

* 1. Install the standard Linux development tools:

    ```
    # yum install createrepo rpm rpm-build dpkg-devel
    ```

* 2. Install the Fuel Plugin Builder. To do that, you should first get pip:

    ```
    # easy_install pip
    ```

* 3. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip:

    ```
    # pip install fuel-plugin-builder
    ```

*Note: You may also have to build the Fuel Plugin Builder if the package version of the
plugin is higher than package version supported by the Fuel Plugin Builder you get from `pypi`.
In this case, please refer to the section "Preparing an environment for plugin development"
of the [Fuel Plugins wiki](https://wiki.openstack.org/wiki/Fuel/Plugins) if you
need further instructions about how to build the Fuel Plugin Builder.*

* 4. Clone the LMA Infrastructure Alerting Plugin git repository:

    ```
    # git clone git@github.com:openstack/fuel-plugin-lma-infrastructure-alerting.git
    ```

* 5. Check that the plugin is valid:

    ```
    # fpb --check ./fuel-plugin-lma-infrastructure-alerting
    ```

* 6. And finally, build the plugin:

    ```
    # fpb --build ./fuel-plugin-lma-infrastructure-alerting
    ```

* 7. Now you have created an RPM file that you can install using the steps described above:

    ```
    # ls ./fuel-plugin-lma-infrastructure-alerting/lma_infrastructure_alerting-0.8-0.8.0-1.noarch.rpm
    ./fuel-plugin-lma-infrastructure-alerting/lma_infrastructure_alerting-0.8-0.8.0-1.noarch.rpm
    ```

User Guide
==========

**LMA-Infrastructure-Alerting** plugin configuration
----------------------------------------------------

1. Create a new environment with the Fuel UI wizard.
2. Click on the Settings tab of the Fuel web UI.
3. Scroll down the page, enable the "LMA Infrastructure Alerting Server plugin"
   and fill-in the required fields.
    - The password to access Nagios web interface.
    - The recipient email address
    - The sender email address
    - The SMTP server IP and port
    - Fill-in autentication parameters if enabled.

4. Add one node with the "Infrastructure Alerting" role.

### Disks partitioning
The plugin uses:

- 20% of the first disk for the operating system by honoring the range of
  15GB minimum and 50GB maximum.
- 20GB for Nagios data and logs (/var/nagios).
- 10GB for /var/log.

It is recommended to review the partitioning done by Fuel before the deployment
and adapt it to your requirements.

Testing
-------

### Nagios

Once installed, you can check that Nagios is working by pointing your browser
to this URL:

```
http://<HOST>:8001
```

Where `HOST` is the IP address or the name of the node that runs the server.

You should be able to login using the username *nagiosadmin* and password
entered for the configuration of the plugin.

Known issues
------------

None.

Release Notes
-------------

**0.8.0**

* Initial release of the plugin. This is a beta version.


Development
===========

The *OpenStack Development Mailing List* is the preferred way to communicate,
emails should be sent to `openstack-dev@lists.openstack.org` with the subject
prefixed by `[fuel][plugins][lma]`.

Reporting Bugs
--------------

Bugs should be filled on the [Launchpad fuel-plugins project](
https://bugs.launchpad.net/fuel-plugins) (not GitHub) with the tag `lma`.


Contributing
------------

If you would like to contribute to the development of this Fuel plugin you must
follow the [OpenStack development workflow](
http://docs.openstack.org/infra/manual/developers.html#development-workflow).

Patch reviews take place on the [OpenStack gerrit](
https://review.openstack.org/#/q/status:open+project:openstack/fuel-plugin-lma-infrastructure-alerting,n,z)
system.

Contributors
------------

* Swann Croiset <scroiset@mirantis.com>
* Simon Pasquier <spasquier@mirantis.com>
* Guillaume Thouvenin <gthouvenin@mirantis.com>
