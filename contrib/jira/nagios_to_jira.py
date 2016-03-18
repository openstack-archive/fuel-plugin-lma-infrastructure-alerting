#!/usr/bin/python

import argparse
import json
import logging
import requests
import socket
import sys

from logging.handlers import SysLogHandler


def _enable_http_debug():
    try:
        import http.client as http_client
    except ImportError:
        # Python 2
        import httplib as http_client
        http_client.HTTPConnection.debuglevel = 1


LOG = None
_SESSION = None


def get_session(config):
    global _SESSION
    if not _SESSION:
        session = requests.Session()
        session.mount(
            'http://', requests.adapters.HTTPAdapter(max_retries=2))
        session.mount(
            'https://', requests.adapters.HTTPAdapter(max_retries=2))

        session.auth = (config.user, config.password)
        session.headers.update({'Content-Type': 'application/json'})
        _SESSION = session
    return _SESSION


def _get_labels(conf):
    labels = []
    if conf.service:
        labels.append('service_notification')
        labels.append(conf.service.lower().replace(' ', '_'))
    else:
        labels.append('host_notification')
    labels.append(conf.host.lower().replace(' ', '_'))
    return labels


def create_issue(conf):
    labels = [conf.host]
    if conf.service:
        labels.append(conf.service)

    post_data = {
        "fields": {
            "project": {"key": conf.key},
            "summary": conf.title,
            "description": conf.description,
            "issuetype": {"id": conf.issue},
            "labels": _get_labels(conf),
        }
    }

    session = get_session(conf)
    r = session.post(
        ''.join([conf.endpoint, 'issue/']), data=json.dumps(post_data)
    )
    if r.status_code not in (200, 201):
        LOG.error("Cannot create issue: HTTP {}".format(r.status_code))
        LOG.error(r.text)


def get_issue(conf):
    session = get_session(conf)
    JQL = '{} AND status not in (Done)'.format(
        ' AND '.join(['labels = "{}"'.format(l) for l in _get_labels(conf)])
    )
    LOG.debug('JQL: {}'.format(JQL))
    search = {
        'jql': JQL,
        'startAt': 0,
        'maxResults': 1,
        'fields': ['status'],
    }
    r = session.post(''.join(
        [conf.endpoint, 'search']), data=json.dumps(search)
    )
    LOG.debug(r.text)
    if r.status_code not in (200, 201):
        LOG.error("Cannot get issue: HTTP {}".format(r.status_code))
        LOG.error(r.text)
        return None

    try:
        res = r.json()
        if len(res['issues']) > 0:
            LOG.info("Issue found {}".format(JQL))
            return res['issues'][0]
        LOG.info("Issue not found {}".format(JQL))
    except Exception as e:
        LOG.error("Fail to load JSON: {}".format(r.text))
        LOG.error(str(e))


def update_issue(conf, issue):
    # To get editable fields
    # endpoint = ''.join(
    #     [conf.endpoint, 'issue/{}/editmeta'.format(issue['id'])])
    # r = session.get(endpoint)

    session = get_session(conf)
    if conf.transition and conf.notification == 'RECOVERY':
        endpoint = ''.join(
            [conf.endpoint, 'issue/{}/transitions'.format(issue['id'])]
        )
        LOG.info('Update transition to indicate RECOVERY stat')
        update = {
            'transition': {'id': conf.transition}
        }
        # To get transition ids
        # transition_endpoint = ''.join(
        #    [conf.endpoint, 'issue/{}/transitions'.format(issue['id'])])
        # r = session.get(transition_endpoint)
        # LOG.info(r.text)
        r = session.post(endpoint, data=json.dumps(update))
        if r.status_code != 204:
            LOG.info('The transition seems to be already set to {}'.format(
                conf.transition)
            )
            LOG.debug(r.text)

    LOG.info('Add a comment')
    endpoint = ''.join([conf.endpoint, 'issue/{}/comment'.format(issue['id'])])
    update = {
        'body': conf.description,
    }
    r = session.post(endpoint, data=json.dumps(update))
    LOG.debug(r.text)

if __name__ == "__main__":

    LOG = logging.getLogger()

    cmd = argparse.ArgumentParser(description="Jira ticket")
    cmd.add_argument('--debug', default=False, action='store_true',
                     help='Enable debug log level')
    cmd.add_argument('--syslog', action='store_true', default=False,
                     help='The logfile name')
    cmd.add_argument('-k', '--key', required=True, help='Project key')
    cmd.add_argument('-e', '--endpoint', required=True,
                     help='Jira API endpoint')
    cmd.add_argument('-u', '--user', required=True, help='User')
    cmd.add_argument('-p', '--password', required=True, help='Password')
    cmd.add_argument('-i', '--issue', default=3, type=int, help='Issue type')
    cmd.add_argument('-t', '--title', required=True, help='Summary')
    cmd.add_argument('-d', '--description', required=True,
                     help='Description (use "-" to use stdin')
    cmd.add_argument('-H', '--host', required=True, help='Host name')
    cmd.add_argument('-s', '--service', required=False, help='Service name')
    cmd.add_argument('-N', '--notification', required=True,
                     help='Notification type (PROBLEM|RECOVERY|CUSTOM)')
    # cmd.add_argument('-S', '--state', required=True,
    #                  help='State (OK|WARNING|CRITICAL|DOWN|UNKNOWN)')
    cmd.add_argument(
        '-T', '--transition', required=False, type=int,
        help='Update transition of the open issue if the notification is a '
             'RECOVERY. Use rest API to find your transition ID '
             '/rest/api/2/issue/154990/transitions')
    try:
        conf = cmd.parse_args()
    except Exception as e:
        LOG.error(e)
        raise

    if conf.syslog:
        handler = SysLogHandler()
    else:
        handler = logging.StreamHandler()

    if conf.debug:
        log_level = logging.DEBUG
        _enable_http_debug()
        requests_log = logging.getLogger("requests.packages.urllib3")
        requests_log.setLevel(log_level)
        requests_log.propagate = True
    else:
        log_level = logging.INFO

    formatter = logging.Formatter(
        '{} nagios_to_jira %(asctime)s %(process)d %(levelname)s %(name)s '
        '[-] %(message)s'.format(socket.getfqdn()),
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    handler.setFormatter(formatter)
    LOG.setLevel(log_level)
    LOG.addHandler(handler)

    if conf.description == '-':
        conf.description = ''.join(sys.stdin.readlines())
    issue = get_issue(conf)
    if issue:
        LOG.info('Update issue {} for Host {}'.format(issue['id'], conf.host))
        update_issue(conf, issue)
    else:
        LOG.info('Create new issue for Host {}'.format(conf.host))
        create_issue(conf)
