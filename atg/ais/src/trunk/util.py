#-*- coding: utf-8 -*-
'''
Misc. utilities for AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import datetime
import os.path
from boto.s3.connection import S3Connection, Location
from boto.s3.key import Key

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
    LOG.info('Reading file ' + file_name_dict['filename'])
    filepath = os.path.join(file_name_dict['path'], 
                            file_name_dict['filename'])
    try:
        filehandle = open(filepath, 'r')
        result = filehandle.read()
    except IOError:
        LOG.exception()
    except:
        LOG.exception('Unexpected error!')
    finally:
        filehandle.close()
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
    List files in directory
    '''
    file_list = None
    try:
        file_list = os.listdir(dir_path)
    except IOError:
        LOG.exception()
    except:
        LOG.exception('Unexpected error!')
    return file_list

def list_files_sorted_creation(dir_path=None):
    '''
    List files in directory sorted on creation time
    '''
    file_name_list = list_files(dir_path)
    file_paths = []
    for file_name in file_name_list:
        file_name = os.path.join(dir_path, file_name)
        file_name = os.path.normpath(file_name)
        file_paths.append(file_name)
    file_date_tuple_list = [(x, os.path.getctime(x)) for x in file_paths]
    file_date_tuple_list.sort(key=lambda x: x[1])
    file_paths = []
    for file_tuple in file_date_tuple_list:
        file_paths.append(file_tuple[0])
    return file_paths
    
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
    
def track_id_to_struct(client, track_id):
    '''
    Converts a track_id to a TrackKey struct
    '''
    struct = client.factory.create('ns3:TrackKey')
    struct['trackId'] = track_id
    return struct

#######################################################
# AWS storage (S3) and other cloud functions          #
#######################################################
def get_aws_s3_connections(username=None, password=None):
    '''
    Return a S3 connection.
    '''
    LOG.info('Connecting to S3')
    return S3Connection(host='s3-eu-west-1.amazonaws.com',
                        aws_access_key_id=username, 
                        aws_secret_access_key=password)

def init_aws_s3_bucket(connection=None, bucketname=None):
    '''
    Return a S3 bucket object. If it does'nt exists it'll
    be created.
    '''
    bucket = None
    if not connection.lookup(bucketname):
        LOG.info('Creating S3 bucket ' + bucketname)
        bucket = connection.create_bucket(bucketname, location=Location.EU)
#        bucket = connection.create_bucket(bucketname)
        LOG.info('Enabling versioning on S3 bucket ' + bucketname)
        bucket.configure_versioning(True)
    else:
        LOG.info('S3 bucket ' + bucketname + ' exists')
        bucket = connection.get_bucket(bucketname, validate=False)
        version_status = bucket.get_versioning_status()
        if len(version_status) == 0 or version_status['Versioning'] != 'Enabled':
            LOG.info('Enabling versioning on S3 bucket ' + bucketname)
            bucket.configure_versioning(True)
    return bucket

def save_files_in_aws_s3_bucket(from_datadir=None, bucket=None):
    local_files = list_files_sorted_creation(from_datadir)
    remote_files = []
    bucket_keys = bucket.list()
    for key in bucket_keys:
        remote_files.append(key.name)
    for file_path in local_files:
        file_name = os.path.basename(file_path)
        if file_name not in remote_files:
            LOG.info('Adding ' + file_name + ' to ' + bucket.name)
            key = Key(bucket)
            key.key = file_name
            key.set_contents_from_filename(file_path)

def save_file_in_aws_s3_bucket(file=None, bucket=None):
    '''
    Save file referenced by file into AWS S3 bucket.
    '''
    pass

def get_files_from_aws_s3(to_datadir=None, bucket=None):
    '''
    Download files from AWS S3 and store them in
    data_dir.
    '''
#    key = Key(bucket)
#    key.key = 'fetchTvillingPoolInfo_20130102_7_8_prod.xml'
#    key.get_contents_to_filename('hello_back_nisse')
    pass

def get_versions_from_aws_s3(bucket=None):
    print(bucket.get_versioning_status())
    for version in bucket.list_versions(): 
        print(version.key)
        print(version.name)
        print(version.version_id)
        print(version.size)
        print(version.last_modified)
        print()

def delete_bucket_with_versions():
    '''
    Inspiration http://stackoverflow.com/questions/6525270/how-to-delete-a-s3-version-from-a-bucket-using-boto-and-python
    '''
#    #Create a versioned bucket
#    bucket = s3.create_bucket("versioned.example.com")
#    bucket.configure_versioning(True)
#    
#    #Create a new key and make a few versions
#    key = new_key("versioned_object")
#    key.set_contents_from_string("Version 1")
#    key.set_contents_from_string("Version 2")
#    
#    #Try to delete bucket
#    bucket.delete()   ## FAILS with 409 Conflict
#    
#    #Delete our key then try to delete our bucket again
#    bucket.delete_key("versioned_object")
#    bucket.delete()   ## STILL FAILS with 409 Conflict
#    
#    #Let's see what's in there
#    list(bucket.list())   ## Returns empty list []
#    
#    #What's in there including versions?
#    list(bucket.list_versions())   ## Returns list of keys and delete markers
#    
#    #This time delete all versions including delete markers
#    for version in bucket.list_versions():
#        #NOTE we're still using bucket.delete, we're just adding the version_id parameter
#        bucket.delete_key(version.name, version_id = version.version_id)
#    
#    #Now what's in there
#    list(bucket.list_versions())   ## Returns empty list []
#    
#    #Ok, now delete the bucket
#    bucket.delete()   ## SUCCESS!!