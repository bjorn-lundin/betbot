from io import BytesIO
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import json
import requests



#hostName = "localhost"
hostName = ""
serverPort = 8080

#########################################################################


class MyServer(BaseHTTPRequestHandler):

    def do_POST(self):
        content_length = int(self.headers['Content-Length'].strip()) # <--- Gets the size of data
        post_data = self.rfile.read(content_length) # <--- Gets the data itself
        #logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
        #        str(self.path), str(self.headers), post_data.decode('utf-8'))

        parsed_json = json.loads(post_data)
        #print(json.dumps(parsed_json, indent=4, sort_keys=True))

        self.send_response(200)
        self.end_headers()

        response = BytesIO()
        if self.do_bet :
            response.write(bytes(str("1"), "utf-8"))
        else:
            response.write(bytes(str("0"), "utf-8"))

        self.wfile.write(response.getvalue())


#payload = 'username=bnlbnl&password=@Bf@vinst@1'
#headers = {'X-Application': 'SomeKey', 'Content-Type': 'application/x-www-form-urlencoded'}

        resp = requests.post('https://identitysso-cert.betfair.se/api/certlogin',
                             data=post_data,
                             cert=('client-2048.crt', 'client-2048.key'),
                             headers=self.headers)

        if resp.status_code == 200:
           resp_json = resp.json()
           print(resp_json['loginStatus'])
           print(resp_json['sessionToken'])
        else:
           print("Request failed.")

##############################################################


webServer = HTTPServer((hostName, serverPort), MyServer)
print("Server started http://%s:%s" % (hostName, serverPort))

logging.basicConfig(level=logging.DEBUG)


try:
   webServer.serve_forever()
except KeyboardInterrupt:
   pass

webServer.server_close()
print("Server stopped.")

