#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Database entities for PPM
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals

from sqlalchemy import create_engine, Column, Integer, String, Numeric, UniqueConstraint, Index
from sqlalchemy import Date, Time, Boolean, ForeignKey, Table, DateTime
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.exc import IntegrityError
import log
import conf

LOG = log.logger
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
        DB_SESSION.rollback()
        return False
    return True

class Company(BASE):
    '''
    Database entity Company
    '''
    __tablename__ = 'company'
    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
    funds = relationship('Fund')
    
    @staticmethod
    def read(name=None):
        '''
        Read a company entity in database
        '''
        result = DB_SESSION.query(Company).filter_by(
            name = name
        ).first()
        return result

class Fund(BASE):
    '''
    Database entity Fund
    '''
    __tablename__ = 'fund'
    id = Column(Integer, primary_key=True, autoincrement=False)
    name = Column(String)
    company_id = Column(Integer, ForeignKey('company.id'))
    quotes = relationship('Quote')
    UniqueConstraint('id', 'name', name='fund_id_name')
    
    @staticmethod
    def read(id=None):
        '''
        Read a fund entity in database
        '''
        result = DB_SESSION.query(Fund).filter_by(
            id = id
        ).first()
        return result

class Quote(BASE):
    '''
    Database entity Quote
    '''
    __tablename__ = 'quote'
    id = Column(Integer, primary_key=True)
    fund_id = Column(Integer, ForeignKey('fund.id'))
    date = Column(Date)
    currency_price_buy = Column(Numeric)
    currency_price_sell = Column(Numeric)
    price_buy = Column(Numeric)
    price_sell = Column(Numeric)
    sek_price_buy = Column(Numeric)
    sek_price_sell = Column(Numeric)
    __table_args__ = \
        (UniqueConstraint(
            'fund_id', 
            'date', 
            name='fundid_date_unigue'),
        )
    
    @staticmethod
    def read(fund_id=None, date=None):
        '''
        Read a quote entity in database
        '''
        result = DB_SESSION.query(Quote).filter_by(
            fund_id = fund_id,
            date = date
        ).first()
        return result

Index("fundid_date_idx", Quote.fund_id, Quote.date)

ENGINE = create_engine(conf.DB_URL, echo=False, 
                       connect_args={'sslmode':conf.DB_SSL})

# Important to have sessionmaker at top level
# for global knowledge of connections, pool etc:
SESSION = sessionmaker(bind=ENGINE)
DB_SESSION = SESSION()
def init_db():
    '''
    Database initiation
    '''
    try:
        BASE.metadata.drop_all(ENGINE)
        BASE.metadata.create_all(ENGINE)
    except:
        session.rollback()
        raise
    finally:
        DB_SESSION.close()

if __name__ == '__main__':
    init_db()
