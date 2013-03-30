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

def write_file(result=None, file_name_dict=None):
    '''
    Write a file
    '''
    LOG.info('Writing file ' + file_name_dict['filename'])
    filepath = os.path.join(file_name_dict['path'], 
                            file_name_dict['filename'])
    try:
        filehandle = open(filepath, 'w')
        filehandle.write(str(result))
    except IOError:
        LOG.exception()
    except:
        LOG.exception('Unexpected error!')
    finally:
        filehandle.close()

def read_file(file_name_dict=None):
    '''
    Read a file
    '''
    result = None
    filepath = os.path.join(file_name_dict['path'], 
                            file_name_dict['filename'])
    if os.path.exists(filepath):
        LOG.info('Reading file ' + file_name_dict['filename'])
        try:
            filehandle = open(filepath, 'r')
            result = filehandle.read()
        except IOError:
            LOG.exception()
        except:
            LOG.exception('Unexpected error!')
        finally:
            filehandle.close()
    else:
        LOG.info('Could not read file ' + file_name_dict['filename'] + 
                 ' (file does not exist)')
    return result

def generate_file_name(datadir = None, ais_service = None,
                       date = None, track=None,
                       ais_version = None, ais_type = None):
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
    
#######################################################
# AIS struct and date/time conversions                #
#######################################################
def struct_to_date(date_struct):
    '''
    Converts string parts to a date object
    '''
    date = datetime.datetime(
        date_struct.year, 
        date_struct.month, 
        date_struct.date
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

def struct_to_datetime(datetime_struct):
    '''
    Converts string parts to a datetime object
    '''
    date_str = str(datetime_struct.date.year) \
        + '-' + str(datetime_struct.date.month) \
        + '-' + str(datetime_struct.date.date)
    date = datetime.datetime.strptime(date_str, "%Y-%m-%d")
    
    time = datetime.time(
        datetime_struct.time.hour,
        datetime_struct.time.minute,
        datetime_struct.time.second
    )
    _datetime = datetime.datetime.combine(date, time)
    return _datetime

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
