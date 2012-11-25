from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy import Date, Time, Boolean, ForeignKey, Table
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relation
import util

Base = declarative_base()

class Raceday(Base):
    __tablename__ = 'raceday'
    id = Column(Integer, primary_key=True)
    country_code = Column(String(convert_unicode = True))
    country_domestic_text = Column(String(convert_unicode = True))
    country_english_text = Column(String(convert_unicode = True))
    first_race_posttime_date = Column(Date)
    first_race_posttime_time = Column(Time)
    first_race_posttime_utc_time = Column(Time)
    includes_final_race = Column(Boolean)
    international = Column(Boolean)
    international_betting = Column(Boolean)
    itsp_event_code = Column(String(convert_unicode = True))
    meeting_number = Column(Integer)
    meetingtype_code = Column(String(convert_unicode = True))
    meetingtype_domestic_text = Column(String(convert_unicode = True))
    meetingtype_english_text = Column(String(convert_unicode = True))
    racecard_available = Column(Boolean)
    raceday_date = Column(Date)
    track_code = Column(String(convert_unicode = True))
    track_domestic_text = Column(String(convert_unicode = True))
    track_english_text = Column(String(convert_unicode = True))
    track_id = Column(Integer)
    trot = Column(Boolean)
    races = relation('Race')
    
    def __init__(self, racedayinfo=None):
        if racedayinfo:
            self.country_code = racedayinfo.country.code
            self.country_domestic_text = racedayinfo.country.domesticText
            self.country_english_text = racedayinfo.country.englishText
            self.first_race_posttime_date = \
                util.struct_to_date(racedayinfo.firstRacePostTime.date)
            self.first_race_posttime_time = \
                util.struct_to_time(racedayinfo.firstRacePostTime.time)
            self.first_race_posttime_utc_time = \
                util.struct_to_time(racedayinfo.firstRacePostTimeUTC.time)
            self.includes_final_race = racedayinfo.includesFinalRace
            self.international = racedayinfo.international
            self.international_betting = racedayinfo.internationalBetting
            self.itsp_event_code = racedayinfo.itspEventCode
            self.meeting_number = racedayinfo.meetingNumber
            self.meetingtype_code = racedayinfo.meetingType.code
            self.meetingtype_domestic_text = racedayinfo.meetingType.domesticText
            self.meetingtype_english_text = racedayinfo.meetingType.englishText
            self.racecard_available = racedayinfo.raceCardAvailable
            self.raceday_date = \
                util.struct_to_date(racedayinfo.raceDayDate)
            self.track_code = racedayinfo.track.code
            self.track_domestic_text = racedayinfo.track.domesticText
            self.track_english_text = racedayinfo.track.englishText
            self.track_id = racedayinfo.trackKey.trackId
            self.trot = racedayinfo.trot
        
    def save(self):
        result = util.get_or_create \
        (
            DB_SESSION,
            Raceday,
            self,
            track_id = self.track_id,
            first_race_posttime_date = \
                self.first_race_posttime_date,
        )
        return result

    def __repr__(self):
        part1 = "<Raceday( "
        part2 = "'%s', " * 21
        part3 = ")>"
        return (part1 + part2 + part3) % \
        (
            self.country_code, 
            self.country_domestic_text, 
            self.country_english_text, 
            self.first_race_posttime_date, 
            self.first_race_posttime_time, 
            self.first_race_posttime_utc_time, 
            self.includes_final_race, 
            self.international, 
            self.international_betting, 
            self.itsp_event_code, 
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

race_bettype_association = Table('race_bettype', Base.metadata,
        Column('id', Integer, primary_key=True),
        Column('race_id', Integer, ForeignKey('race.id')),
        Column('bettype_id', Integer, ForeignKey('bettype.id'))
    )

class Race(Base):
    __tablename__ = 'race'
    id = Column(Integer, primary_key=True)
    raceday_id = Column(Integer, ForeignKey('raceday.id'))
    has_result = Column(Boolean)
    post_time = Column(Time)
    post_time_utc = Column(Time)
    race_nr = Column(Integer)
    bettypes = relation('Bettype', secondary=race_bettype_association)

    def __init__(self, race=None):
        if race:
            self.has_result = race.hasResult
            self.post_time = util.struct_to_time(race.postTime)
            self.post_time_utc = util.struct_to_time(race.postTimeUTC)
            self.race_nr = race.raceNr
        
    def save(self):
        result = DB_SESSION.add(self)
        DB_SESSION.commit()
        return result
    
    def __repr__(self):
        part1 = "<Race( "
        part2 = "'%s', " * 6
        part3 = ")>"
        return (part1 + part2 + part3) % \
        (
            self.raceday_id,
            self.has_result,
            self.post_time,
            self.post_time_utc,
            self.race_nr,
            self.bettypes
         ) 

class Bettype(Base):
    '''
    TODO: Where does these fields belong
    has_result = Column(Boolean) -> bettype.hasResult
    national = Column(Boolean) -> bettype.national
    races_int = Column(Integer) -> bettype.races.int
    '''
    __tablename__ = 'bettype'
    id = Column(Integer, primary_key=True)
    name_code = Column(String(convert_unicode = True))
    name_domestic_text = Column(String(convert_unicode = True))
    name_english_text = Column(String(convert_unicode = True))

    def __init__(self, bettype=None):
        if bettype:
            self.name_code = bettype.name.code
            self.name_domestic_text = bettype.name.domesticText
            self.name_english_text = bettype.name.englishText
        
    def save(self):
        result = util.get_or_create \
        (
            DB_SESSION, 
            Bettype, 
            self, 
            name_code = self.name_code
        )
        return result
    
    def get(self, btc):
        result = DB_SESSION.query(Bettype)\
            .filter_by(name_code = btc).first()
        return result
    
    def __repr__(self):
        part1 = "<Bettype( "
        part2 = "'%s', " * 3
        part3 = ")>"
        return (part1 + part2 + part3) % \
        (
            self.name_code,
            self.name_domestic_text,
            self.name_english_text,
        ) 

DB_SESSION = None

def init_db_client(db_url, db_init=False):
    global DB_SESSION #pylint: disable-msg=W0603
    engine = create_engine(db_url, echo=False)
    session = sessionmaker(bind=engine)
    DB_SESSION = session()
    if db_init:
        Base.metadata.drop_all(engine)
        Base.metadata.create_all(engine)

if __name__ == '__main__':
    exit(0)
