import requests
import json


def post(URL, data, headers):
    response = requests.post(URL, data=json.dumps(data), headers=headers)
    return response


def get(URL, headers):
    response = requests.get(URL, headers=headers)
    return response
