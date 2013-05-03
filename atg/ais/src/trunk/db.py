#-*- coding: utf-8 -*-
'''
Database entities for AIS web service
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy import Date, Time, Boolean, ForeignKey, Table, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relation
import util
import conf

BASE = declarative_base()

class LoadedEODFiles(BASE):
    '''
    Database entity loaded_eod_files
    Table holding names of EOD files already loaded into
    the database.
    '''
    __tablename__ = 'loaded_eod_files'
    id = Column(Integer, primary_key=True)
    filename = Column(String)
    loadtime = Column(DateTime)
    def __init__(self, filename=None, loadtime=None):
        self.filename = filename
        self.loadtime = loadtime
    
    @staticmethod 
    def create(new):
        '''
        Create a LoadedEODFiles entity in database
        '''
        entity = DB_SESSION.add(new)
        DB_SESSION.commit()
        return entity
        
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
    track_code = Column(String)
    track_domestic_text = Column(String)
    track_english_text = Column(String)
    track_id = Column(Integer)
    trot = Column(Boolean)
    races = relation('Race')
    
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
            self.track_code = racedayinfo.track.code
            self.track_domestic_text = racedayinfo.track.domesticText
            self.track_english_text = racedayinfo.track.englishText
            self.track_id = racedayinfo.trackKey.trackId
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
    def create(new):
        '''
        Create a raceday entity in database
        '''
        entity = DB_SESSION.add(new)
        DB_SESSION.commit()
        return entity
        
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

RACE_BETTYPE_ASSOCIATION = Table('race_bettype', BASE.metadata,
        Column('id', Integer, primary_key=True),
        Column('race_id', Integer, ForeignKey('race.id')),
        Column('bettype_id', Integer, ForeignKey('bettype.id'))
    )

RACE_HORSE_ASSOCIATION = \
    Table (
        'race_horse', BASE.metadata,
        Column('id', Integer, primary_key=True),
        Column('race_id', Integer, ForeignKey('race.id')),
        Column('horse_id', Integer, ForeignKey('horse.id'))
    )
    
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
    bettypes = relation('Bettype', secondary=RACE_BETTYPE_ASSOCIATION)
    horses = relation('Horse', secondary=RACE_HORSE_ASSOCIATION)
    race_type_code = Column(String)
    race_type_domestic_text = Column(String)
    race_type_english_text = Column(String)
    track_surface_code = Column(String)
    track_surface_domestic_text = Column(String)
    track_surface_english_text = Column(String)

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
    def create(new):
        '''
        Create a race entity in database
        '''
        entity = DB_SESSION.add(new)
        DB_SESSION.commit()
        return entity

    @staticmethod
    def update_horses(date=None, track=None, race_number=None, horses=None):
        '''
        Update race with starting horses
        according to racingcard data
        '''
        race = DB_SESSION.query(Race).filter(
            Race.raceday_id == Raceday.id,
            Raceday.raceday_date == date,
            Raceday.track_code == track,
            Race.race_nr == race_number
            ).first()
        race.horses = horses
        DB_SESSION.commit()

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
    def create(new):
        '''
        Create a bettype entity in database
        '''
        entity = DB_SESSION.add(new)
        DB_SESSION.commit()
        return entity
    
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

RACINGCARD_HORSE_ASSOCIATION = \
    Table (
        'racingcard_horse', BASE.metadata,
        Column('id', Integer, primary_key=True),
        Column('racingcard_id', Integer, ForeignKey('racingcard.id')),
        Column('horse_id', Integer, ForeignKey('horse.id'))
    )
    
class Racingcard(BASE):
    '''
    Database entity Racingcard
    '''
    __tablename__ = 'racingcard'
    id = Column(Integer, primary_key=True)
    date = Column(Date)
    track_code = Column(String)
    bettype_code = Column(String)
    horses = relation('Horse', secondary=RACINGCARD_HORSE_ASSOCIATION)
    
    def __init__(self, data=None):
        if data:
            self.date = data.date
            self.track_code = data.track_code
            self.bettype_code = data.bettype_code
            self.horses = data.horses
            
    def __repr__(self):
        params = (
            self.id, 
            self.date, 
            self.track_code, 
            self.bettype_code,
            self.horses
        ) 
        part1 = "<Racingcard( "
        part2 = "'%s', " * len(params)
        part3 = ")>"
        return (part1 + part2 + part3) % params
    
    @staticmethod 
    def create(new):
        '''
        Create an entity in database
        '''
        entity = DB_SESSION.add(new)
        DB_SESSION.commit()
        return entity
        
    @staticmethod
    def read_all():
        '''
        List all entities in database
        '''
        return DB_SESSION.query(Racingcard).all()
    
    
    @staticmethod
    def read(entity):
        '''
        Read an entity from database
        '''
        result = DB_SESSION.query(Racingcard).filter_by(
            date = entity.date,
            track_code = entity.track_code
        ).first()
        return result

class Horse(BASE):
    '''
    Database entity Horse
    '''
    __tablename__ = 'horse'
    id = Column(Integer, primary_key=True)
    atg_id = Column(Integer)
    name = Column(String)
    name_and_nationality = Column(String) 
    seregnr = Column(String)
    uelnnr = Column(String)

    def __init__(self, data=None):
        if data:
            self.atg_id = data.atg_id
            self.name = data.name
            self.name_and_nationality = data.name_and_nationality
            self.seregnr = data.seregnr
            self.uelnnr = data.uelnnr
        
    @staticmethod
    def create(new):
        '''
        Create an entity in database
        '''
        entity = DB_SESSION.add(new)
        DB_SESSION.commit()
        return entity
    
    @staticmethod
    def read(entity):
        '''
        Read an entity in database
        '''
        result = DB_SESSION.query(Horse).filter_by(
            name_and_nationality = entity.name_and_nationality
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
