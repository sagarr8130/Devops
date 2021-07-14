from api import api

headers = {'X-API-Version': '1.5',
           'Content-Type': 'application/json'}


def authn_to_RS(RS_URL, rs_token):
    data = {'grant_type': 'refresh_token',
            'refresh_token': rs_token
            }
    OA_URL = RS_URL + 'api/oauth2'
    br_token = api.post(OA_URL, data, headers)
    return br_token
