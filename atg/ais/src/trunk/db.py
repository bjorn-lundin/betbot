#-*- coding: utf-8 -*-
'''
Database entities for AIS web service
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

from sqlalchemy import create_engine, Column, Integer, String, Numeric
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

class RacedayCalendar(BASE):
    '''
    Database entity RacedayCalendar
    '''
    __tablename__ = 'raceday_calendar'
    id = Column(Integer, primary_key=True)
    from_date = Column(Date)
    to_date = Column(Date)

    def __repr__(self):
        params = (
            self.id, 
            self.from_date, 
            self.to_date
        ) 
        part1 = "<RacedayCalendar( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params
    
    @staticmethod
    def read(from_date=None, to_date=None):
        '''
        Read a raceday entity in database
        '''
        result = DB_SESSION.query(RacedayCalendar).filter_by(
            from_date = from_date,
            to_date = to_date
        ).first()
        return result

class Raceday(BASE):
    '''
    Database entity Raceday
    Skipping the fields:
    * itspEventCode
    * country_domestic_text (country_code suffice)
    * country_english_text (country_code suffice)

    '''
    __tablename__ = 'raceday'
    id = Column(Integer, primary_key=True)
    country_code = Column(String)
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

    def __repr__(self):
        params = (
            self.country_code, 
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
            self.trot,
            self.track_id 
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
    def read(track_id=None, raceday_date=None):
        '''
        Read a raceday entity in database
        '''
        result = DB_SESSION.query(Raceday).filter_by(
            track_id = track_id,
            raceday_date = raceday_date
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
    def read(pk_id=None, atg_id=None):
        '''
        Read Track based on parameters pk_id OR atg_id
        '''
        result = None
        if pk_id is not None:
            result = \
                DB_SESSION.query(Track).filter_by(
                    id = pk_id
                ).first()
        elif atg_id is not None:
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
    raceday_id = Column(Integer, ForeignKey('raceday.id'))
    raceday = relationship('Raceday')
    bettypes = relationship('Bettype', secondary=RACE_BETTYPE_ASSOCIATION)
    horses = relationship('RaceHorseAssociation')
    drivers = relationship('RaceDriverAssociation')

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
    def read(raceday_date=None, race_nr=None, 
             track_atg_id=None, track_code=None):
        '''
        Read race based on parameters track_atg_id OR track_code
        '''
        result = None
        if track_atg_id is not None:
            result = \
                DB_SESSION.query(Race).filter(
                    Race.raceday_id == Raceday.id,
                    Race.race_nr == race_nr,
                    Raceday.raceday_date == raceday_date,
                    Raceday.track_id == Track.id,
                    Track.atg_id == track_atg_id
                ).first()
        elif track_code is not None:
            result = \
                DB_SESSION.query(Race).filter(
                    Race.raceday_id == Raceday.id,
                    Race.race_nr == race_nr,
                    Raceday.raceday_date == raceday_date,
                    Raceday.track_id == Track.id,
                    Track.code == track_code
                ).first()
        return result

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
    has_result = Column(Boolean)
    national = Column(Boolean)

    def __repr__(self):
        params = (
            self.name_code,
            self.name_domestic_text,
            self.name_english_text,
            self.has_result,
            self.national
        ) 
        part1 = "<Bettype( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

    @staticmethod
    def read(name_code=None):
        '''
        Read a bettype entity in database
        '''
        result = DB_SESSION.query(Bettype).filter_by(
            name_code = name_code
        ).first()
        return result

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

class VPPoolInfo(BASE):
    '''
    Database entity VPPoolInfo
    
    Skipping turnover_sum (turnover.sum) and 
    turnover_currency (turnover.currency) 
    since they seem empty all the time
    '''
    __tablename__ = 'vppoolinfo'
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime)
    pool_closed = Column(Boolean)
    sale_open = Column(Boolean)
    number_of_horses = Column(Integer)
    turnover_win_sum = Column(Integer)
    turnover_win_currency = Column(String)
    turnover_place_sum = Column(Integer)
    turnover_place_currency = Column(String)
    race_id = Column(Integer, ForeignKey('race.id'))
    race = relationship('Race')
    
    def __repr__(self):
        params = (
            self.id,
            self.timestamp,
            self.pool_closed,
            self.sale_open,
            self.number_of_horses,
            self.turnover_win_sum,
            self.turnover_win_currency,
            self.turnover_place_sum,
            self.turnover_place_currency,
            self.race_id,
        ) 
        part1 = "<VPPoolInfo( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

    @staticmethod
    def read(race_id=None, timestamp=None):
        '''
        Read an entity in database
        '''
        result = DB_SESSION.query(VPPoolInfo).filter_by(
            race_id = race_id,
            timestamp = timestamp
        ).first()
        return result

class Vpodds(BASE):
    __tablename__ = 'vpodds'
    id = Column(Integer, primary_key=True)
    invest_place_sum = Column(Integer)
    invest_place_currency = Column(String)
    invest_win_sum = Column(Integer)
    invest_win_currency = Column(String)
    place_max_odds = Column(Integer)
    place_max_scratched = Column(Boolean)
    place_min_odds = Column(Integer)
    place_min_scratched = Column(Boolean)
    scratched = Column(Boolean)
    start_nr = Column(Integer)
    win_odds = Column(Integer)
    win_scratched = Column(Boolean)
    race_id = Column(Integer, ForeignKey('race.id'))
    race = relationship('Race')
    
    @staticmethod
    def read(race_id=None, start_nr=None):
        '''
        Read Vpodds based on parameters
        '''
        result = \
            DB_SESSION.query(Vpodds).filter_by(
                race_id = race_id,
                start_nr = start_nr
            ).first()
        return result

class VPResult(BASE):
    '''
    Database entity VPResult
    
    Skipping the following fields due to no data/same data:
    * turnover_sum (no data)
    * All turnover currency (always SEK)
    * coupled_horses_winning (always False)
    * win_stables (no data)
    * scratchings (no data)
    '''
    __tablename__ = 'vpresult'
    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime)
    pool_closed = Column(Boolean)
    sale_open = Column(Boolean)
    turnover_win_sum = Column(Integer)
    turnover_place_sum = Column(Integer)
    race_id = Column(Integer, ForeignKey('race.id'))
    race = relationship('Race')
    
    def __repr__(self):
        params = (
            self.id,
            self.timestamp,
            self.pool_closed,
            self.sale_open,
            self.turnover_win_sum,
            self.turnover_place_sum,
            self.race_id,
        ) 
        part1 = "<VPResult( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

    @staticmethod
    def read(race_id=None, timestamp=None):
        '''
        Read an entity in database
        '''
        result = DB_SESSION.query(VPResult).filter_by(
            race_id = race_id,
            timestamp = timestamp
        ).first()
        return result

class ToteResult(BASE):
    '''
    Database entity ToteResult
    '''
    __tablename__ = 'toteresult'
    id = Column(Integer, primary_key=True)
    final_odds_place = Column(Numeric)
    final_odds_win = Column(Numeric)
    start_nr = Column(Integer)
    tote_place = Column(Integer)
    win_km_time = Column(String)
    vpresult_id = Column(Integer, ForeignKey('vpresult.id'))
    vpresult = relationship('VPResult')
    
    def __repr__(self):
        params = (
            self.id,
            self.final_odds_place,
            self.final_odds_win,
            self.start_nr,
            self.tote_place,
            self.win_km_time,
            self.vpresult_id,
        ) 
        part1 = "<ToteResult( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

class DDPoolInfo(BASE):
    '''
    Database entity DDPoolInfo
    
    TODO: Replace track_id with race_id when raceday has been fixed (DD-1, DD-2 etc.)
    '''
    __tablename__ = 'ddpoolinfo'
    id = Column(Integer, primary_key=True)
    date = Column(Date)
    timestamp = Column(DateTime)
    pool_closed = Column(Boolean)
    sale_open = Column(Boolean)
    turnover_sum = Column(Integer)
    turnover_currency = Column(String)
    bettype_code = Column(String)
    bettype_domestic_text = Column(String)
    bettype_english_text = Column(String)
    nr_of_horses_leg_1 = Column(Integer)
    nr_of_horses_leg_2 = Column(Integer)
    track_id = Column(Integer, ForeignKey('track.id'))
    track = relationship('Track')

    def __repr__(self):
        params = (
            self.id,
            self.date,
            self.timestamp,
            self.pool_closed,
            self.sale_open,
            self.turnover_sum,
            self.turnover_currency,
            self.bettype_code,
            self.bettype_domesticText,
            self.bettype_englishText,
            self.nr_of_horses_leg_1,
            self.nr_of_horses_leg_2,
            self.track_id,
        ) 
        part1 = "<DDPoolInfo( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params

    @staticmethod
    def read(track_id=None, timestamp=None):
        '''
        Read an entity in database
        '''
        result = DB_SESSION.query(DDPoolInfo).filter_by(
            track_id = track_id,
            timestamp = timestamp
        ).first()
        return result

class DDOdds(BASE):
    __tablename__ = 'ddodds'
    id = Column(Integer, primary_key=True)
    odds = Column(Integer)
    scratched = Column(Boolean)
    start_nr_leg_1 = Column(Integer)
    start_nr_leg_2 = Column(Integer)
    ddpoolinfo_id = Column(Integer, ForeignKey('ddpoolinfo.id'))
    ddpoolinfo = relationship('DDPoolInfo')
    
    @staticmethod
    def read(ddpoolinfo_id=None):
        '''
        Read DDOdds based on parameters
        '''
        result = \
            DB_SESSION.query(DDOdds).filter_by(
                ddpoolinfo_id = ddpoolinfo_id
            ).first()
        return result

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
