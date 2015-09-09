Logging, Monitoring and Alerting (LMA) Infrastructure Alerting Plugin for Fuel
==============================================================================

Overview
--------

The `LMA Infrastructure Alerting` plugin is composed of several services
running on a node (base-os role). It provides the alerting functionality for
the OpenStack Infrastructure inside the LMA toolchain.

The LMA toolchain is currently composed of these Fuel plugins:

        * [LMA collector Plugin](https://github.com/stackforge/fuel-plugin-lma-collector)
        * [InfluxDB-Grafana Plugin](https://github.com/stackforge/fuel-plugin-influxdb-grafana)
        * [Elasticsearch-Kibana Plugin](https://github.com/stackforge/fuel-plugin-elasticsearch-kibana)

Requirements
------------

| Requirement                               | Version/Comment  |
| ----------------------------------------- | -----------------|
| Mirantis OpenStack compatility            | 6.1 or higher    |
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

To install the LMA Infrastructure Alerting plugin, follow these steps:

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

Please refer to the [Fuel Plugins wiki](https://wiki.openstack.org/wiki/Fuel/Plugins)
if you want to build the plugin by yourself, version 2.0.0 (or higher) of the Fuel
Plugin Builder is required.

User Guide
==========

**LMA-Infrastructure-Alerting** plugin configuration
----------------------------------------------------

1. Create a new environment with the Fuel UI wizard.
2. Add a node with the "Operating System" role.
3. Before applying changes or once changes applied, edit the name of the node by
   clicking on "Untitled (xx:yy)" and modify it for "alerting".
4. Click on the Settings tab of the Fuel web UI.
5. Scroll down the page, select the "LMA Infrastructure Alerting Server plugin"
   checkbox and fill-in the required fields.
    - The name of the node where the plugin is deployed.
    - The username and password to access Nagios web interface.

### Disks partitioning
The plugin uses:

- 20% of the first disk for the operating system by honoring the range of
  15GB minimum and 50GB maximum.
- 20GB for Nagios archives (/var/nagios).
- 10GB for /var/log.

Please note that this partitioning schema doesn't use all disks available,
you should consider to adapt this default partioning logic before deploying the
node, accordingly to your requirements.

Testing
-------

### Nagios

Once installed, you can check that Nagios is working by pointing your browser
to this URL:

```
http://<HOST>/nagios3/
```

Where `HOST` is the IP address or the name of the node that runs the server.

You should be able to login using the username and password entered for the
configuration of the plugin.

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
https://review.openstack.org/#/q/status:open+project:stackforge/fuel-plugin-lma-infrastructure-alerting,n,z)
system.

Contributors
------------

* Swann Croiset <scroiset@mirantis.com>
* Simon Pasquier <spasquier@mirantis.com>
* Guillaume Thouvenin <gthouvenin@mirantis.com>
