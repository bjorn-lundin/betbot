import requests
import json

endpoint = "https://beta-api.betfair.com/rest/v1.0/"

header = { 'X-Application' : 'JYheFAFiOMVSIYEw', 'X-Authentication' : '79Zzpw2pQclogPFJk2YlgwT5bOQxV0Luo97qpZYIEkM=' ,'content-type' : 'application/json' }

json_req='{"filter":{ }}'

url = endpoint + "listEventTypes/"

response = requests.post(url, data=json_req, headers=header)


print json.dumps(json.loads(response.text), indent=3)