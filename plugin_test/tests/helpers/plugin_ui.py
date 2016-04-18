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

from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.common.keys import Keys

from fuelweb_test import logger
from fuelweb_test import logwrap

delay = 120

@logwrap
def get_driver(nagios_ip, anchor):
    driver = webdriver.Firefox()
    driver.get(nagios_ip)
    WebDriverWait(driver, delay).until(EC.presence_of_element_located((By.XPATH, anchor)))
    assert "Nagios Core" in driver.title
    return driver

@logwrap
def get_hosts_page(driver):
    driver.switch_to.frame(driver.find_element_by_name("side"))
    link = driver.find_element_by_link_text('Hosts')
    link.click()
    driver.switch_to.default_content()
    driver.switch_to.frame(driver.find_element_by_name("main"))
    WebDriverWait(driver, delay).until(EC.presence_of_element_located((By.XPATH, "//table[@class='headertable']")))
    return driver

@logwrap
def node_is_present(driver, name):
    present = False
    rows_number = len(driver.find_elements_by_xpath("/html/body/div[2]/table/tbody/tr[position() > 0]"))
    for ind in xrange(2, rows_number+1):
        node_link = driver.find_element_by_xpath('/html/body/div[2]/table/tbody/tr[{0}]/td[1]/table/'
                                                 'tbody/tr/td[1]/table/tbody/tr/td/a'.format(ind))
        node_link.click()
        WebDriverWait(driver, delay).until(EC.presence_of_element_located((By.XPATH, "//body[@class='extinfo']")))

        node_name = driver.find_element_by_xpath('/html/body/table/tbody/tr/td[2]/div[2]').text
        if name in node_name:
            present = True
            break

        driver.back()

    return present
