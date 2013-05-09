#-*- coding: utf-8 -*-
'''
Database entities for AIS web service
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy import Date, Time, Boolean, ForeignKey, Table, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.exc import IntegrityError
import util
import conf
import logging

LOG = logging.getLogger('AIS')
BASE = declarative_base()
# pylint: disable=E1101
# pylint: disable=W0232

def create(entity=None):
    '''
    Create an entity in database
    '''
    try:
        DB_SESSION.add(entity)
        DB_SESSION.commit()
    except IntegrityError:
        LOG.exception('Exception when creating new db entity')
        DB_SESSION.rollback()

class LoadedEODFiles(BASE):
    '''
    Database entity loaded_eod_files
    Table holding names of EOD files already loaded into
    the database.
    '''
    __tablename__ = 'loaded_eod_files'
    id = Column(Integer, primary_key=True)
    filename = Column(String, unique=True)
    loadtime = Column(DateTime)
    def __init__(self, filename=None, loadtime=None):
        self.filename = filename
        self.loadtime = loadtime
    
    @staticmethod
    def read_all():
        '''
        List all LoadedEODFiles entities in database
        '''
        return DB_SESSION.query(LoadedEODFiles).all()
    
class Raceday(BASE):
    '''
    Database entity Raceday
    Skipping the field 'itspEventCode'. For some reason it 
    crashes SQLAlchemy when when data is loaded from local 
    soap file instead of from web servie call directly.
    '''
    __tablename__ = 'raceday'
    id = Column(Integer, primary_key=True)
    country_code = Column(String)
    country_domestic_text = Column(String)
    country_english_text = Column(String)
    first_race_posttime_date = Column(Date)
    first_race_posttime_time = Column(Time)
    first_race_posttime_utc_time = Column(Time)
    includes_final_race = Column(Boolean)
    international = Column(Boolean)
    international_betting = Column(Boolean)
    meeting_number = Column(Integer)
    meetingtype_code = Column(String)
    meetingtype_domestic_text = Column(String)
    meetingtype_english_text = Column(String)
    racecard_available = Column(Boolean)
    raceday_date = Column(Date)
    trot = Column(Boolean)
    track_id = Column(Integer, ForeignKey('track.id'))
    track = relationship("Track")
    races = relationship('Race')
    
    def __init__(self, racedayinfo=None):
        if racedayinfo:
            self.country_code = racedayinfo.country.code
            self.country_domestic_text = racedayinfo.country.domesticText
            self.country_english_text = racedayinfo.country.englishText
            self.first_race_posttime_date = util.strings_to_date(
                year=racedayinfo.firstRacePostTime.date.year, 
                month=racedayinfo.firstRacePostTime.date.month, 
                date=racedayinfo.firstRacePostTime.date.date
             )
            self.first_race_posttime_time = \
                util.struct_to_time(racedayinfo.firstRacePostTime.time)
            self.first_race_posttime_utc_time = \
                util.struct_to_time(racedayinfo.firstRacePostTimeUTC.time)
            self.includes_final_race = racedayinfo.includesFinalRace
            self.international = racedayinfo.international
            self.international_betting = racedayinfo.internationalBetting
            self.meeting_number = racedayinfo.meetingNumber
            self.meetingtype_code = racedayinfo.meetingType.code
            self.meetingtype_domestic_text = \
                racedayinfo.meetingType.domesticText
            self.meetingtype_english_text = racedayinfo.meetingType.englishText
            self.racecard_available = racedayinfo.raceCardAvailable
            self.raceday_date = util.strings_to_date(
                year=racedayinfo.raceDayDate.year,
                month=racedayinfo.raceDayDate.month,
                date=racedayinfo.raceDayDate.date
            )
            self.trot = racedayinfo.trot

    def __repr__(self):
        params = (
            self.country_code, 
            self.country_domestic_text, 
            self.country_english_text, 
            self.first_race_posttime_date, 
            self.first_race_posttime_time, 
            self.first_race_posttime_utc_time, 
            self.includes_final_race, 
            self.international, 
            self.international_betting, 
            self.meeting_number, 
            self.meetingtype_code, 
            self.meetingtype_domestic_text, 
            self.meetingtype_english_text, 
            self.racecard_available, 
            self.raceday_date, 
            self.track_code, 
            self.track_domestic_text, 
            self.track_english_text, 
            self.track_id, 
            self.trot
        ) 
        part1 = "<Raceday( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params
    
    @staticmethod
    def read_all():
        '''
        List all raceday entities in database
        '''
        return DB_SESSION.query(Raceday).all()
    
    @staticmethod
    def read(entity):
        '''
        Read a raceday entity in database
        '''
        result = DB_SESSION.query(Raceday).filter_by(
            track_id = entity.track_id,
            raceday_date = entity.raceday_date
        ).first()
        return result

class Track(BASE):
    '''
    Database entity Track
    '''
    __tablename__ = 'track'
    id = Column(Integer, primary_key=True)
    atg_id = Column(Integer)
    code = Column(String)
    domestic_text = Column(String)
    english_text = Column(String)

    def __repr__(self):
        params = (
            self.id,
            self.atg_id,
            self.code,
            self.domestic_text,
            self.english_text
        ) 
        part1 = "<Track( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

    @staticmethod
    def read(atg_id=None):
        '''
        Read Track based on parameters
        '''
        result = \
            DB_SESSION.query(Track).filter_by(
                atg_id = atg_id
            ).first()
        return result

RACE_BETTYPE_ASSOCIATION = \
    Table(
        'race_bettype', BASE.metadata,
        Column('id', Integer, primary_key=True),
        Column('race_id', Integer, ForeignKey('race.id')),
        Column('bettype_id', Integer, ForeignKey('bettype.id'))
    )

class RaceHorseAssociation(BASE):
    __tablename__ = 'race_horse_startnumber'
    id = Column(Integer, primary_key=True)
    race_id = Column(Integer, ForeignKey('race.id'))
    horse_id = Column(Integer, ForeignKey('horse.id'))
    start_nr = Column(Integer)
    horse = relationship("Horse")

    @staticmethod
    def read(race_id=None, horse_id=None):
        '''
        Read RaceHorseAssociation based on parameters
        '''
        result = \
            DB_SESSION.query(RaceHorseAssociation).filter_by(
                race_id = race_id,
                horse_id = horse_id
            ).first()
        return result
    
class RaceDriverAssociation(BASE):
    __tablename__ = 'race_driver_startnumber'
    id = Column(Integer, primary_key=True)
    race_id = Column(Integer, ForeignKey('race.id'))
    driver_id = Column(Integer, ForeignKey('driver.id'))
    start_nr = Column(Integer)
    driver = relationship("Driver")

    @staticmethod
    def read(race_id=None, driver_id=None):
        '''
        Read RaceDriverAssociation based on parameters
        '''
        result = \
            DB_SESSION.query(RaceDriverAssociation).filter_by(
                race_id = race_id,
                driver_id = driver_id
            ).first()
        return result

class Race(BASE):
    '''
    Database entity Race
    '''
    __tablename__ = 'race'
    id = Column(Integer, primary_key=True)
    raceday_id = Column(Integer, ForeignKey('raceday.id'))
    has_result = Column(Boolean)
    post_time = Column(Time)
    post_time_utc = Column(Time)
    race_nr = Column(Integer)
    race_type_code = Column(String)
    race_type_domestic_text = Column(String)
    race_type_english_text = Column(String)
    track_surface_code = Column(String)
    track_surface_domestic_text = Column(String)
    track_surface_english_text = Column(String)
    bettypes = relationship('Bettype', secondary=RACE_BETTYPE_ASSOCIATION)
    horses = relationship('RaceHorseAssociation')
    drivers = relationship('RaceDriverAssociation')

    def __init__(self, race=None):
        if race:
            self.has_result = race.hasResult
            self.post_time = util.struct_to_time(race.postTime)
            self.post_time_utc = util.struct_to_time(race.postTimeUTC)
            self.race_nr = race.raceNr
            self.race_type_code = race.raceType.code
            self.race_type_domestic_text = race.raceType.domesticText
            self.race_type_english_text = race.raceType.englishText
            self.track_surface_code = race.trackSurface.code
            self.track_surface_domestic_text = race.trackSurface.domesticText
            self.track_surface_english_text = race.trackSurface.englishText

    def __repr__(self):
        params = (
            self.raceday_id,
            self.has_result,
            self.post_time,
            self.post_time_utc,
            self.race_nr,
            self.bettypes
         ) 
        part1 = "<Race( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

    @staticmethod
    def read(date=None, track_code=None, race_number=None):
        '''
        Read race based on parameters
        '''
        race = \
            DB_SESSION.query(Race).filter(
                Race.raceday_id == Raceday.id,
                Race.race_nr == race_number,
                Raceday.raceday_date == date,
                Raceday.track_id == Track.id,
                Track.code == track_code
            ).first()
        return race

class Bettype(BASE):
    '''
    Database entity Bettype
    Skipping the following fields: 'hasResult', 
    'national', 'races'
    '''
    __tablename__ = 'bettype'
    id = Column(Integer, primary_key=True)
    name_code = Column(String)
    name_domestic_text = Column(String)
    name_english_text = Column(String)

    def __init__(self, bettype=None):
        if bettype:
            self.name_code = bettype.name.code
            self.name_domestic_text = bettype.name.domesticText
            self.name_english_text = bettype.name.englishText
        
    @staticmethod
    def read(entity):
        '''
        Read a bettype entity in database
        '''
        result = DB_SESSION.query(Bettype).filter_by(
            name_code = entity.name_code
        ).first()
        return result
    
    def __repr__(self):
        params = (
            self.name_code,
            self.name_domestic_text,
            self.name_english_text,
        ) 
        part1 = "<Bettype( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

class Horse(BASE):
    '''
    Database entity Horse
    '''
    __tablename__ = 'horse'
    id = Column(Integer, primary_key=True)
    atg_id = Column(Integer, unique=True)
    name = Column(String)
    name_and_nationality = Column(String) 
    seregnr = Column(String)
    uelnnr = Column(String)

    @staticmethod
    def read(atg_id=None):
        '''
        Read an entity in database
        '''
        result = DB_SESSION.query(Horse).filter_by(
            atg_id = atg_id
        ).first()
        return result
    
    def __repr__(self):
        params = (
            self.id,
            self.atg_id,
            self.name,
            self.name_and_nationality,
            self.seregnr,
            self.uelnnr,
        ) 
        part1 = "<Horse( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

class Driver(BASE):
    '''
    Database entity Driver
    '''
    __tablename__ = 'driver'
    id = Column(Integer, primary_key=True)
    atg_id = Column(Integer, unique=True)
    initials = Column(String)
    name = Column(String)
    shortname = Column(String)
    sport = Column(String)
    surname = Column(String)
    driver_colour = Column(String)
    swedish = Column(Boolean)
    amateur = Column(Boolean)

    @staticmethod
    def read(atg_id=None):
        '''
        Read an entity in database
        '''
        result = DB_SESSION.query(Driver).filter_by(
            atg_id = atg_id
        ).first()
        return result
    
    def __repr__(self):
        params = (
            self.id,
            self.atg_id,
            self.initials,
            self.name,
            self.shortname,
            self.sport,
            self.surname,
            self.driver_colour,
            self.swedish,
            self.amateur
        ) 
        part1 = "<Driver( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

ENGINE = create_engine(conf.AIS_DB_URL, echo=False)
# Important to have sessionmaker at top level
# for global knowledge of connections, pool etc:
SESSION = sessionmaker(bind=ENGINE)
DB_SESSION = SESSION()

def init_db_client(db_init=False):
    '''
    Database initiation
    '''
    if db_init:
        BASE.metadata.drop_all(ENGINE)
        BASE.metadata.create_all(ENGINE)

if __name__ == '__main__':
    exit(0)
