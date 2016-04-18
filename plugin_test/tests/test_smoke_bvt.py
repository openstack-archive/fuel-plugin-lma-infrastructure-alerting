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

import helpers.plugin_ui as plugin_ui

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

    def add_remove_node(self, node_updates):
        self.env.revert_snapshot("deploy_lma_alerting_plugin_ha")

        cluster_id = self.fuel_web.get_last_created_cluster()
        # remove 1 node with specified role.
        self.fuel_web.update_nodes(cluster_id, node_updates, False, True)

        self.fuel_web.deploy_cluster_wait(cluster_id, check_services=False)
        self.check_nagios_online(cluster_id)
        self.fuel_web.run_ostf(cluster_id=cluster_id, should_fail=1)
        self.check_node_in_nagios(cluster_id, node_updates, False)

        # add 1 node with specified role.
        self.fuel_web.update_nodes(cluster_id, node_updates)

        self.fuel_web.deploy_cluster_wait(cluster_id, check_services=False)
        self.check_nagios_online(cluster_id)
        self.fuel_web.run_ostf(cluster_id=cluster_id, should_fail=1)
        self.check_node_in_nagios(cluster_id, node_updates, True)

    def get_alerting_tasks_pids(self):
        nodes = ['slave-0{0}'.format(slave) for slave in xrange(1, 4)]
        processes = ['heka', 'collectd']
        pids = {}

        for node in nodes:
            with self.fuel_web.get_ssh_for_node(node) as remote:
                pids[node] = {}
                for process in processes:
                    result = remote.execute("ps axf | grep {0} | grep -v grep "
                                            "| awk '{{print $1}}'".format(process))
                    pids[node][process] = result['stdout'][0].rstrip()

        with self.fuel_web.get_ssh_for_node('slave-03') as remote:
            result = remote.execute("ps axf | grep influxdb | grep -v grep | awk '{print $1}'")
            pids['slave-03']['influxdb'] = result['stdout'][0].rstrip()

        return pids

    def check_node_in_nagios(self, cluster_id, changed_node, state):

        name = ''
        for key in changed_node:
            name = key
            for role in changed_node[key]:
                name += '_'+role

        driver = plugin_ui.get_driver("http://{0}:{1}@{2}:8001".format(
                self._nagios_user, self._nagios_password, self.get_alerting_ip(cluster_id)), "//frame[2]")
        driver = plugin_ui.get_hosts_page(driver)
        asserts.assert_equal(state, plugin_ui.node_is_present(driver, name))

        driver.close()

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
    def deploy_lma_infra_alerting(self):
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

        self.check_run('deploy_lma_alerting_plugin')

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

        self.env.make_snapshot("deploy_lma_alerting_plugin", is_make=True)

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
        Snapshot deploy_lma_alerting_plugin_ha
        """

        self.check_run('deploy_lma_alerting_plugin_ha')

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

        logger.info('Making environment snapshot deploy_lma_alerting_plugin_ha')
        self.env.make_snapshot("deploy_lma_alerting_plugin_ha", is_make=True)

    @test(depends_on=[deploy_lma_infra_alerting_plugin_in_ha_mode],
          groups=["add_remove_controller"])
    @log_snapshot_after_test
    def add_remove_controller(self):
        """Add/remove controller nodes in existing environment

        Scenario:
            1.  Remove 1 node with the controller role.
            2.  Re-deploy the cluster.
            3.  Check the plugin services using the CLI
            4.  Check in the Nagios UI that the removed node is no longer monitored.
            5.  Run the health checks (OSTF).
            6.  Add 1 new node with the controller role.
            7.  Re-deploy the cluster.
            8.  Check the plugin services using the CLI.
            9.  Check in the Nagios UI that the new node is monitored.
            10. Run the health checks (OSTF).

        Duration 60m
        """

        self.add_remove_node({'slave-02': ['controller']})
        self.add_remove_node({'slave-04': ['compute', 'cinder']})

    @test(depends_on=[deploy_lma_infra_alerting_plugin_in_ha_mode],
          groups=["add_remove_compute"])
    @log_snapshot_after_test
    def add_remove_compute(self):
        """Add/remove compute nodes in existing environment

        Scenario:
            1.  Remove 1 node with the compute role.
            2.  Re-deploy the cluster.
            3.  Check the plugin services using the CLI
            4.  Check in the Nagios UI that the removed node is no longer monitored.
            5.  Run the health checks (OSTF).
            6.  Add 1 new node with the compute role.
            7.  Re-deploy the cluster.
            8.  Check the plugin services using the CLI.
            9.  Check in the Nagios UI that the new node is monitored.
            10. Run the health checks (OSTF).

        Duration 60m
        """
        self.add_remove_node({'slave-04': ['compute', 'cinder']})

    @test(depends_on=[deploy_lma_infra_alerting_plugin_in_ha_mode],
          groups=["uninstall_deployed_plugin"])
    @log_snapshot_after_test
    def uninstall_deployed_plugin(self):
        """Uninstall the plugins with deployed environment

        Scenario:
            1.  Try to remove the plugins using the Fuel CLI
            2.  Remove the environment.
            3.  Remove the plugins.

        Duration 20m
        """
        self.env.revert_snapshot("deploy_lma_alerting_plugin_ha")

        with self.env.d_env.get_admin_remote() as remote:
            exec_res = remote.execute("fuel plugins --remove {0}=={1}".format(self._name, self._version))
            asserts.assert_equal(1, exec_res['exit_code'], 'Plugin deletion must not be permitted while '
                                                           'it\'s active in deployed in env')
            cluster_id = self.fuel_web.get_last_created_cluster()
            self.fuel_web.delete_env_wait(cluster_id)
            exec_res = remote.execute("fuel plugins --remove {0}=={1}".format(self._name, self._version))
# TODO: plugin deletion has a bug.
            asserts.assert_equal(0, exec_res['exit_code'], 'Plugin deletion failed: {0}'.format(exec_res['stderr']))

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["uninstall_plugin"])
    @log_snapshot_after_test
    def uninstall_plugin(self):
        """Uninstall the plugins

        Scenario:
            1.  Install plugin.
            2.  Remove the plugins.

        Duration 5m
        """
        self.env.revert_snapshot("ready_with_3_slaves")

        self.prepare_plugins(dependencies=False)

        with self.env.d_env.get_admin_remote() as remote:
            exec_res = remote.execute("fuel plugins --remove {0}=={1}".format(self._name, self._version))
# TODO: plugin deletion has a bug.
            asserts.assert_equal(0, exec_res['exit_code'], 'Plugin deletion failed: {0}'.format(exec_res['stderr']))

    @test(depends_on=[base_test_case.SetupEnvironment.prepare_slaves_3],
          groups=["createmirror_deploy_plugin"])
    @log_snapshot_after_test
    def createmirror_deploy_plugin(self):
        """Run fuel-createmirror and deploy environment

        Scenario:
            1.  Copy the plugins to the Fuel Master node and install the plugins.
            2.  Run the following command on the master node:
                    fuel-createmirror
            3.  Create an environment with enabled plugins in the Fuel Web UI and deploy it.
            4.  Run OSTF.

        Duration 60m
        """
        self.env.revert_snapshot("ready_with_3_slaves")

        self.prepare_plugins()

        with self.env.d_env.get_admin_remote() as remote:
            exec_res = remote.execute("fuel-createmirror")
            asserts.assert_equal(0, exec_res['exit_code'], 'fuel-createmirror failed: {0}'.format(exec_res['stderr']))

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

    @test(depends_on=[deploy_lma_infra_alerting],
          groups=["plugin_core_repos_setup"])
    @log_snapshot_after_test
    def plugin_core_repos_setup(self):
        """Fuel-createmirror and setup of core repos

        Scenario:
            1.  Copy the plugins to the Fuel Master node and install the plugins.
            2.  Create an environment with enabled plugin in the Fuel Web UI and deploy it.
            3.  Run OSTF
            4.  Go in cli through controller / compute / storage /etc nodes and get pid of
                services which were launched by plugin and store them.
            5.  Launch the following command on the Fuel Master node:
                    fuel-createmirror -M
            6.  Launch the following command on the Fuel Master node:
                    fuel --env <ENV_ID> node --node-id <NODE_ID1> <NODE_ID2>
                        <NODE_ID_N> --tasks setup_repositories
            7.  Go to controller/plugin/storage node and check if plugin's services are
                alive and aren't changed their pid.
            8.  Check with fuel nodes command that all nodes are remain in ready status.
            9.  Rerun OSTF.

        Duration 60m
        """

        self.env.revert_snapshot("deploy_lma_alerting_plugin")

        origina_pids = self.get_alerting_tasks_pids()


        with self.env.d_env.get_admin_remote() as remote:
            exec_res = remote.execute("fuel-createmirror -M")
# TODO: fuel-createmirror -M will fail during the execution.
            asserts.assert_equal(0, exec_res['exit_code'], 'fuel-createmirror -M failed: {0}'.format(exec_res['stderr']))
            cluster_id = self.fuel_web.get_last_created_cluster()
            cmd = "fuel --env {0} node --node-id 1 2 3 --tasks setup_repositories".format(cluster_id)
            exec_res = remote.execute(cmd)
            asserts.assert_equal(0, exec_res['exit_code'], 'Command {0} failed: {1}'.format(cmd, exec_res['stderr']))

        new_pids = self.get_alerting_tasks_pids()

        error = False
        for node in origina_pids:
            for process in origina_pids[node]:
                if origina_pids[node][process] != new_pids[node][process]:
                    logger.error("Process {0} on node {1} has changed its pid!"
                                 " Was: {2} Now: {3}".format(process,node, origina_pids[node][process],
                                                             new_pids[node][process]))
                    error = True

        asserts.assert_false(error, 'Some processes have changed their pids!')

        with self.env.d_env.get_admin_remote() as remote:
            exec_res = remote.execute("fuel nodes | awk {'print $3'} | grep error")
            asserts.assert_equal(1, exec_res['exit_code'], 'Some nodes are in error state!')
