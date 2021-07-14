import json
import requests
import re
from api import api
from beans.User import RS_URL
from beans.Deployment import Deployment1
from urlextract import URLExtract
import logging

extractor = URLExtract()

logging.basicConfig(filename='app.log', level=logging.DEBUG)


##############################################################################################
# Receives bearer token, environment, release version, service and bearer token from Router  #
# Returns list of Deployment objects                                                         #
##############################################################################################
def get_deployment_details(env, rel_version, service, stack_name, bearer_token):
    logging.info("Fetching Deployment details based on inputs entered")

    URL = RS_URL + "api/tags/by_tag"
    headers = {'X-API-Version': '1.5',
               'Content-Type': 'application/json',
               'Authorization': 'Bearer ' + bearer_token}

    data = {"match_all": "true",
            "resource_type": "deployments",
            "tags": ["kronos:environment_name=" + env,
                     "kronos:shared_service_type=" + service,
                     "kronos:service_version=" + rel_version,
                     "kronos:stack_name=" + stack_name]
            }

    r = requests.post(URL, headers=headers, json=data)
    list_of_name_href = execution_name_selfservice_url(r, bearer_token)
    list_of_dep_objects = separate_out_list(list_of_name_href)
    return list_of_dep_objects


##############################################################################################
# Receives bearer token, list of selected deployments and Right-script name from Router      #
# Executes Right-script on selected deployments                                              #
##############################################################################################
def execute_right_script(list_of_selected_deployments, rs_name, bearer_token):
    logging.info("Executing right script on selected deployments")
    headers = {'X-API-Version': '1.5',
               'Content-Type': 'application/json',
               'Authorization': 'Bearer ' + bearer_token}
    list_of_ins_href = bck_ip(list_of_selected_deployments, headers)

    list_of_rs_response = []

    rs_href = right_script(rs_name, headers)
    if rs_href == "":
        return list_of_rs_response

    data = {"right_script_href": rs_href}

    for bck_ins_href in list_of_ins_href:
        url = bck_ins_href + '/run_executable'
        #        print(url)
        #        rs_href = right_script(rs_name, headers)
        #        data = {"right_script_href": rs_href}
        response = api.post(url, data, headers)
        list_of_rs_response.append(response.status_code)
    #    print(list_of_rs_response)
    return list_of_rs_response


def deployment(r):
    my_list = []
    for i in (json.loads(r.content)):
        if 'tags' in i:
            array_href = i['links']
            for j in array_href:
                if j['rel'] == 'resource':
                    my_list.append('https://us-4.rightscale.com' + j['href'])
    return my_list


def execution_name1(r, headers):
    my_list = []
    for dep_href in deployment(r):
        resp = requests.get(dep_href, headers=headers)
        my_list.append('-'.join(json.loads(resp.content)
                                ["name"].split("-", 3))[:-14])
        my_list.append((json.loads(resp.content)["description"].split(
            "[View in Self-Service]", 1)[1][1:74]))
    return my_list


##############################################################################################
# Helper Methods                                                                             #
##############################################################################################
##############################################################################################
# Receives deployment href api(by_tag) response and bearer token                             #
# Returns list of name and self service url  list = [name, url, name, url ..]                #
##############################################################################################
def execution_name_selfservice_url(response_from_above, bearer_token):
    my_list = []

    headers = {'X-API-Version': '1.5',
               'Content-Type': 'application/json',
               'Authorization': 'Bearer ' + bearer_token}

    for hrefs in deployment_href(response_from_above):
        response = requests.get(hrefs, headers=headers)
        my_list.append(''.join(json.loads(response.content)["name"])[:-14])
        # my_list.append((json.loads(response.content)["description"].split("[View in Self-Service]", 1)[1][1:74]))
        my_list.append(extractor.find_urls(
            json.loads(response.content)["description"]))
    return my_list


##############################################################################################
# Receives response from execution_name_selfservice_url()                                    #
# Returns of deployment href                                                                 #
##############################################################################################
def deployment_href(r):
    my_list = []
    for i in (json.loads(r.content)):
        if 'tags' in i:
            hrefs = i['links']
            for j in hrefs:
                if j['rel'] == 'resource':
                    my_list.append('https://us-4.rightscale.com' + j['href'])
    return my_list


##############################################################################################
# Receives single list of deployment name and url alternatively                              #
# Returns list of deployment objects each having a name and url                              #
##############################################################################################
def separate_out_list(my_list):
    list_of_name = []
    list_of_url = []

    length = len(my_list)
    for i in range(length):
        if i % 2 == 0:
            name = my_list[i]
            list_of_name.append(name)
        else:
            url = my_list[i]
            list_of_url.append(url)

    half_length = len(list_of_name)

    dep_obj_list = []
    for i in range(half_length):
        name = list_of_name[i]
        url = list_of_url[i]
        url_str = url[0]
        obj = Deployment1(name, url_str)
        #        obj = Deployment1(name, url)
        #        dep_obj_list.append(obj)
        dep_obj_list.append(obj.toJSON())
    #        print(type(dep_obj_list))
    return dep_obj_list


##############################################################################################
# Receives Right-script name and headers from execute_right_script method                    #
# Returns H-ref of received Right-script                                                     #
##############################################################################################
def right_script(rs_name, headers):
    rs_href = ""
    logging.info("Fetching Rightscript href details")
    URL = "https://us-4.rightscale.com/api/right_scripts?filter[]=name==" + rs_name
    r = requests.get(URL, headers=headers)

    for i in (json.loads(r.content)):
        if i['name'] == rs_name:
            rs_href = i['links']
            for j in rs_href:
                if j['rel'] == 'self':
                    rs_href = j['href']

    return rs_href


##############################################################################################
#
#
##############################################################################################
def execution_name(r):
    my_list = []
    dep_name_list = []
    dep_url_list = []
    dep_obj_list = []
    for i in (json.loads(r.content)):
        if re.search("^WFM", i['name']):
            my_list.append('-'.join(i['name'].split("-", 3))[:-14])
            dep_name_list.append('-'.join(i['name'].split("-", 3))[:-14])
            my_list.append(i['description'].split(
                "[View in Self-Service]", 1)[1][1:74])
            dep_url_list.append(i['description'].split(
                "[View in Self-Service]", 1)[1][1:74])

    # separating out name and URL lists and creating a list of Deployment objects
    length = len(dep_name_list)
    for i in range(length):
        name = dep_name_list[i]
        url = dep_url_list[i]
        obj = Deployment1(name, url)
        dep_obj_list.append(obj.toJSON())

    return dep_obj_list


def bck_ip(list_of_selected_deployments, headers):
    my_list = []
    for url in bck_array(list_of_selected_deployments, headers):
        resp = requests.get(url, headers=headers)
        for i in (json.loads(resp.content)):
            ip = i['links']
            for j in ip:
                if j['rel'] == 'self':
                    my_list.append('https://us-4.rightscale.com' + j['href'])
    return my_list


def bck_array(list_of_selected_deployments, headers):
    my_list = []
    for url in server_array(list_of_selected_deployments, headers):
        resp = requests.get(url, headers=headers)
        for i in (json.loads(resp.content)):
            if 'fnt' not in i['name']:
                fnt_href = i['links']
                for j in fnt_href:
                    if j['rel'] == 'current_instances':
                        my_list.append(
                            'https://us-4.rightscale.com' + j['href'])
    return my_list


def server_array(list_of_selected_deployments, headers):
    my_list = []
    for deployment in list_of_selected_deployments:
        URL = RS_URL + 'api/deployments?filter[]=name==' + deployment
        r = requests.get(URL, headers=headers)
        for i in (json.loads(r.content)):
            if re.search("^WFM", i['name']):
                array_href = i['links']
                for j in array_href:
                    if j['rel'] == 'server_arrays':
                        my_list.append(
                            'https://us-4.rightscale.com' + j['href'])
    return my_list
