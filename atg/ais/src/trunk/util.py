#-*- coding: utf-8 -*-
'''
Misc. utilities for AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import datetime
import os.path
import hashlib
import errno
import subprocess as sp
import aws_services
import codecs
from lxml import objectify

LOG = logging.getLogger('AIS')

#######################################################
# File handling                                       #
#######################################################
def write_meta_files(client=None, path=None):
    '''
    Writes a report of methods and types found in WSDL
    and also writes the WSDL itself to file
    '''
    wsdl_file = 'ais_wsdl.xml'
    method_file = 'ais_methods.txt'
    
    LOG.info('Writing meta files')
    filepath = os.path.join(path, wsdl_file)
    filepath = os.path.normpath(filepath)
    try:
        filehandle = open(filepath, 'w')
        filehandle.write(str(client.wsdl))
    except IOError:
        LOG.exception()
    except:
        LOG.exception('Unexpected error!')
    finally:
        filehandle.close()

    filepath = os.path.join(path, method_file)
    filepath = os.path.normpath(filepath)
    try:
        filehandle = open(filepath, 'w')
        filehandle.write(str(client))
    except IOError:
        LOG.exception()
    except:
        LOG.exception('Unexpected error!')
    finally:
        filehandle.close()

def write_file(data=None, filepath=None, encoding=None):
    '''
    Write a file (with encoding if stated)
    '''
    filename = os.path.basename(filepath)
    LOG.info('Writing file ' + filename)
    if not os.path.exists(filepath):
        try:
            filehandle = codecs.open(filepath, encoding=encoding, mode='w')
            filehandle.write(str(data))
        except IOError:
            LOG.exception()
        except:
            LOG.exception('Unexpected error!')
        finally:
            filehandle.close()
    else:
        LOG.info('Could not write file ' + filename + 
                 ' (file already exist)')

def read_file(filepath=None, encoding=None):
    '''
    Read a file (with encoding if stated)
    '''
    filename = os.path.basename(filepath)
    result = None
    if os.path.exists(filepath):
        LOG.info('Reading file ' + filename)
        filehandle = None
        try:
            filehandle = codecs.open(filepath, encoding=encoding)
            result = filehandle.read()
        except IOError:
            LOG.exception()
        except:
            LOG.exception('Unexpected error!')
        finally:
            filehandle.close()
    else:
        LOG.info('Could not read file ' + filename + 
                 ' (file does not exist)')
    return result

def generate_file_name(datadir=None, ais_service=None,
                       date=None, track=None,
                       ais_version=None, ais_type=None):
    '''
    Generate a dict containing path, filename and 
    filepath (path + filename)
    '''
    result = {'filename':'', 'path':''}
    result['path'] = os.path.normpath(datadir)
    result['filename'] = ais_service
    result['filename'] += '_'
    result['filename'] += date_to_string(date)
    result['filename'] += '_'
    result['filename'] += str(track)
    result['filename'] += '_'
    result['filename'] += ais_version
    result['filename'] += '_'
    result['filename'] += ais_type
    result['filename'] += '.xml'
    return result

def list_files(dir_path=None):
    '''
    List filenames in a directory
    '''
    file_list = None
    try:
        file_list = os.listdir(dir_path)
    except IOError:
        LOG.exception()
    except:
        LOG.exception('Unexpected error!')
    return file_list

def list_files_with_path(dir_path=None):
    '''
    List file paths to files in a directory
    '''
    file_name_list = list_files(dir_path)
    file_path_list = []
    for file_name in file_name_list:
        file_name = os.path.join(dir_path, file_name)
        file_name = os.path.normpath(file_name)
        file_path_list.append(file_name)
    return file_path_list

def list_files_sorted_creation(dir_path=None):
    '''
    List files in directory sorted on creation time
    '''
    file_path_list = list_files_with_path(dir_path=dir_path)
    file_date_tuple_list = [(x, os.path.getctime(x)) for x in file_path_list]
    file_date_tuple_list.sort(key=lambda x: x[1])
    file_paths = []
    for file_tuple in file_date_tuple_list:
        file_paths.append(file_tuple[0])
    return file_paths

def file_md5(file_path=None):
    '''
    Calculate the md5 checksum for a file and return the 
    result as a hexadecimal string
    '''
    try:
        checksum = hashlib.md5(open(file_path, 'rb').read()).hexdigest()
    except IOError:
        LOG.exception('Could not open file ' + file_path)
    return checksum

def file_list_md5(dir_path=None):
    '''
    Return a list of files with their md5 checksums from a directory
    '''
    file_list = list_files_with_path(dir_path=dir_path)
    # pylint: disable=E1101
    file_md5_list = [
        (file_path, file_md5(file_path))
        for file_path in file_list
    ]
    return file_md5_list

def create_directories(dirs=None):
    for cdir in dirs:
        try:
            os.makedirs(cdir)
        except OSError as exception:
            if exception.errno != errno.EEXIST:
                raise

# Compiling regexp on global level for performance
import re
CLEANXML_1 = re.compile(ur'<\?.*?\?>\n')
CLEANXML_2 = re.compile(ur'(</{0,1}).+?:')
CLEANXML_3 = re.compile(ur'\Wxsi:.*?=".*?"')

def clean_xml_namespaces(xmlfile=None, savename=None):
    '''
    Removes namespace data in xml file
    '''
    xml = read_file(xmlfile, encoding='utf-8')
    xml = CLEANXML_1.sub(ur'', xml, count=1)
    xml = CLEANXML_2.sub(ur'\1', xml)
    xml = CLEANXML_3.sub(ur'', xml)
    if savename:
        filehandle = open(savename, 'w')
        filehandle.write(xml)
        filehandle.close()
    return xml

def get_filename_from_path(path=None):
    return os.path.basename(path)

def create_file_path(path=None, filename=None):
    filepath = os.path.join(path, filename)
    filepath = os.path.normpath(filepath)
    return filepath
    
#######################################################
# AIS struct and date/time conversions                #
#######################################################
def strings_to_date(year=None, month=None, date=None):
    '''
    Converts string parts to a date object
    '''
    date = datetime.datetime(
        int(year), 
        int(month), 
        int(date)
    )
    return date

def date_to_struct(client, date):
    '''
    Converts a date object to a AtgDate struct
    '''
    struct = client.factory.create('ns4:AtgDate')
    struct['year'] = date.year
    struct['month'] = date.month
    struct['date'] = date.day
    return struct

def struct_to_time(time_struct):
    '''
    Converts string parts to a time object
    '''
    time = datetime.time(time_struct.hour, 
                         time_struct.minute, 
                         time_struct.second, 
                         time_struct.tenth * 100000)
    return time

def params_to_datetime(year=None, month=None, day=None, hour=None, 
                       minute=None, second=None, tenth=None):
    '''
    Converts parameters to a datetime object
    '''
    result = datetime.datetime(
        year = year,
        month = month,
        day = day,
        hour = hour,
        minute = minute,
        second = second,
        microsecond = tenth * 10000 
    )
    return result

def date_to_string(date_time):
    '''
    Return a string representation of a 
    datetime object, e.g. '20130105'
    '''
    return date_time.strftime('%Y%m%d')

def date_to_string2(date_time):
    '''
    Return a string representation of a 
    datetime object, e.g. '2013-01-05'
    '''
    return date_time.strftime('%Y-%m-%d')

def get_current_date():
    '''
    Get current date object
    '''
    return datetime.datetime.now()
    
def track_id_to_struct(client, track_id):
    '''
    Converts a track_id to a TrackKey struct
    '''
    struct = client.factory.create('ns3:TrackKey')
    struct['trackId'] = track_id
    return struct

#######################################################
# Database handling                                   #
#######################################################
def save_db_dump_in_cloud(dbname=None, dumpdir=None, bucketname=None, 
                          host=None, username=None, password=None):
    '''
    Run commands to create db dump directory and generating 
    a db dump into it. Finally the dump is uploaded to the cloud.
    '''
    create_directories(dirs=[dumpdir])
    chmod_bin = '/bin/chmod'
    sudo_bin = '/usr/bin/sudo'
    su_bin = '/bin/su'
    pg_dump_bin = '/usr/bin/pg_dump'
    pg_dump_format = '-Fc' # Custom (compressed) format
    db_superuser = 'postgres'
    chmod_command = [chmod_bin, '777', dumpdir]
    proc = sp.Popen(chmod_command, stdout=sp.PIPE, stderr=sp.PIPE)
    error = proc.communicate()[1]
    filepath = None
    if not error:
        filepath = os.path.join(dumpdir, dbname + '.backup')
        filepath = os.path.normpath(filepath)
        dump_command = [
            sudo_bin, su_bin, '-', '-c',
            pg_dump_bin + ' ' + pg_dump_format + ' ' + dbname + '>' + \
            filepath, db_superuser
        ]
        proc = sp.Popen(dump_command, stdout=sp.PIPE, stderr=sp.PIPE)
        error = proc.communicate()[1]
        if error:
            LOG.error(
                'Need sudo rights without password.\n' +
                'E.g. "ubuntu ALL=(ALL) NOPASSWD:ALL" in /etc/sudoers. ' +
                'Use command visudo.'
            )
            LOG.error(error)
    else:
        LOG.error(error)
    if not error:
        aws_services.save_files_in_aws_s3_bucket(
            sourcefiles=[filepath],
            bucketname=bucketname,
            versioning=False,
            replace=True,
            host=host,
            username=username,
            password=password
        )

#######################################################
# Email (SMTP) handling                               #
#######################################################
def email_log_stats_and_errors(logdir=None, logfile=None, datadir=None,
                               subject=None, username=None, password=None,
                               from_address=None, send_list=None):
    '''
    Send an email after e.g. EOD download with stats 
    and errors if any.
    '''
    curr_date = date_to_string2(get_current_date())
    filepath = create_file_path(path=logdir, filename=logfile)
    log = read_file(filepath)
    # If logging framework has rotated logs (created history) during last run,
    # we have to look in '.1' as well
    log_hist = read_file(filepath + '.1')

    log_collection = []
    if log_hist:
        log_collection.append(log_hist)
    log_collection.append(log)
    write_count = 0
    error_count = 0
    for log_content in log_collection:
        for row in log_content.split('\n'):
            if curr_date in row:
                if 'Writing' in row:
                    write_count += 1
                if 'ERROR' in row:
                    error_count += 1
    nbr_of_data_files = len(list_files(datadir))
    subject = subject + ' ' + curr_date
    body = 'Number of written files: %d' % (write_count)
    body += '\n'
    body += 'Number of errors: %d' % (error_count)
    body += '\n'
    body += 'Total number of data files: %d' % (nbr_of_data_files)
    aws_services.send_ses_email(
        username=username,
        password=password,
        from_address=from_address,
        subject=subject,
        body=body,
        send_list=send_list
    )

#######################################################
# Xml parser implementation                           #
#######################################################
def get_xml_object(filepath=None):
    xml = clean_xml_namespaces(filepath)
    xml_object = objectify.fromstring(xml)
    return xml_object
