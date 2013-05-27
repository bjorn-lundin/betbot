# login test
import socket

HOST = 'localhost'    # The remote host
PORT = 27123          # The same port as used by the server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))
s.send('user=bnlbnl,pwd=Rebecca1Lundin,productid=82,vendorid=0')
data = s.recv(1024)
s.close()
print 'Received', repr(data)

