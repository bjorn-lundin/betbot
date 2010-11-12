#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function, unicode_literals
import ConfigParser
import os
import sys

from sqlalchemy import create_engine, Column, Integer, String, Date, ForeignKey, Table, Numeric, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relation

def read_conf(conf):
    config_file = 'analyze.conf'
    config_file_path = os.path.join(sys.path[0], config_file)
    if os.path.exists(config_file_path):
        conf.read(config_file_path)
    else:
        print('Please create ' + config_file_path + ' before continuing!')
        exit(1)

Base = declarative_base()

def create_db_session(client_db_url):
    engine = create_engine(client_db_url, echo=False)
    Session = sessionmaker(bind=engine)
    return Session()

class Race(Base):
    __tablename__ = 'race'
    id = Column(Integer, primary_key=True)
    track = Column(String)
    date = Column(Date)
    number = Column(Integer)
    trio_odds = Column(Numeric)
    tvilling_odds = Column(Numeric)
    auto_start = Column(Boolean)
    raceday_id = Column(Integer)
    file = Column(String)
    url = Column(String)
    error = Column(String)
    bettypes = relation('BetType', secondary='race_bettype', backref='race')
    ekipage = relation('Ekipage', secondary='race_ekipage', backref='race')
    def __init__(self, data, file_instance, error=None):
        self.id = file_instance['race_id']
        self.track = data['race_track']
        self.date = data['race_date']
        self.number = data['race_number']
        if data.has_key('race_odds_trio'):
            self.trio_odds = data['race_odds_trio']
        else:
            self.trio_odds = None
        if data.has_key('race_odds_tvilling'):
            self.tvilling_odds = data['race_odds_tvilling']
        else:
            self.tvilling_odds = None
        self.auto_start = False
        self.raceday_id = file_instance['raceday_id']
        self.file = file_instance['file_name']
        self.url = 'http://www.travsport.se/sresultat?kommando=tevlingsdagVisa&tevdagId=' + \
                    file_instance['raceday_id'] + '&loppId=' + file_instance['race_id']
        self.error = error
    def __repr__(self):
        return "<Race('%s','%s', '%s', '%s')>" % \
            (self.id, self.track, self.date, self.number)

class BetType(Base):
    __tablename__ = 'bettype'
    id = Column(String, primary_key=True)
    def __init__(self, bet_type):
        self.id = bet_type
    def __repr__(self):
        return "<BetType('%s')>" % (self.id)

class Horse(Base):
    __tablename__ = 'horse'
    id = Column(Integer, primary_key=True)
    name = Column(String)
    def __init__(self, data):
        self.id = data['horse_id']
        self.name = data['horse_name']
    def __repr__(self):
        return "<Horse('%s','%s')>" % \
            (self.id, self.name)

class Driver(Base):
    __tablename__ = 'driver'
    id = Column(Integer, primary_key=True)
    name = Column(String)
    def __init__(self, data):
        self.id = data['driver_id']
        self.name = data['driver_name']
    def __repr__(self):
        return "<Driver('%s','%s')>" % \
            (self.id, self.name)

class Ekipage(Base):
    __tablename__ = 'ekipage'
    id = Column(Integer, primary_key=True)
    horse_id = Column(Integer, ForeignKey('horse.id'))
    driver_id = Column(Integer, ForeignKey('driver.id'))
    start_place = Column(Integer)
    finish_place = Column(Integer)
    dist_start_place = Column(Integer)
    distance = Column(Integer)
    shoes_front = Column(Boolean)
    shoes_rear = Column(Boolean)
    winner_odds = Column(Numeric)
    place_odds = Column(Numeric)
    time = Column(Numeric)
    time_comment = Column(String)
    # No strings (e.g. 'Horse') when using primaryjoin etc.
    horse = relation(Horse, primaryjoin=horse_id == Horse.id)
    driver = relation(Driver, primaryjoin=driver_id == Driver.id)
    def __init__(self, data):
        self.horse_id = data['horse_id']
        self.driver_id = data['driver_id']
        self.start_place = data['start_place']
        self.finish_place = data['finish_place']
        self.dist_start_place = data['dist_start_place']
        self.distance = data['distance']
        self.shoes_front = data['shoes_front']
        self.shoes_rear = data['shoes_rear']
        self.winner_odds = data['winner_odds']
        self.place_odds = data['place_odds']
        self.time = data['time']
        self.time_comment = data['time_comment']
    def __repr__(self):
        return "<Ekipage('%s','%s','%s')>" % \
            (self.id, self.horse_id, self.driver_id)

# Association tables
race_bettype = Table('race_bettype', Base.metadata,
                      Column('race_id', Integer, ForeignKey('race.id')),
                      Column('bettype_id', String, ForeignKey('bettype.id'))
                      )

race_ekipage = Table('race_ekipage', Base.metadata,
                     Column('race_id', Integer, ForeignKey('race.id')),
                     Column('ekipage_id', Integer, ForeignKey('ekipage.id')),
                     )

def get_persisted_files(db_session):
    persisted_files = []
    for file in db_session.query(Race.file):
        persisted_files.append(file[0])
    return persisted_files
    
if __name__ == '__main__':
    conf = ConfigParser.SafeConfigParser()
    read_conf(conf)
    client_db_url = conf.get('DEFAULT', 'client_db_url')
    db_session = create_db_session(client_db_url)
    persisted_files = get_persisted_files(db_session)
    print('Number of files:', len(persisted_files))
    
    auto_dict = {}
    for start_place, finish_place, time_comment in \
        db_session.query(Ekipage.start_place, Ekipage.finish_place,
        Ekipage.time_comment):
        errors = 0
        auto = False
        try:
            if time_comment and u'a' in time_comment:
                auto = True
        except:
            errors += 1
            continue
        if auto:
            if auto_dict.has_key(start_place):
                auto_dict[start_place] = auto_dict[start_place] + finish_place
            else:
                auto_dict[start_place] = finish_place
    print('Autostart')
    for key in auto_dict.keys():
        print('Start:', key, 'Sum of finish:', auto_dict[key])
    print('Errors:', errors)