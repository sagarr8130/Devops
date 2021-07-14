import json
import requests

rs_token = 'dec3b3db4701b089eca58cae86c071f068c426d4'
URL = 'https://us-4.rightscale.com/api/oauth2'

headers = {'X-API-Version': '1.5',
           'Content-Type': 'application/json'}

data = {'grant_type': 'refresh_token',
        'refresh_token': rs_token
        }

r = requests.post(URL, data=json.dumps(data), headers=headers)
token = json.loads(r.content)["access_token"]
