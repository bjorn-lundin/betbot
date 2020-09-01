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

      if self.path == '/certlogin':

        content_length = int(self.headers['Content-Length'].strip()) # <--- Gets the size of data
        post_data_raw = (self.rfile.read(content_length)) # <--- Gets the data itself
        #logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
        #        str(self.path), str(self.headers), post_data.decode('utf-8'))

       # parsed_json = json.loads(post_data)
        #print(json.dumps(parsed_json, indent=4, sort_keys=True))

        self.send_response(200)
        self.end_headers()

        post_data = post_data.decode("utf-8")
        print('headers',self.headers)
        print('data',post_data)


#payload = 'username=bnlbnl&password=@Bf@vinst@1'
        headers = {'X-Application': self.headers['X-Application'],
           'Content-Type': self.headers['Content-Type'],
           'Accept': self.headers['Accept'],
           'User-Agent': self.headers['User-Agent']}

        resp = requests.post('https://identitysso-cert.betfair.se/api/certlogin',
                             data=post_data,
                             cert=('client-2048.crt', 'client-2048.key'),
                             headers=headers)

        if resp.status_code == 200:
           resp_json = resp.json()
           print(resp_json)

           response = BytesIO()
           response.write(bytes(json.dumps(resp_json), "utf-8"))
           self.wfile.write(response.getvalue())

        else:
           print("Request failed.")
           print(json.dumps(resp_json))

      else:
        response = BytesIO()
        response.write(bytes(str("bad url"), "utf-8"))
        self.send_response(500)


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

