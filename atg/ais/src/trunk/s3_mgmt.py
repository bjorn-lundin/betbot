#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Misc. utilities for AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
from boto.s3.connection import S3Connection, Location
from boto.s3.key import Key
from boto.exception import S3CreateError
from boto.exception import S3PermissionsError, S3ResponseError
import logging
import conf
import util
import os

LOG = logging.getLogger('AIS')

#######################################################
# AWS storage (S3) cloud API                          #
#######################################################
def get_aws_s3_connections(username=None, password=None):
    '''
    Return a S3 connection.
    '''
    LOG.info('Connecting to S3')
    connection = None
    try:
        connection = S3Connection(
            host=conf.AIS_S3_HOST,
            aws_access_key_id=username, 
            aws_secret_access_key=password
        )
    except S3PermissionsError:
        LOG.exception('S3 Exception')
    except S3ResponseError:
        LOG.exception('S3 Exception')
    return connection

def init_aws_s3_bucket(connection=None, bucketname=None):
    '''
    Returns a S3 bucket object. If it does'nt exists it'll
    be created.
    '''
    bucket = None
    if not connection.lookup(bucketname):
        LOG.info('Creating S3 bucket ' + bucketname)
        try:
            bucket = connection.create_bucket(bucketname, location=Location.EU)
        except S3CreateError:
            LOG.exception('Failed to create bucket ' + bucketname)
        LOG.info('Enabling versioning on S3 bucket ' + bucketname)
        bucket.configure_versioning(True)
    else:
        LOG.info('S3 bucket ' + bucketname + ' exist')
        bucket = connection.get_bucket(bucketname, validate=False)
        version_status = bucket.get_versioning_status()
        if len(version_status) == 0 or \
                version_status['Versioning'] != 'Enabled':
            LOG.info('Enabling versioning on S3 bucket ' + bucketname)
            bucket.configure_versioning(True)
    return bucket

def save_files_in_aws_s3_bucket(from_datadir=None, bucket=None, replace=False):
    '''
    Save files in directory into AWS S3 bucket.
    '''
    local_files = util.list_files_with_path(dir_path=from_datadir)
    remote_files = []
    bucket_keys = bucket.list()
    for key in bucket_keys:
        remote_files.append(key.name)
    for file_path in local_files:
        file_name = os.path.basename(file_path)
        if file_name not in remote_files:
            LOG.info('Adding ' + file_name + ' to ' + bucket.name)
            save_file_in_aws_s3_bucket(
                file_path=file_path,
                bucket=bucket,
                replace=replace
            )

def save_file_in_aws_s3_bucket(file_path=None, bucket=None, replace=False):
    '''
    Save file referenced by file into AWS S3 bucket. NOTE! Using the md5
    parameter when saving will ensure data integrity during file transfer. 
    BOTO documentation say something else though.
    '''
    file_name = os.path.basename(file_path)
    key = Key(bucket)
    key.key = file_name
    file_md5 = key.compute_md5(open(file_path, 'rb'))
    try:
        key.set_contents_from_filename(
            filename=file_path,
            replace=replace,
            md5=file_md5
        )
    except S3ResponseError:
        LOG.exception('Failed saving file ' + file_name + 
                      ' to S3 bucket ' + bucket.name)

def print_versions_from_aws_s3(bucket=None):
    '''
    Print version information from a bucket
    '''
    print('Version status: ' + str(bucket.get_versioning_status()))
    for version in bucket.list_versions():
        print('Version name: ' + version.name) # equals version.key
        print('Version id: ' + version.version_id)
        print('Version storage_class: ' + version.storage_class)
        print('Version size: ' + str(version.size))
        print('Version last modified: ' + version.last_modified)
        print('Version etag: ' + version.etag)
        print('Version md5: ' + str(version.md5))

def delete_aws_s3_bucket(host=None, username=None, 
                         password=None, bucketname=None):
    '''
    Deletes a bucket including versions if they exist
    '''
    print()
    verify = raw_input('Delete bucket: ' + 
                       bucketname + '? (y/n): ')
    verify = verify.strip().lower()
    if verify not in ("y", "yes"):
        print('Bucket deletion aborted, exiting application')
        exit(0)

    connection = S3Connection(
        host=host,
        aws_access_key_id=username, 
        aws_secret_access_key=password
    )
    print('Connecting to S3')
    try:
        bucket = connection.get_bucket(bucketname, validate=True)
    except S3ResponseError:
        print('Could not get bucket ' + bucketname)
        return
    for version in bucket.list_versions():
        try:
            bucket.delete_key(
                version.name,
                version_id=version.version_id
            )
        except S3ResponseError:
            print('Could not delete key')
    try:
        print('Deleting bucket ' + bucketname)
        bucket.delete()
    except S3ResponseError:
        print('Could not delete bucket')

def main():
    '''
    Test main loop of this module
    '''
    import command_parser as cp
    command = cp.parse()
    print('Starting module as stand alone application')
        
    cloud_storage_connection = None
    cloud_storage_bucket = None
    
    if cp.DELETE_BUCKET_IN_CLOUD not in command:
        # delete_bucket handles it's own connection etc.
        cloud_storage_connection = get_aws_s3_connections(
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD
        )
        cloud_storage_bucket = init_aws_s3_bucket(
            connection=cloud_storage_connection,
            bucketname=conf.AIS_S3_BUCKET
        )
    
    if cp.SAVE_FILES_IN_CLOUD in command:
        print('Running ' + cp.SAVE_FILES_IN_CLOUD)
        save_files_in_aws_s3_bucket(
            from_datadir=conf.AIS_DATADIR, bucket=cloud_storage_bucket
        )
        
    if cp.PRINT_VERSIONS_FROM_CLOUD in command:
        print('Running ' + cp.PRINT_VERSIONS_FROM_CLOUD)
        print_versions_from_aws_s3(bucket=cloud_storage_bucket)
        
    if cp.DELETE_BUCKET_IN_CLOUD in command:
        print('Running ' + cp.DELETE_BUCKET_IN_CLOUD)
        delete_aws_s3_bucket(
            host=conf.AIS_S3_HOST,
            username=conf.AIS_S3_USER,
            password=conf.AIS_S3_PASSWORD,
            bucketname=conf.AIS_S3_BUCKET
        )
        print('Ending ' + cp.DELETE_BUCKET_IN_CLOUD)
        
    if cloud_storage_connection:
        cloud_storage_connection.close()
        
if __name__ == "__main__":
    main()
        