#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function, unicode_literals
import ConfigParser
import os
import sys
import datetime
import decimal

from sqlalchemy import create_engine, Column, Integer, String, Date, ForeignKey, Table, Numeric, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relation, eagerload

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
                      Column('race_id', Integer, ForeignKey('race.id'), primary_key=True),
                      Column('bettype_id', String, ForeignKey('bettype.id'), primary_key=True)
                      )

race_ekipage = Table('race_ekipage', Base.metadata,
                     Column('race_id', Integer, ForeignKey('race.id'), primary_key=True),
                     Column('ekipage_id', Integer, ForeignKey('ekipage.id'), primary_key=True),
                     )

def get_persisted_files(db_session):
    persisted_files = []
    for file in db_session.query(Race.file):
        persisted_files.append(file[0])
    return persisted_files

def date_range(db_session, start_date=None, end_date=None, debug=False):
    if not start_date:
        start_date = datetime.date(1990,01,01)
        if debug:
            print('start_date', start_date)
    if not end_date:
        end_date = datetime.date.today()
        if debug:
            print('end_date', end_date)
    query = db_session.query(Race).\
            order_by(Race.date, Race.number).\
            options(eagerload('ekipage')).\
            options(eagerload('bettypes')).\
            filter(Race.date >= start_date).filter(Race.date <= end_date)
    races = query.all()
    if debug:
        print([[race.date, race.number] for race in races])
    return races

def start_finish_stats(races, track=None):
    auto_indices = []
    volt_indices = []
    index = -1
    for race in races:
        index += 1
        if race.auto_start:
            auto_indices.append(index)
        else:
            volt_indices.append(index)
    auto_start_finish = {}
    auto_win_percentage = {}
    auto_place_percentage = {}
    volt_start_finish = {}
    volt_win_percentage = {}
    volt_place_percentage = {}
    # Auto start races
    for race in auto_indices:
        for ekipage in races[race].ekipage:
            if ekipage.finish_place < 900:
                if ekipage.start_place not in auto_start_finish:
                    auto_start_finish[ekipage.start_place] = {}
                elif ekipage.finish_place not in auto_start_finish[ekipage.start_place]:
                    auto_start_finish[ekipage.start_place][ekipage.finish_place] = 1
                else:
                    auto_start_finish[ekipage.start_place][ekipage.finish_place] += 1
    for start in auto_start_finish:
        if auto_start_finish[start].has_key(1) and auto_start_finish[start].has_key(2) \
                and auto_start_finish[start].has_key(3):
            win_perc = decimal.Decimal(auto_start_finish[start][1])/decimal.Decimal(len(auto_indices))
            auto_win_percentage[start] = win_perc
            place_accu = auto_start_finish[start][1] + auto_start_finish[start][2] + auto_start_finish[start][3]
            place_perc = decimal.Decimal(place_accu)/decimal.Decimal(len(auto_indices))
            auto_place_percentage[start] = place_perc
    # Volt start races
    for race in volt_indices:
        for ekipage in races[race].ekipage:
            if ekipage.finish_place < 900:
                if ekipage.start_place not in volt_start_finish:
                    volt_start_finish[ekipage.start_place] = {}
                elif ekipage.finish_place not in volt_start_finish[ekipage.start_place]:
                    volt_start_finish[ekipage.start_place][ekipage.finish_place] = 1
                else:
                    volt_start_finish[ekipage.start_place][ekipage.finish_place] += 1
    for start in volt_start_finish:
        if volt_start_finish[start].has_key(1) and volt_start_finish[start].has_key(2) \
                and volt_start_finish[start].has_key(3):
            win_perc = decimal.Decimal(volt_start_finish[start][1])/decimal.Decimal(len(volt_indices))
            volt_win_percentage[start] = win_perc
            place_accu = volt_start_finish[start][1] + volt_start_finish[start][2] + volt_start_finish[start][3]
            place_perc = decimal.Decimal(place_accu)/decimal.Decimal(len(volt_indices))
            volt_place_percentage[start] = place_perc
    print('Number of races:', len(races))
    print('Number of races with auto start:', len(auto_indices))
    print('Number of races with volt start:', len(volt_indices))
    print('Auto winning %:')
    for x in sorted(auto_win_percentage, key=auto_win_percentage.get, reverse=True):
        print(x, '\t\t', (auto_win_percentage[x] * 100).quantize(decimal.Decimal('.1'), rounding=decimal.ROUND_DOWN), '%')
    print('Auto place %:')
    for x in sorted(auto_place_percentage, key=auto_place_percentage.get, reverse=True):
        print(x, '\t\t', (auto_place_percentage[x]* 100).quantize(decimal.Decimal('.1'), rounding=decimal.ROUND_DOWN), '%')
    print('Volt winning %:')
    for x in sorted(volt_win_percentage, key=volt_win_percentage.get, reverse=True):
        print(x, '\t\t', (volt_win_percentage[x] * 100).quantize(decimal.Decimal('.1'), rounding=decimal.ROUND_DOWN), '%')
    print('Volt place %:')
    for x in sorted(volt_place_percentage, key=volt_place_percentage.get, reverse=True):
        print(x, '\t\t', (volt_place_percentage[x]* 100).quantize(decimal.Decimal('.1'), rounding=decimal.ROUND_DOWN), '%')

def ekipage_form(races):
    form = {}
    for race in races:
        for ekipage in race.ekipage:
            if ekipage.horse_id not in form:
                form[ekipage.horse_id] = {}
            form[ekipage.horse_id][race.date] = ['start' + str(ekipage.start_place), 'finish' + str(ekipage.finish_place)]
    for horse in form:
        print(horse)
        for r in form[horse].iteritems():
            print('  ->  ', r)
        
def bettype_range(races, search_bettype):
    indices = []
    index = -1
    for race in races:
        index += 1
        for bettype in race.bettypes:
            if search_bettype in bettype.id:
                indices.append(index)
                break
    return indices

if __name__ == '__main__':
    conf = ConfigParser.SafeConfigParser()
    read_conf(conf)
    client_db_url = conf.get('DEFAULT', 'client_db_url')
    db_session = create_db_session(client_db_url)
    
    races = []
    start_date = datetime.date(2009, 01, 01)
    end_date = datetime.date(2009, 01, 31)
    races = date_range(db_session, start_date, end_date, debug=False)
    #start_finish_stats(races)
    ekipage_form(races)
    
    
    exit()
    
    bettype = 'trio'
    hit_indices = bettype_range(races, bettype)
    print('races2:', len(hit_indices))
    
    for i in hit_indices:
        for e in races[i].ekipage:
            print(e.horse.name, e.start_place, e.finish_place)
    exit()
    
