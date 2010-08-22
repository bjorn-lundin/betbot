import os
import datetime
import codecs

def write_data(datadir, file, data):
    filepath = os.path.join(datadir, file)
    file = codecs.open(filepath, 'w', encoding='utf-8')
    file.write(data)
    file.close

def read_data(datadir, file):
    filepath = os.path.join(datadir, file)
    file = codecs.open(filepath, 'r', encoding='utf-8')
    data = file.read()
    file.close
    return data

def get_files(datadir, file_name_pattern):
    files = []
    datafiles = os.listdir(datadir)
    for datafile in datafiles:
        if datafile.startswith(file_name_pattern):
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
