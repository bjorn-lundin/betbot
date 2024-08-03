from io import BytesIO
from http.server import BaseHTTPRequestHandler, HTTPServer
import logging
import json
import requests
import os
import os.path
import numpy
import pickle
import sys




#hostName = "localhost"
hostName = ""
serverPort = 12345

#########################################################################

# neural network class definition
class neuralNetwork:


    # initialise the neural network
    def __init__(self, inputnodes, hiddennodes, outputnodes, learningrate):
        # set number of nodes in each input, hidden, output layer
        self.inodes = inputnodes
        self.hnodes = hiddennodes
        self.onodes = outputnodes

        # link weight matrices, wih and who
        # weights inside the arrays are w_i_j, where link is from node i to node j in the next layer
        # w11 w21
        # w12 w22 etc
        self.wih = numpy.random.normal(0.0, pow(self.inodes, -0.5), (self.hnodes, self.inodes))
        self.who = numpy.random.normal(0.0, pow(self.hnodes, -0.5), (self.onodes, self.hnodes))
        # learning rate
        self.lr = learningrate

        # activation function is the sigmoid function
        #self.activation_function = lambda x: scipy.special.expit(x)
        self.activation_function = scipy.special.expit
    ###################### end __init__ ###############################################

    # train the neural network
    def train(self, inputs_list, targets_list):
        # convert inputs list to 2d array
        inputs = numpy.array(inputs_list, ndmin=2).T
        targets = numpy.array(targets_list, ndmin=2).T

        # calculate signals into hidden layer
        hidden_inputs = numpy.dot(self.wih, inputs)
        # calculate the signals emerging from hidden layer
        hidden_outputs = self.activation_function(hidden_inputs)

        # calculate signals into final output layer
        final_inputs = numpy.dot(self.who, hidden_outputs)
        # calculate the signals emerging from final output layer
        final_outputs = self.activation_function(final_inputs)

        # output layer error is the (target - actual)
        output_errors = targets - final_outputs
        # hidden layer error is the output_errors, split by weights, recombined at hidden nodes
        hidden_errors = numpy.dot(self.who.T, output_errors)

        # update the weights for the links between the hidden and output layers
        self.who += self.lr * numpy.dot((output_errors * final_outputs * (1.0 - final_outputs)), numpy.transpose(hidden_outputs))

        # update the weights for the links between the input and hidden layers
        self.wih += self.lr * numpy.dot((hidden_errors * hidden_outputs * (1.0 - hidden_outputs)), numpy.transpose(inputs))

    ###################### end train ###############################################

    # query the neural network
    def query(self, inputs_list):
        # convert inputs list to 2d array
        inputs = numpy.array(inputs_list, ndmin=2).T

        # calculate signals into hidden layer
        hidden_inputs = numpy.dot(self.wih, inputs)
        # calculate the signals emerging from hidden layer
        hidden_outputs = self.activation_function(hidden_inputs)

        # calculate signals into final output layer
        final_inputs = numpy.dot(self.who, hidden_outputs)
        # calculate the signals emerging from final output layer
        final_outputs = self.activation_function(final_inputs)

        return final_outputs

    ###################### end query ###############################################

###################### end class nn ################################################


#############################

class MyServer(BaseHTTPRequestHandler):

    def do_treat_ai_request(self, post_data) :
        #BASE = os.environ['BOT_TARGET']  no bot env here
        BASE = '/bnlbot/bnlbot/botstart/bot-1-0/target'
        # get the JSON into dict
#        print('post_data',post_data)
        rpc = json.loads(post_data)

#        print('json-loads',rpc)
#        print('json-loads input', rpc['params']['input'])

        params = rpc['params']

        # interpret what pickle to load

        pickle_file_root = BASE + '/pickles'
        pickle_file =  "/" + params['betType']
        pickle_file += "/" + params['side']
        pickle_file += '/' + str(params['hiddenNodes'])
        pickle_file += '_' + str(params['learningRate'])
        pickle_file += '_' + str(params['numFromLeader'])
        pickle_file += '_' + str(params['epochs'])
        pickle_file += '.p'

        pickle_file = pickle_file_root + pickle_file

        n = None
        try :
            # read into n
            with open( pickle_file, "rb" ) as f:
                n = pickle.load(f)
                logging.info("Loaded pickle file: %s\n", pickle_file)

        except  :
            # Get current system exception
            ex_type, ex_value, ex_traceback = sys.exc_info()
            logging.warning("Exception type : %s " % ex_type.__name__)
            logging.warning("Exception message : %s" %ex_value)

            resp = {}
            resp['method'] = rpc['method']
            resp['id'] = rpc['id']
            resp['jsonrpc'] = rpc['jsonrpc']
            error = {}
            error['code'] = 2
            error['message'] = str(ex_type.__name__) + ' - ' + str(ex_value)
            resp['error'] = error
            return json.dumps(resp, indent = 4)
        ##############do not continue if error ########################


        inputs = (numpy.asfarray(params['input']) / 1000.0 * 0.99) + 0.01
        logging.info("input: %s\n", inputs)

        # ask n with input arrays (as numpy array)
        outputs = n.query(inputs)
        logging.info("output: %s\n", outputs)

        num_from_leader = params['numFromLeader']

        label = -1
        if num_from_leader > 0 :
            cnt = num_from_leader
            while cnt > 0 :
                #remove the current leader and go for next
#                print('cnt',cnt)
                label = numpy.argmax(outputs)
#                print('reset label',label,' was outputs[label]' ,outputs[label])
                outputs[label] = 0.01
                cnt = cnt -1

            label = numpy.argmax(outputs)
#            print('label_', label, 'outputs[label]', outputs[label])


        elif num_from_leader == 0 :
            # the index of the highest value corresponds to the label
            label = numpy.argmax(outputs)
#            print('label0', label, 'outputs[label]', outputs[label])


#        print('return', label, 'outputs[label]', outputs[label])
#        print('outputs', outputs)
        logging.info("output: %s\n", outputs)

        # create json response (as dict)
        resp = {}
        resp['method'] = rpc['method']
        resp['id'] = rpc['id']
        resp['jsonrpc'] = rpc['jsonrpc']
        result = {}
        result['comment'] = "valid bestRunner index is 0-15"
        result['bestRunner'] = int(label)
        resp['result'] = result
        # return json response
        return json.dumps(resp, indent = 4)


################### end do_treat_ai_request ####################3


    def do_POST(self):


      if self.path == '/certlogin':

        content_length = int(self.headers['Content-Length'].strip()) # <--- Gets the size of data
        post_data_raw = (self.rfile.read(content_length)) # <--- Gets the data itself

        #payload = 'username=bnlbnl&password=@Bf@vinst@1'

        post_data = post_data_raw.decode("utf-8")

        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
              str(self.path), str(self.headers), post_data)

        user =''
        if 'bnlbnl' in post_data:
          user = 'bnl'
        elif 'joakimbirgerson' in post_data:
          user = 'jmb'
        elif 'Grappe' in post_data:
          user = 'msm'


        cert_path_prefix = os.getenv('BOT_START')
        if cert_path_prefix is None :
           cert_path_prefix = '/bnlbot/bnlbot/botstart'

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

      elif self.path == '/AI':
        # get the request from the betbot
        content_length = int(self.headers['Content-Length'].strip()) # <--- Gets the size of data
        post_data_raw = (self.rfile.read(content_length)) # <--- Gets the data itself
        post_data = post_data_raw.decode("utf-8")

        logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
              str(self.path), str(self.headers), post_data)

        ai_response = self.do_treat_ai_request(post_data)

        response = BytesIO()
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        response.write(bytes(ai_response, "utf-8"))
        self.wfile.write(response.getvalue())

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

