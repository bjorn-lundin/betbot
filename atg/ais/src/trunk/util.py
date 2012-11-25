'''
Utilities for converting to and from AIS data types
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import datetime

def struct_to_date(date_struct):
    '''
    Converts string parts to a date object
    '''
    date_string = str(date_struct.year) \
        + '-' + str(date_struct.month) \
        + '-' + str(date_struct.date)
    date = datetime.datetime.strptime(date_string, "%Y-%m-%d")
    return date

def date_to_struct():
    '''
    Converts a date object to string parts?/array?
    '''
    pass

def struct_to_time(time_struct):
    '''
    Converts string parts to a time object
    '''
    time = datetime.time(time_struct.hour, 
                         time_struct.minute, 
                         time_struct.second, 
                         time_struct.tenth * 100000)
    return time

def get_or_create(session, caller_clazz, caller_self, **kwargs):
    '''
    If entity exist in db return in, else create and save it
    '''
    instance = session.query(caller_clazz).filter_by(**kwargs).first()
    if not instance:
        instance = caller_self
        session.add(instance)
        session.commit()
    return instance
