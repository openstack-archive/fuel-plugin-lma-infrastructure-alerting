#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
import os

from proboscis import asserts
from proboscis import test

from fuelweb_test.helpers.decorators import log_snapshot_after_test
from fuelweb_test import logger
from fuelweb_test import settings
from fuelweb_test.tests import base_test_case

import requests


@test(groups=["plugins"])
class TestLMAInfraAlertingPlugin(base_test_case.TestBasic):
    """Class for testing the LMA Infrastructure Alerting plugin."""

    _name = 'lma_infrastructure_alerting'
    _version = '0.9.0'
    _role_name = 'infrastructure_alerting'
    _nagios_user = 'nagiosadmin'
    _nagios_password = 'r00tme'
    _send_to = 'root@localhost'
    _send_from = 'nagios@localhost'
    _smtp_host = '127.0.0.1'

    def prepare_plugins(self, dependencies=True):
        self.env.admin_actions.upload_plugin(plugin=settings.LMA_INFRA_ALERTING_PLUGIN_PATH)
        self.env.admin_actions.install_plugin(
            plugin_file_name=os.path.basename(settings.LMA_INFRA_ALERTING_PLUGIN_PATH))
        if dependencies:
            self.env.admin_actions.upload_plugin(plugin=settings.LMA_COLLECTOR_PLUGIN_PATH)
            self.env.admin_actions.install_plugin(
                plugin_file_name=os.path.basename(settings.LMA_COLLECTOR_PLUGIN_PATH))
            self.env.admin_actions.upload_plugin(
                plugin=settings.INFLUXDB_GRAFANA_PLUGIN_PATH)
            self.env.admin_actions.install_plugin(
                plugin_file_name=os.path.basename(settings.INFLUXDB_GRAFANA_PLUGIN_PATH))

    def activate_plugins(self, cluster_id, dependencies=True):
        msg = "LMA Infra Alerting Plugin couldn't be enabled. Check plugin version. Test aborted"
        asserts.assert_true(self.fuel_web.check_plugin_exists(cluster_id, self._name), msg)
        options = {
            'nagios_password/value': self._nagios_password,
            'send_to/value': self._send_to,
            'send_from/value': self._send_from,
            'smtp_host/value': self._smtp_host,
        }
        self.fuel_web.update_plugin_settings(cluster_id, self._name, self._version, options)
        if dependencies:
            plugins = [
                {
                    'name': 'lma_collector',
                    'version': '0.9.0',
                    'options': {
                        'elasticsearch_mode/value': 'disabled',
                        'influxdb_mode/value': 'local',
                        'alerting_mode/value': 'local',
                    }
                },
                {
                    'name': 'influxdb_grafana',
                    'version': '0.9.0',
                    'options': {
                        'influxdb_rootpass/value': 'r00tme',
                        'influxdb_username/value': 'influxdb',
                        'influxdb_userpass/value': 'influxdbpass',
                        'grafana_username/value': 'grafana',
                        'grafana_userpass/value': 'grafanapass',
                        'mysql_mode/value': 'local',
                        'mysql_dbname/value': 'grafanalma',
                        'mysql_username/value': 'grafanalma',
                        'mysql_password/value': 'mysqlpass',
                    }
                },
            ]

            for plugin in plugins:
                msg = "{} couldn't be enabled. Check plugin version. Test aborted".format(plugin['name'])
                asserts.assert_true(self.fuel_web.check_plugin_exists(cluster_id, plugin['name']), msg)
                self.fuel_web.update_plugin_settings(cluster_id,
                                                     plugin['name'], plugin['version'], plugin['options'])

    def check_nagios_online(self, cluster_id):
        lma_alerting_vip = self.get_alerting_ip(cluster_id)
        asserts.assert_is_not_none(lma_alerting_vip, "Failed to get the IP of Nagios server")

        logger.info("Check that the Nagios server is running")
        r = requests.get(
            "http://{0}:{1}@{2}:8001".format(
                self._nagios_user, self._nagios_password, lma_alerting_vip))
        msg = "Nagios server responded with {}, expected 200".format(
            r.status_code)
        asserts.assert_equal(r.status_code, 200, msg)

    def get_alerting_ip(self, cluster_id):
        networks = self.fuel_web.client.get_networks(cluster_id)
        return networks.get('infrastructure_alerting')

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["install_lma_infra_alerting"])
    @log_snapshot_after_test
    def install_lma_infra_alerting_plugin(self):
        """Install LMA Infrastructure Alerting plugin and check it exists

        Scenario:
            1. Upload plugin to the master node
            2. Install plugin
            3. Create cluster
            4. Check that plugin exists

        Duration 20m
        """
        self.env.revert_snapshot("ready_with_3_slaves")

        self.prepare_plugins(dependencies=False)

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            mode=settings.DEPLOYMENT_MODE,
        )

        self.activate_plugins(cluster_id, dependencies=False)

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["deploy_lma_infra_alerting"])
    @log_snapshot_after_test
    def deploy_lma_infra_alerting_plugin(self):
        """Deploy a cluster with the LMA Infrastructure Alerting plugin

        Scenario:
            1. Upload plugins to the master node
            2. Install plugins
            3. Create cluster
            4. Add 1 node with controller role
            5. Add 1 node with compute role
            6. Add 1 node with lma infrastructure alerting,
             influxdb grafana roles
            7. Deploy the cluster
            8. Check that plugin is working
            9. Run OSTF

        Duration 60m
        Snapshot deploy_lma_alerting_plugin
        """
        self.env.revert_snapshot("ready_with_3_slaves")

        self.prepare_plugins()

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            mode=settings.DEPLOYMENT_MODE,
        )

        self.activate_plugins(cluster_id)

        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['compute'],
                'slave-03': [self._role_name, 'influxdb_grafana']
            }
        )

        self.fuel_web.deploy_cluster_wait(cluster_id)

        self.check_nagios_online(cluster_id)

        self.fuel_web.run_ostf(cluster_id=cluster_id)

        self.env.make_snapshot("deploy_lma_alerting_plugin")

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_9],
          groups=["deploy_lma_infra_alerting_ha"])
    @log_snapshot_after_test
    def deploy_lma_infra_alerting_plugin_in_ha_mode(self):
        """Deploy a cluster with the LMA Infrastructure Alerting plugin

        Scenario:
            1. Upload plugins to the master node
            2. Install plugins
            3. Create cluster
            4. Add 3 nodes with controller role
            5. Add 1 node with compute and cinder roles
            6. Add 3 nodes with lma infrastructure alerting,
             influxdb grafana roles
            7. Deploy the cluster
            8. Check that plugin is working
            9. Run OSTF

        Duration 60m
        Snapshot deploy_lma_alerting_plugin
        """
        self.env.revert_snapshot("ready_with_9_slaves")

        self.prepare_plugins()

        cluster_id = self.fuel_web.create_cluster(
            name=self.__class__.__name__,
            mode=settings.DEPLOYMENT_MODE,
        )

        self.activate_plugins(cluster_id)

        self.fuel_web.update_nodes(
            cluster_id,
            {
                'slave-01': ['controller'],
                'slave-02': ['controller'],
                'slave-03': ['controller'],
                'slave-04': ['compute', 'cinder'],
                'slave-05': [self._role_name, 'influxdb_grafana'],
                'slave-06': [self._role_name, 'influxdb_grafana'],
                'slave-07': [self._role_name, 'influxdb_grafana']
            }
        )

        self.fuel_web.deploy_cluster_wait(cluster_id)

        self.check_nagios_online(cluster_id)

        self.fuel_web.run_ostf(cluster_id=cluster_id)

        self.env.make_snapshot("deploy_lma_alerting_plugin")
