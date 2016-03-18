Nagios integration with Jira
============================

Overview
--------

A Jira issue is created for host and service notifications. This is achieved by
using the Jira Rest API.

When an alert notification is triggered, the workflow is the following:

* if no corresponding issue is *open* for the notification:
 * create a new issue with these properties:
  * summary
  * description
  * labels:
    - *host_notification* and *service_notification*
    - hostname (option *-H*)
    - service name (if the notification is related to a service, option *-s*)

* if a corresponding issue is already *open* for the notification (by searching
  one issue with proper labels and not in *done* status):
 * add a comment with the notification content
 * if the notification type is RECOVERY and the transition number is specified (option *-T*)
   * update the Jira workflow transition (eg. "In Progress" or "Done" or whatever you have)


Configuration
-------------

# Copy the Nagios configuration *jira.cfg* in */etc/nagios3/conf.d* directory
# Modify the *jira.cfg* with approriate parameters matching your Jira project::

  usage: nagios_to_jira.py [-h] [--debug] [--syslog] -k KEY -e ENDPOINT -u USER
                         -p PASSWORD [-i ISSUE] -t TITLE -d DESCRIPTION -H
                         HOST [-s SERVICE] -N NOTIFICATION [-T TRANSITION]

  Jira ticket

  optional arguments:
    -h, --help            show this help message and exit
    --debug               Enable debug log level
    --syslog              Log to syslog
    -k KEY, --key KEY     Project key
    -e ENDPOINT, --endpoint ENDPOINT
                          Jira API endpoint
    -u USER, --user USER  User
    -p PASSWORD, --password PASSWORD
                          Password
    -i ISSUE, --issue ISSUE
                          Issue type
    -t TITLE, --title TITLE
                          Summary
    -d DESCRIPTION, --description DESCRIPTION
                          Description (use "-" to use stdin
    -H HOST, --host HOST  Host name
    -s SERVICE, --service SERVICE
                          Service name
    -N NOTIFICATION, --notification NOTIFICATION
                          Notification type (PROBLEM|RECOVERY|CUSTOM)
    -T TRANSITION, --transition TRANSITION
                          Update transition of the open issue if the
                          notification is a RECOVERY. Use rest API to find your
                          transition ID /rest/api/2/issue/{ID}/transitions

# Copy the script *nagios_to_jira.py* into */usr/lib/nagios/plugin* directory
# Restart Nagios::

  # service nagios3 restart
