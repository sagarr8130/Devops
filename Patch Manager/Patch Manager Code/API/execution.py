from bearer import *
import requests
from urlextract import URLExtract

extractor = URLExtract()
URL = "https://us-4.rightscale.com/api/tags/by_tag"
service = "wfm"
env = "cfn01"
version = "06.08.00"
stack = "kcfn01"

headers = {'X-API-Version': '1.5',
           'Content-Type': 'application/json',
           'Authorization': 'Bearer ' + token}

data = {"match_all": "true",
        "resource_type": "deployments",
        "tags": ["kronos:environment_name=" + env,
                 "kronos:shared_service_type=" + service,
                 "kronos:stack_name=" + stack,
                 "kronos:service_version=" + version]
        }

URL2 = "https://us-4.rightscale.com/api/right_scripts?filter[]=name==hostname"

r = requests.post(URL, headers=headers, json=data)
r2 = requests.get(URL2, headers=headers)


####################################################################################
# deployment_href() return /api/deployments/1404056004                             #
####################################################################################

def deployment_href():
    my_list = []
    for i in (json.loads(r.content)):
        if 'tags' in i:
            hrefs = i['links']
            for j in hrefs:
                if j['rel'] == 'resource':
                    my_list.append('https://us-4.rightscale.com' + j['href'])
    return my_list




####################################################################################
# execution_name_selfservice_url() return Execution Name and Self-Service URL.     #
# This function depends on deployment_href()                                       #
####################################################################################

def execution_name_selfservice_url():
    my_list = []
    for hrefs in deployment_href():
        response = requests.get(hrefs, headers=headers)
        my_list.append(''.join(json.loads(response.content)["name"])[:-14])
        # my_list.append((json.loads(resp.content)["description"].split("[View in Self-Service]", 1)[1][1:74]))
        my_list.append(extractor.find_urls(
            json.loads(response.content)["description"]))
    return my_list


####################################################################################
# bck_array_href() return bck,bgp,api,udm HREFs for WFM                            #
# fnt_array_href() return only fnt HREFs for WFM                                   #
# "/api/deployments/1404056004/server_arrays/494564004"                            #
# This function depends on deployment_href()                                       #
####################################################################################

def bck_array_href():
    my_list = []
    for hrefs in deployment_href():
        response = requests.get(hrefs + '/server_arrays', headers=headers)
        for i in (json.loads(response.content)):
            if 'fnt' not in i['name']:
                bck_href = i['links']
                for j in bck_href:
                    if j['rel'] == 'self':
                        my_list.append(
                            'https://us-4.rightscale.com' + j['href'])
    return my_list


def fnt_array_href():
    my_list = []
    for hrefs in deployment_href():
        response = requests.get(hrefs + '/server_arrays', headers=headers)
        for i in (json.loads(response.content)):
            if 'fnt' in i['name']:
                fnt_href = i['links']
                for j in fnt_href:
                    if j['rel'] == 'self':
                        my_list.append(
                            'https://us-4.rightscale.com' + j['href'])
    return my_list


####################################################################################
# bck_instances_href() return all bck,bgp,api,udm instances HREFs for WFM          #
# fnt_instances_href() return all fnt instances HREFs for WFM                      #
# "/api/clouds/2175/instances/DQ5HMB8O6V61M"                                       #
# This function depends on bck_array_href() & fnt_array_href()                     #
####################################################################################

def bck_instances_href():
    my_list = []
    for hrefs in bck_array_href():
        response = requests.get(hrefs, headers=headers)
        for i in (json.loads(response.content)):
            ip = i['links']
            for j in ip:
                if j['rel'] == 'self':
                    my_list.append('https://us-4.rightscale.com' + j['href'])
    return my_list


def fnt_instances_href():
    my_list = []
    for hrefs in fnt_array_href():
        response = requests.get(hrefs, headers=headers)
        for i in (json.loads(response.content)):
            ip = i['links']
            for j in ip:
                if j['rel'] == 'self':
                    my_list.append('https://us-4.rightscale.com' + j['href'])
    return my_list


####################################################################################
# right_script() which use "URL2" & "r2"                                           #
####################################################################################

def right_script():
    for i in (json.loads(r2.content)):
        if i['name'] == 'hostname':
            rs_href = i['links']
            for j in rs_href:
                if j['rel'] == 'self':
                    return j['href']
