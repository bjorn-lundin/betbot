#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, division, print_function, unicode_literals
import ConfigParser
import sys
import re
import datetime
import decimal
import os
import codecs

from sqlalchemy import create_engine, Column, Integer, String, Date, ForeignKey, Table, Numeric, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relation

def read_conf(conf):
    config_file = 'persist.conf'
    config_file_path = os.path.join(sys.path[0], config_file)
    if os.path.exists(config_file_path):
        conf.read(config_file_path)
    else:
        print('Please create ' + config_file_path + ' before continuing!')
        exit(1)

Base = declarative_base()

def create_db_session(db_url, init_db):
    engine = create_engine(db_url, echo=False)
    Session = sessionmaker(bind=engine)
    if init_db:
        Base.metadata.drop_all(engine)
        Base.metadata.create_all(engine)
    return Session()

def get_persisted_files(db_session):
    persisted_files = []
    for file in db_session.query(Race.file):
        persisted_files.append(file[0])
    return persisted_files

def get_data(data_path, test, db_session, persisted_files):
    file_source = []
    test_files = [
                  'raceday_492338_race_640915.html',
                  'raceday_507132_race_700937.html',
                  'raceday_507646_race_709300.html', # Problem with trasched åäöÅÄÖ
                  'raceday_494210_race_653094.html', # Decimal problem in parse_ekipage_odds_time()/string_to_decimal()
                  'raceday_507130_race_700240.html', # Month problem in parse_race_date_bet_types()/month = int(months.index(f.group(3).lower()) + 1)
                  'raceday_492788_race_645816.html', # No result what so ever...
                  'raceday_507630_race_698161.html', # No track name extracted
                  ]
    skip_files = [
                  #'raceday_507646_race_709300.html',
                  #'raceday_493395_race_651321.html',
#                  'raceday_507130_race_700240.html', # Problem with trasched åäöÅÄÖ (unsolved)
                  ]
    if test:
        file_source = get_files_and_ids(data_path, test_files)
    else:
        file_source = get_files_and_ids(data_path)

    for file in file_source:
        if file['file_name'] in persisted_files:
            print ('File ' + file['file_name'] + ' already in database')
            continue
        
        if file['file_name'] in skip_files:
            print ('Skipping file ' + file['file_name'])
            continue
        
        print ('Processing ' + file['file_name'])
        f = codecs.open(os.path.join(data_path, file['file_name']), 'r', encoding='iso-8859-1')
        data = prep_data(f)
        f.close()

        table = re.compile('<table.*?</table>', (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
        tables = table.findall(data)
        
        horse_data_search = 'Plac'
        race_data_search = 'Omsättning\svinnare:'
        pattern_table_index = {horse_data_search:None, race_data_search:None}
        for key in pattern_table_index.keys():
            p = re.compile(key, (re.IGNORECASE | re.UNICODE))
            for table in tables:
                if p.search(table):
                    pattern_table_index[key] = tables.index(table)

        error = ''
        result1 = parse_race_date_bet_types(data, file)
        if not result1:
            error = error + '1'
            
        result2 = parse_ekipage_data(data)
        if not result2:
            error = error + '2'
            
        result3 = parse_race_turnover_odds(data)
        if not result3:
            error = error + '3'
            
        # Initial db storage test
        if error == '':
            race_data = {}
            race_data.update(result1)
            race_data.update(result3)
            
            ekipage_data = []
            ekipage_data.extend(result2)
            
            race = Race(race_data, file)
            bettypes = []
            for data in race_data['race_bet_types']:
                bettypes.append(BetType(data))
            race.bettypes = bettypes
            
            auto_start = False
            all_ekipage = []
            for data in ekipage_data:
                horse = Horse(data)
                driver = Driver(data)
                db_session.merge(horse)
                db_session.merge(driver)
                ekipage = Ekipage(data)
                # If time_comment contains an 'a' the start method is auto
                if ekipage.time_comment and 'a' in ekipage.time_comment:
                    auto_start = True
                all_ekipage.append(ekipage)
            race.ekipage = all_ekipage
            race.auto_start = auto_start
        else:
            race = Race(result1, file, error)
        # TODO For efficency use db_session.add(race)
        # instead when checking filenames before adding?
        db_session.merge(race)
        db_session.commit()
            
        if test:
            print ('parse_race_date_bet_types', result1)
            print (len(result1))
            print ('parse_ekipage_data', result2)
            print (len(result2))
            print ('parse_race_turnover_odds', result3)
            print (len(result3))

def get_files_and_ids(data_path, test_files=None):
    data_files = []
    files_and_ids = []
    pattern = 'raceday_(\d+)_race_(\d+).'
    if test_files:
        data_files = test_files
    else:
        data_files = os.listdir(data_path)
    for file in data_files:
        match = re.match(pattern, file)
        if match:
            files_and_ids.append({'file_name':file, 
                                  'raceday_id':match.group(1), 
                                  'race_id':match.group(2)})
    return files_and_ids

def prep_data(f):
    data = []
    for line in f:
        line = line.strip(' \t\r\n')
        if not line:
            continue
        else: 
            data.append(line)
    return ('\n'.join(data))

def parse_race_date_bet_types(data, file_instance):
    result = {}
    named_targets = ('race_track', 'race_date', 'race_number', 'race_bet_types')
    for name in named_targets:
        result[name] = None
    months = ['januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 
              'augusti','september', 'oktober', 'november', 'december']
    # Get track and date
    p = re.compile('(\w+) \w+ (\d{1,2}) (\w+) (\d{4})', (re.DOTALL | re.IGNORECASE | re.UNICODE))
    f = p.search(data)
    if f:
        result[named_targets[0]] = f.group(1).lower()
        year = int(f.group(4))
        month = int(months.index(f.group(3).lower()) + 1)
        day = int(f.group(2))
        result[named_targets[1]] = datetime.date(year, month, day)
    # Get race bet types
    p = re.compile('Lopp\s(\d+)\..*?([,\s\w\d-]+)', (re.DOTALL | re.IGNORECASE | re.UNICODE))
    m = p.search(data)
    if m:
        result[named_targets[2]] = int(m.group(1))
        result[named_targets[3]] = m.group(2).lower().replace(' ','').split(',')
    return result

def parse_ekipage_data(data):
    result = []
    p = re.compile('''
    <A\sHREF="/shestinfo\?kommando=hestResultat&hestId=(\d+)"\sCLASS="linkBlue10"><B>.*?</B></A><BR>
    ''', (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
    horse_id_start_end = []
    iterator = p.finditer(data)
    for m in iterator:
        horse_id_start_end.append({'horse_id':m.group(1), 'parse_start':m.start(), 'parse_end':m.end()})
    # Check if at least one match
    if horse_id_start_end:
        horse_data = []
        driver_data = []
        horse_odds_time = []
        
        for index in range(0, len(horse_id_start_end) - 1):
            horse_id_start_end[index]['parse_end'] = horse_id_start_end[index + 1]['parse_start']
        horse_id_start_end[-1]['parse_end'] = len(data)

        horse_data = parse_horse_data(data)
        driver_data = parse_driver_data(data, horse_id_start_end)
        horse_odds_time = parse_ekipage_odds_time(data, horse_id_start_end)
        
        if len(horse_data) == len(driver_data) == len(horse_odds_time) == len(horse_id_start_end):
            for i in range(0, len(horse_id_start_end)):
                horse_data[i].update(driver_data[i])
                horse_data[i].update(horse_odds_time[i])
                result.append(horse_data[i])
    return result

def parse_horse_data(data):
    result = []
    named_targets = ('finish_place', 'start_place', 'horse_id', 'horse_name',
                     'dist_start_place', 'distance', 'shoes_front', 'shoes_rear')
    p = re.compile('''
        <TD\sCLASS="contentHeadline"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding-top:1px;\spadding-bottom:1px;\spadding-left:
        1px;\spadding-right:10px"\sALIGN="right"><B>(?P<%s>[\d\w]+)</B></TD>
        .*?
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"><B>(?P<%s>\d+)</B>&nbsp;
        .*?
        <A\sHREF="/shestinfo\?kommando=hestResultat&hestId=(?P<%s>\d+)"\sCLASS="linkBlue10"><B>(?P<%s>.*?)</B></A><BR>
        .*?
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="right">(?P<%s>\d+)/(?P<%s>\d+)</TD>
        .*?
        (?P<%s>Sko.gif|EjSko.gif)
        .*?
        (?P<%s>Sko.gif|EjSko.gif)
        ''' % named_targets, (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
    iterator = p.finditer(data)
    for target in iterator:
        all_targets = target.groupdict()
        if all_targets['finish_place'] == '0':
            all_targets['finish_place'] = 900
        elif not all_targets['finish_place'].isdigit():
            all_targets['finish_place'] = 999
        all_targets['shoes_front'] = all_targets['shoes_front'] == 'Sko.gif'
        all_targets['shoes_rear'] = all_targets['shoes_rear'] == 'Sko.gif'
        result.append(all_targets)
    return result

'''
A driver to a horse can have 3 states
The horse have
1. both driver and trainer (choose driver)
2. only driver
3. a driver without id  (create "anonymous driver")
'''
def parse_driver_data(data, horse_id_start_end):
    result = []
    named_targets = ('driver_id', 'driver_name', 'trainer_as_driver_id', 'trainer_as_driver_name')
    p = re.compile('''
        <A\sHREF="/slicensinfo\?kommando=visalicens&licensId=(?P<%s>\d+)"\sCLASS="linkBlue9">(?P<%s>.*?)</A>
        |
        <A\sHREF="/slicensinfo\?kommando=trenarstat&licensId=(?P<%s>\d+)"\sCLASS="linkBlue9">(?P<%s>.*?)</A>
        ''' % named_targets, (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
    for horse in horse_id_start_end:
        match = p.search(data, horse['parse_start'], horse['parse_end'])
        driver_data = {}
        driver_data['horse_id'] = horse['horse_id']
        if match:
            driver_dict = match.groupdict()
            driver_data['driver_id'] = driver_dict.get('driver_id')
            driver_data['driver_name'] = driver_dict.get('driver_name')
            if not driver_data['driver_id']:
                driver_data['driver_id'] = driver_dict.get('trainer_as_driver_id')
                driver_data['driver_name'] = driver_dict.get('trainer_as_driver_name')
        else:
            driver_data['driver_id'] = '999999'
            driver_data['driver_name'] = 'No driver info'
        result.append(driver_data)
    return result

def parse_ekipage_odds_time(data, horse_id_start_end):
    result = []
    named_targets = ('winner_odds', 'place_odds', 'time', 'time_comment', 
                    'winner_odds2', 'place_odds2', 'time2', 'time_comment2')
    target_to_decimal = [named_targets[0], named_targets[1], named_targets[2]]
    p = re.compile('''
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="center">\s<B>(?P<%s>[\d,]+)</B>\s</TD>
        .*?
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="center"><B>(?P<%s>[\d,]*)&nbsp;</B></TD>
        .*?
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="left">(?P<%s>[\d,]*)(?P<%s>\w*)</TD>
        |
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="center">\s*\((?P<%s>[\d,]+)\)\s*</TD>
        .*?
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="center"><B>(?P<%s>[\d,]*)&nbsp;</B></TD>
        .*?
        <TD\sCLASS="content"\sBGCOLOR="\#EEEEEA"\sSTYLE="padding:2px"\sALIGN="left">(?P<%s>[\d,]*)(?P<%s>\w*)</TD>
        ''' % named_targets, (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
    for horse in horse_id_start_end:
        match = p.search(data, horse['parse_start'], horse['parse_end'])
        odds_time = {}
        odds_time['horse_id'] = horse['horse_id']
        if match:
            odds_time_dict = match.groupdict()
            clean_index = 0
            clean_dict = {}
            for group in named_targets[:int(len(named_targets)/2)]:
                clean_dict[group] = None
            for index in xrange(0, len(named_targets)):
                if clean_index == len(named_targets)/2:
                    clean_index = 0
                if odds_time_dict[named_targets[index]]:
                    clean_dict[named_targets[clean_index]] = odds_time_dict[named_targets[index]]
                clean_index += 1
            # Convert to decimal
            for target in target_to_decimal:
                clean_dict[target] = string_to_decimal(clean_dict[target])
            result.append(clean_dict)
    return result

def parse_race_turnover_odds(data):
    result = {}
    named_groups = ('race_turnover_winner', 'race_turnover_place', 'race_result_tvilling', 
                    'race_odds_tvilling', 'race_turnover_tvilling')
    p = re.compile(r'''
        Omsättning\svinnare:.*?>(?P<%s>[\d ]+)
        .*?
        Omsättning\splats:.*?>(?P<%s>[\d ]+)
        .*?
        Tvilling\sres/odds:.*?>(?P<%s>[\d-]+).*?(?P<%s>[\d,]+)
        .*?
        Omsättning\stvilling:.*?>(?P<%s>[\d ]+)
    ''' % named_groups, (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
    m = p.search(data)
    if m:
        for name in named_groups:
            result[name] = None
        result.update(m.groupdict())
        # Convert to int
        for name in [0, 1, 4]:
            result[named_groups[name]] = string_to_int(result[named_groups[name]])
        # Convert into decimal
        result[named_groups[3]] = string_to_decimal(result[named_groups[3]])
        # Convert into list
        result[named_groups[2]] = string_to_list(result[named_groups[2]])
    named_groups = ('race__result_trio', 'race_odds_trio', 'race_turnover_trio')
    p = re.compile(r'''
        Trio\sres/odds:.*?>(?P<%s>[\d-]+).*?(?P<%s>[\d,]+)
        .*?
        Omsättning\strio:.*?>(?P<%s>[\d ]+)
    ''' % named_groups, (re.VERBOSE | re.DOTALL | re.IGNORECASE | re.UNICODE))
    m = p.search(data)
    if m:
        for name in named_groups:
            result[name] = None
        result.update(m.groupdict())
        result[named_groups[0]] = string_to_list(result[named_groups[0]])
        result[named_groups[1]] = string_to_decimal(result[named_groups[1]])
        result[named_groups[2]] = string_to_int(result[named_groups[2]])
    return result

def string_to_decimal(string):
    result = None
    err = False
    if string == None:
        err = True
    # Check if string can be converted to decimal
    if not err:
        pattern = '(^|[^\d])[,.]($|[^\d])'
        if re.search(pattern, string):
            err = True
    # If the string already contain a comma sign, just replace it
    if not err:
        if string.find(',') > -1:
            result = decimal.Decimal(string.replace(',', '.'))
        # Else we need to devide the value (odds) with 10 and create a float
        else:
            result = decimal.Decimal(string) / 10
    return result

def string_to_int(string):
    if string == None:
        return None
    return int(string.replace(' ', ''))

def string_to_list(string):
    return string.split("-")
    
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

if __name__ == '__main__':
    conf = ConfigParser.SafeConfigParser()
    read_conf(conf)
    file_path = conf.get('DEFAULT', 'client_file_path')
    db_url = conf.get('DEFAULT', 'client_db_url')
    init_db = True
    test = False
    db_session = create_db_session(db_url, init_db)
    persisted_files = get_persisted_files(db_session)
    get_data(file_path, test, db_session, persisted_files)