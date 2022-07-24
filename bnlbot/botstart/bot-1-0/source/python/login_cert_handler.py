from io import BytesIO
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import json
import requests
import os
import os.path

#hostName = "localhost"
hostName = ""
serverPort = 12345

#########################################################################


class MyServer(BaseHTTPRequestHandler):

    def do_POST(self):

      if self.path == '/certlogin':

        content_length = int(self.headers['Content-Length'].strip()) # <--- Gets the size of data
        post_data_raw = (self.rfile.read(content_length)) # <--- Gets the data itself
        #logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
        #        str(self.path), str(self.headers), post_data.decode('utf-8'))

        #payload = 'username=bnlbnl&password=@Bf@vinst@1'

#        print('headers',self.headers)

        post_data = post_data_raw.decode("utf-8")
        logging.info('post_data %s',post_data)

        user =''
        if 'bnlbnl' in post_data:
          user = 'bnl'
        elif 'joakimbirgerson' in post_data:
          user = 'jmb'
        elif 'Grappe' in post_data:
          user = 'msm'


        cert_path_prefix = os.getenv('BOT_START')
        if cert_path_prefix is None :
           cert_path_prefix = '/bnlbot/botstart'

        cert_path = cert_path_prefix + '/user/' + user + '/certificates'


        if not os.path.exists(cert_path + '/client-2048.crt') :
           self.send_response(200)
           self.end_headers()
           response = BytesIO()
           response.write(b'Post request error')
           self.wfile.write(response.getvalue())
           logging.warning("Post request error")
           logging.warning('no certfile found')
           return



        logging.info('user %s', user)
        logging.info('cert_path %s', cert_path)

        headers = {'X-Application': self.headers['X-Application'],
           'Content-Type': self.headers['Content-Type'],
           'Accept': self.headers['Accept'],
           'User-Agent': self.headers['User-Agent']}

        resp = requests.post('https://identitysso-cert.betfair.se/api/certlogin',
                             data=post_data,
                             cert=(cert_path + '/client-2048.crt', cert_path + '/client-2048.key'),
                             headers=headers)

        self.send_response(200)
        self.end_headers()

        if resp.status_code == 200:
           resp_json = resp.json()
           logging.info('resp_json %s', resp_json)

           response = BytesIO()
           response.write(bytes(json.dumps(resp_json), "utf-8"))
           self.wfile.write(response.getvalue())

        else:
           response = BytesIO()
           response.write(b'Post request error')
           self.wfile.write(response.getvalue())
           logging.warning("Post request error")
           logging.warning('resp_json', resp_json)

      else:
        response = BytesIO()
        response.write(b'bad url')
        self.send_response(500)
        logging.error('Bad url %s', self.path)

##############################################################


webServer = HTTPServer((hostName, serverPort), MyServer)
print("Server started http://%s:%s" % (hostName, serverPort))

logging.basicConfig(filename='/bnlbot/bnlbot/botstart/bot-1-0/target/log/python_login_service.log', level=logging.INFO,format='%(asctime)s %(message)s')

pid = os.getpid()
print('pid',pid)

with open("/bnlbot/bnlbot/botstart/bot-1-0/target/befair_logon_daemon.pid", "w") as file1:
    # Writing data to a file
    file1.write(str(pid) + "\n")

try:
   webServer.serve_forever()
except KeyboardInterrupt:
   pass

webServer.server_close()
print("Server stopped.")

