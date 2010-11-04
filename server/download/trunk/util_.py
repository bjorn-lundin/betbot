import os
import datetime
import codecs
import gzip

def write_data(datadir, file, data):
    filepath = os.path.join(datadir, file)
    data = data.encode('iso-8859-1')
    file = gzip.open(filepath, 'wb')
    file.write(data)
    file.close
    
def read_data(datadir, file):
    filepath = os.path.join(datadir, file)
    print ('Reading data from ', filepath)
    file = gzip.open(filepath, 'rb')
    data = file.read()
    file.close
    return data.decode('iso-8859-1')

def get_files(datadir, file_name_pattern):
    files = []
    datafiles = os.listdir(datadir)
    for datafile in datafiles:
        if file_name_pattern in datafile:
            files.append(datafile)
    return files

class Logger():
    def __init__(self, logfile):
        self.logfile = logfile
        self.doPrint = True
        self.doLog = True
    def log(self, message):
        timestamp = datetime.datetime.strftime(datetime.datetime.now(),
            "%Y-%m-%d %H:%M") + " : "
        if self.doPrint:
            print(timestamp + message)
        if self.doLog:
            file = open(self.logfile, 'a')
            file.write(timestamp)
            file.write(message + '\n')
            file.close

def current_date():
    return datetime.datetime.strftime(datetime.datetime.now(), "%Y-%m-%d")
