#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
The main PPM application
'''
from __future__ import unicode_literals
from __future__ import division
from __future__ import absolute_import
from __future__ import print_function
import log
import conf
import os
import datetime
import decimal
import db

LOG = log.logger

def extract_zip(path=None, filename=None):
    '''Extract all zip files in directory

    Keyword arguments:
    directory -- path to directory containing zip files (default None)
    '''
    LOG.info('Examine ' + filename)
    import zipfile
    filehandle = open(os.path.join(path, filename), 'r')
    zip_content = zipfile.ZipFile(filehandle)
    for zipped in zip_content.namelist():
        file_ext = 'txt'
        if '.xls' in zipped:
            file_ext = 'xls'
        new_filename = filename[:-3] + file_ext
        if os.path.exists(os.path.join(path, new_filename)):
            continue
        zip_content.extract(zipped, path)
        zip_outfile = zip_content.getinfo(zipped).filename
        os.rename(
            os.path.join(path, zip_outfile),
            os.path.join(path, new_filename))
        LOG.info('\tUnzip ' + zip_outfile + ' -> ' + new_filename)
    filehandle.close()

def parse_txt_file(filename=None, encoding='iso-8859-1', dev=True):
    '''Read a text file
    
    Keyword arguments:
    filename -- file to read (default None)
    dev -- faster handling during development (default True)

    Fields in order:
    ----------------
    FONDNUMMER
    FONDBOLAG
    FONDNAMN
    VALUTA
    DATUM
    VALUTAKURS_KÖP
    VALUTAKURS_SÄLJ
    FONDKURS_KÖP
    FONDKURS_SÄLJ
    FONDKURS_SEK_KÖP
    FONDKURS_SEK_SÄLJ
    '''
    LOG.info('Parse ' + filename)
    import io
    filehandle = io.open(filename, mode='r', encoding=encoding)
    line_index = 0
    for line in filehandle.readlines():
        if len(line) <= 1:
            continue 
        if line_index == 0:
            if 'hist-fondkurser2006' not in filename:
                line_index += 1
                continue
        line_index += 1
        fields = line.split('\t')
        data = Data()
        if 'hist-fondkurser2006' in filename:
            data.fund_company = fields[0]
            data.fund_number = fields[2]
            data.fund_name = fields[3]
            data.date = fields[11]
            data.currency_price_buy = fields[13]
            data.currency_price_sell = fields[12]
            data.price_buy = fields[14]
            data.price_sell = fields[15]
            data.sek_price_buy = fields[16]
            data.sek_price_sell = fields[17]
        else:
            data.fund_number = fields[0]
            data.fund_company = fields[1]
            data.fund_name = fields[2]
            data.currency = fields[3]
            data.date = fields[4]
            data.currency_price_buy = fields[5]
            data.currency_price_sell = fields[6]
            data.price_buy = fields[7]
            data.price_sell = fields[8]
            data.sek_price_buy = fields[9]
            data.sek_price_sell = fields[10]
        data.create(dev=dev)
        if dev:
            return

def parse_excel_file(filename=None, dev=True):
    '''Read an Excel file

    Keyword arguments:
    filename -- file to read (default None)
    dev -- faster handling during development (default True)

    Fields in order:
    ----------------
    Fondbolag
    Fond-nr
    Fondnamn
    Datum
    Valutakurs sälj
    Valutakurs Köp
    Fondkurs Sälj
    Fondkurs Köp
    Fondkurs i sek köp
    Fondkurs i sek sälj

    Note: No valuta/currency in this file type
    '''
    LOG.info('Parse ' + filename)
    import xlrd
    workbook = xlrd.open_workbook(filename)
    worksheets = workbook.sheet_names()
    for worksheet_name in worksheets:
        worksheet = workbook.sheet_by_name(worksheet_name)
        num_rows = worksheet.nrows - 1
        curr_row = 1
        while curr_row < num_rows:
            curr_row += 1
            data = Data()
            data.fund_number = worksheet.cell_value(curr_row, 1)
            data.fund_company = worksheet.cell_value(curr_row, 0)
            data.fund_name = worksheet.cell_value(curr_row, 2)
            data.date = \
                datetime.datetime(*(xlrd.xldate_as_tuple(
                    worksheet.cell_value(curr_row, 3),
                    workbook.datemode))
                ).date().strftime("%Y-%m-%d")
            data.currency_price_buy = worksheet.cell_value(curr_row, 5)
            data.currency_price_sell = worksheet.cell_value(curr_row, 4)
            data.price_buy = worksheet.cell_value(curr_row, 7)
            data.price_sell = worksheet.cell_value(curr_row, 6)
            data.sek_price_buy = worksheet.cell_value(curr_row, 8)
            data.sek_price_sell = worksheet.cell_value(curr_row, 9)
            data.create(dev=dev)
            if dev:
                return

class Data(object):
    '''Data class representing all fields'''
    _datemode = None
    _fund_number = None
    _fund_company = None
    _fund_name = None
    _currency = None
    _date = None
    _currency_price_buy = None
    _currency_price_sell = None
    _price_buy = None
    _price_sell = None
    _sek_price_buy = None
    _sek_price_sell = None
    
    data_names = [
        'fund_number',
        'fund_company',
        'fund_name',
        'currency',
        'date',
        'currency_price_buy',
        'currency_price_sell',
        'price_buy',
        'price_sell',
        'sek_price_buy',
        'sek_price_sell'
    ]

    @staticmethod
    def __create_decimal(value=None):
        '''
        Number formatting in Excel uses \xa0, e.g. 1 000,25
        instead of 1000,25. The white space character is
        non-breaking space in Latin1 (ISO 8859-1), also chr(160).
        '''
        # TODO Compare values with Fondandelskurser+Kvartal+1+2010.xls
        # Problem started at 2010-03-31
        value = ((unicode)(value)).replace(u'\xa0', u'')
        value = ((unicode)(value)).replace(u',', u'.')
        return decimal.Decimal(value)

    @property
    def fund_number(self):
        return self._fund_number
    @fund_number.setter
    def fund_number(self, value):
        self._fund_number = int(value)

    @property
    def fund_company(self):
        return self._fund_company
    @fund_company.setter
    def fund_company(self, value):
        self._fund_company = value

    @property
    def fund_name(self):
        return self._fund_name
    @fund_name.setter
    def fund_name(self, value):
        self._fund_name = value

    @property
    def currency(self):
        return self._currency
    @currency.setter
    def currency(self, value):
        self._currency = value

    @property
    def date(self):
        return self._date
    @date.setter
    def date(self, value):
        # Does date stem from Excel?
        if isinstance(value, tuple):
            self._date = datetime.datetime(*value).date()
        else:
            self._date = datetime.datetime.strptime(value, "%Y-%m-%d").date()

    @property
    def currency_price_buy(self):
        return self._currency_price_buy
    @currency_price_buy.setter
    def currency_price_buy(self, value):
        self._currency_price_buy = Data.__create_decimal(value)

    @property
    def currency_price_sell(self):
        return self._currency_price_sell
    @currency_price_sell.setter
    def currency_price_sell(self, value):
        self._currency_price_sell = Data.__create_decimal(value)

    @property
    def price_buy(self):
        return self._price_buy
    @price_buy.setter
    def price_buy(self, value):
        self._price_buy = Data.__create_decimal(value)

    @property
    def price_sell(self):
        return self._price_sell
    @price_sell.setter
    def price_sell(self, value):
        self._price_sell = Data.__create_decimal(value)

    @property
    def sek_price_buy(self):
        return self._sek_price_buy
    @sek_price_buy.setter
    def sek_price_buy(self, value):
        self._sek_price_buy = Data.__create_decimal(value)

    @property
    def sek_price_sell(self):
        return self._sek_price_sell
    @sek_price_sell.setter
    def sek_price_sell(self, value):
        self._sek_price_sell = Data.__create_decimal(value)

    def __repr__(self):
        params = (
            self.data_names[0] + ': ' + (str)(self._fund_number),
            self.data_names[1] + ': ' + self._fund_company,
            self.data_names[2] + ': ' + self._fund_name,
            self.data_names[3] + ': ' + (str)(self._currency),
            self.data_names[4] + ': ' + (str)(self._date),
            self.data_names[5] + ': ' + (str)(self._currency_price_buy),
            self.data_names[6] + ': ' + (str)(self._currency_price_sell),
            self.data_names[7] + ': ' + (str)(self._price_buy),
            self.data_names[8] + ': ' + (str)(self._price_sell),
            self.data_names[9] + ': ' + (str)(self._sek_price_buy),
            self.data_names[10] + ': ' + (str)(self._sek_price_sell)
        )
        part1 = 'Data object:\n'
        part2 = '\t%s\n' * len(params)
        return ((part1 + part2) % params).encode('utf-8')

    def create_old(self, dev=True):
        quote = db.Quote.read(fund_id=self._fund_number, date=self._date)
        if quote is None:
            quote = db.Quote()
            quote.date = self._date
            quote.currency_price_buy = self._currency_price_buy
            quote.currency_price_sell = self._currency_price_sell
            quote.price_buy = self._price_buy
            quote.price_sell = self._price_sell
            quote.sek_price_buy = self._sek_price_buy
            quote.sek_price_sell = self._sek_price_sell
            db.create(quote)
            fund = db.Fund.read(id=self._fund_number)
            if fund is None:
                fund = db.Fund()
                fund.id = self._fund_number
                fund.name = self._fund_name
                fund.quotes.append(quote)
                db.create(fund)
                company = db.Company.read(name=self._fund_company)
                if company is None:
                    company = db.Company()
                    company.name = self._fund_company
                    company.funds.append(fund)
                    db.create(company)
            else:
                fund.quotes.append(quote)
                db.DB_SESSION.commit()

    def create(self, dev=True):
        if dev:
            print(self)
        quote = db.Quote()
        quote.date = self._date
        quote.currency_price_buy = self._currency_price_buy
        quote.currency_price_sell = self._currency_price_sell
        quote.price_buy = self._price_buy
        quote.price_sell = self._price_sell
        quote.sek_price_buy = self._sek_price_buy
        quote.sek_price_sell = self._sek_price_sell
        if not db.create(quote):
            return
        fund = db.Fund()
        fund.id = self._fund_number
        fund.name = self._fund_name
        fund.quotes.append(quote)
        if not db.create(fund):
            return
        company = db.Company()
        company.name = self._fund_company
        company.funds.append(fund)
        if not db.create(company):
            fund.quotes.append(quote)
            db.DB_SESSION.commit()

def load_history(datadir=None, dev=True):
    zipped_file_names = [
        '2000-2008/hist-fondkurser2000',
        '2000-2008/hist-fondkurser2001',
        '2000-2008/hist-fondkurser2002',
        '2000-2008/hist-fondkurser2003',
        '2000-2008/hist-fondkurser2004',
        '2000-2008/hist-fondkurser2005',
        '2000-2008/hist-fondkurser2006',       # TODO: Check order in outcome
        '2000-2008/hist-fondkurser-2007-excel',
        '2000-2008/hist-fondkurser-2008-excel'
    ]
    for filename in zipped_file_names:
        extract_zip(
            path=datadir,
            filename=filename + '.zip')
    for filename in zipped_file_names[0:7]:
        parse_txt_file(
            os.path.join(datadir, filename + '.txt'), 
            dev=dev)
    for filename in zipped_file_names[7:9]:
        parse_excel_file(
            os.path.join(datadir, filename + '.xls'),
            dev=dev)
    file_names = [
        '2009/Fondandelskurser+kvartal+1+2009.xls',
        '2009/Fondandelskurser+kvartal+2+2009.xls',
        '2009/Fondandelskurser+kvartal+3+2009.xls',
        '2009/Fondandelskurser+kvartal+4+2009.xls',
        '2010/Fondandelskurser+Kvartal+1+2010.xls',
        '2010/Fondandelskurser+kvartal+2+2010.xls',
        '2010/Fondandelskurser+kvartal+3+2010.xls',
        '2010/Fondandelskurser+kvartal+4+2010.xls',
        '2011/Fondandelskurser+kvartal+1+2011.xls',
        '2011/Fondandelskurser+kvartal+2+2011.xls',
        '2011/Fondandelskurser+kvartal+3+2011.xls',
        '2011/Fondandelskurser+kvartal+4+2011.xls',
        '2012/Fondandelskurser+kvartal+1+2012.xls',
        '2012/Fondandelskurser+kvartal+2+2012.xls',
        '2012/Fondandelskurser+kvartal+3+2012.xls',
        '2012/Fondandelskurser+kvartal+4+2012.xls',
        '2013/Fondandelskurser+kvartal+1+2013.xls',
        '2013/Fondandelskurser+kvartal+2+2013.xls',
        '2013/Fondandelskurser+kvartal+3+2013.xls',
        '2013/Fondandelskurser+kvartal+4+2013.xls',
        '2014/Fondandelskurser+kvartal+1+2014.xls'
    ]
    for filename in file_names:
        parse_excel_file(
            os.path.join(datadir, filename),
            dev=dev)
    
def main():
    LOG.info('Starting PPM application')
    try:
        load_history(datadir=conf.DATADIR, dev=False)
    except Exception as e:
        db.DB_SESSION.rollback()
        LOG.exception(e)
    finally:
        LOG.info('Ending PPM application')
        db.DB_SESSION.close()
        log.shutdown()
        exit(0)

if __name__ == "__main__":
    main()

