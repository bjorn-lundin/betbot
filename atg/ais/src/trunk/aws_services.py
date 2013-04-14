#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Misc. utilities for AIS
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
from boto.s3.connection import S3Connection, Location
from boto.s3.key import Key
from boto.exception import BotoClientError, S3CreateError
from boto.exception import S3PermissionsError, S3ResponseError
from boto import ses
import logging
import os

LOG = logging.getLogger('AIS')

#######################################################
# AWS storage (S3) cloud API                          #
#######################################################
def get_aws_s3_connections(host=None, username=None, password=None):
    '''
    Return a S3 connection.
    '''
    LOG.info('Connecting to S3')
    connection = None
    try:
        connection = S3Connection(
            host=host,
            aws_access_key_id=username, 
            aws_secret_access_key=password
        )
    except S3PermissionsError:
        LOG.exception('S3 Exception')
    except S3ResponseError:
        LOG.exception('S3 Exception')
    return connection

def init_aws_s3_bucket(connection=None, bucketname=None, versioning=True):
    '''
    Returns a S3 bucket object. If it does'nt exists it'll
    be created.
    '''
    bucket = None
    createbucket = False
    try:
        connection.get_bucket(bucketname)
    except (BotoClientError, S3ResponseError) as e:
        if hasattr(e, 'status') and e.status == 404: # Not Found
            createbucket = True
        else:
            LOG.exception('Exiting application')
            exit(1)

    if createbucket:        
        LOG.info('Creating S3 bucket ' + bucketname)
        try:
            bucket = connection.create_bucket(
                bucketname, 
                location=Location.EU
            )
            if versioning:
                LOG.info('Enabling versioning on S3 bucket ' + bucketname)
                bucket.configure_versioning(versioning)
        except (S3ResponseError, S3CreateError, S3PermissionsError) as e:
            LOG.exception('Exiting application')
            exit(1)
    else:
        LOG.info('S3 bucket ' + bucketname + ' exist')
        try:
            bucket = connection.get_bucket(bucketname, validate=False)
            if versioning:
                version_status = bucket.get_versioning_status()
                if len(version_status) == 0 or \
                        version_status['Versioning'] != 'Enabled':
                    LOG.info('Enabling versioning on S3 bucket ' + bucketname)
                    bucket.configure_versioning(versioning)
        except (S3ResponseError, S3CreateError, S3PermissionsError) as e:
            LOG.exception('Exiting application')
            exit(1)
    return bucket

def save_files_in_aws_s3_bucket(sourcefiles=None, bucketname=None, 
                                versioning=True, replace=False,
                                host=None, username=None, password=None):
    '''
    Save a list of files into AWS S3 bucket. NOTE! Using the md5 parameter
    when saving will ensure data integrity during file transfer. BOTO 
    documentation say something else though.
    '''
    connection = get_aws_s3_connections(
        host=host,
        username=username,
        password=password
    )
    bucket = init_aws_s3_bucket(
        connection=connection,
        bucketname=bucketname,
        versioning=versioning
    )
    targetfiles = []
    bucketkeys = bucket.list()
    for key in bucketkeys:
        targetfiles.append(key.name)
    for filepath in sourcefiles:
        filename = os.path.basename(filepath)
        if filename not in targetfiles:
            key = Key(bucket)
            key.key = filename
            file_md5 = key.compute_md5(open(filepath, 'rb'))
            try:
                LOG.info('Uploading ' + filename + ' to ' + bucket.name)
                key.set_contents_from_filename(
                    filename=filepath,
                    replace=replace,
                    md5=file_md5
                )
            except S3ResponseError:
                LOG.exception('Failed saving file ' + filename + 
                              ' to S3 bucket ' + bucket.name)
            finally:
                if connection:
                    connection.close()

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

def delete_aws_s3_bucket(host=None, username=None, password=None):
    '''
    Deletes a bucket including versions if they exist
    '''
    bucket_name = raw_input('Name of bucket to delete: ')
    verify = raw_input('Delete bucket: ' + 
                       bucket_name + '? (y/n): ')
    verify = verify.strip().lower()
    if verify not in ("y", "yes"):
        log_msg = 'Bucket deletion aborted, exiting application'
        print(log_msg)
        LOG.info(log_msg)
        exit(0)

    connection = get_aws_s3_connections(
        host=host,
        username=username, 
        password=password
    )
    
    try:
        bucket = connection.get_bucket(bucket_name, validate=True)
    
    except (BotoClientError, S3ResponseError) as e:
        LOG.exception('Exiting application')
        print(e)
        exit(1)
    
    for version in bucket.list_versions():
        try:
            bucket.delete_key(
                version.name,
                version_id=version.version_id
            )
        except (BotoClientError, S3ResponseError) as e:
            LOG.exception('Exiting application')
            print(e)
            exit(1)
    try:
        log_msg = 'Deleting bucket ' + bucket_name
        print(log_msg)
        LOG.info(log_msg)
        bucket.delete()
    except (BotoClientError, S3ResponseError) as e:
        LOG.exception('Exiting application')
        print(e)
        exit(1)

def get_aws_ses_connections(username=None, password=None):
    '''
    Return a SES connection.
    '''
    LOG.info('Connecting to SES')
    connection = ses.connect_to_region(
        'us-east-1',
        aws_access_key_id=username, 
        aws_secret_access_key=password
    )
    return connection

def send_ses_email(username=None, password=None, from_address=None,
                   subject=None, body=None, send_list=None):
    '''
    Send an email via AWS SES
    '''
    connection = get_aws_ses_connections(
        username=username,
        password=password
    )
    LOG.info('Sending email with subject ' + subject)
    connection.send_email(
        from_address,
        subject,
        body,
        send_list
    )

def main():
    '''
    Test main loop of this module
    '''
    pass

if __name__ == "__main__":
    main()
