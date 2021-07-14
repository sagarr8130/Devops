from bearer import *
import sys

headers = {'X-API-Version': '1.5',
           'Content-Type': 'application/json',
           'Authorization': 'Bearer ' + token}

response = requests.get(
    'https://us-4.rightscale.com/api/deployments', headers=headers)


def deployment_href():
    my_list = []
    for i in (json.loads(response.content)):
        link = i['links']
        for j in link:
            if 'self' in j['rel']:
                my_list.append(j['href'])
    return my_list

deployment_href()

data = {"resource_hrefs": deployment_href()}
tag_response = requests.post(
    'https://us-4.rightscale.com/api/tags/by_resource', headers=headers, json=data)


def tags():
    my_list = []
    for i in (json.loads(tag_response.content)):
        tag = i['tags']
        for j in tag:
            if 'kronos:stack_name' in j['name'] or 'kronos:environment_name' in j['name']:
                my_list.append(j['name'])
    return my_list


a = list([sub.replace('kronos:environment_name=', '').replace(
    'kronos:stack_name=', '') for sub in tags()])
b = list(zip(a[1::2], a[::2]))
my_list = sorted(set(b))

stack_list = []


for i in my_list:
    if i[0] not in stack_list:
        stack_list.append(i[0])

list_of_dictionaries = []


for i in stack_list:
    a = []
    for j in my_list:
        if(j[0] == i):
            a.append(j[1])
    my_dict = {i: a}
    list_of_dictionaries.append(my_dict)


with open(r"E:\Automation\Patch_Manager\API\env.json", "w") as outfile:

    outfile.write(json.dumps(list_of_dictionaries, indent=2))
