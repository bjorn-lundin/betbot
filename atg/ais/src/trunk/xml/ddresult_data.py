#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Data handling regarding vppoolinfo data
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import util
import db
import datetime
import decimal

LOG = logging.getLogger('AIS')

def load_into_db(datadir=None):
    '''
    Iterate over all saved (local) ddresult files and
    load the data into database
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchDDResult' in f]
    # Get all loaded filenames from db
    loaded_files = []
    for loaded in db.LoadedEODFiles.read_all():
        loaded_files.append(loaded.filename)
    # Compare with filename
    for filepath in racingcard_filelist:
        filename = util.get_filename_from_path(filepath)
        if filename not in loaded_files:
            LOG.info('Parsing ' + filename)
            root = util.get_xml_object(filepath=filepath)
            ddresult = root.Body.fetchDDResultResponse.result
            date = util.strings_to_date(
                ddresult.date.year,
                ddresult.date.month,
                ddresult.date.date
            )
            timestamp = util.params_to_datetime(
                year = ddresult.timestamp.date.year, 
                month = ddresult.timestamp.date.month, 
                day = ddresult.timestamp.date.date, 
                hour = ddresult.timestamp.time.hour, 
                minute = ddresult.timestamp.time.minute, 
                second = ddresult.timestamp.time.second, 
                tenth = ddresult.timestamp.time.tenth
            )
            track_atg_id = int(ddresult.trackKey.trackId)
            track = db.Track.read(atg_id=track_atg_id)
            bettype_code = unicode(ddresult.betType.code)
            bettype = db.Bettype.read(name_code=bettype_code)
            ddresult_entity = db.DDResult.read(date=date, track_id=track.id)
            if ddresult_entity is None:
                ddresult_entity = db.DDResult()
                ddresult_entity.date = date
                ddresult_entity.timestamp = timestamp
                ddresult_entity.pool_closed = bool(ddresult.poolClosed)
                ddresult_entity.sale_open = bool(ddresult.saleOpen)
                ddresult_entity.turnover_sum = int(ddresult.turnover.sum)
                ddresult_entity.turnover_currency = unicode(ddresult.turnover.currency)
                ddresult_entity.final_odds = decimal.Decimal(unicode(ddresult.finalOddses.FinalDoubleOdds.finalOdds))
                ddresult_entity.start_nr_leg_1 = int(ddresult.finalOddses.FinalDoubleOdds.startNrLeg1)
                ddresult_entity.start_nr_leg_2 = int(ddresult.finalOddses.FinalDoubleOdds.startNrLeg2)
                ddresult_entity.scratched_leg_1 = unicode(ddresult.scratchedLeg1)
                ddresult_entity.scratched_leg_2 = unicode(ddresult.scratchedLeg2)
                ddresult_entity.possible_oddses = unicode(ddresult.possibleOddses)
                ddresult_entity.winners_leg_1 = int(ddresult.winnersLeg1.int)
                ddresult_entity.winners_leg_2 = int(ddresult.winnersLeg2.int)
                ddresult_entity.track_id = track.id
                ddresult_entity.bettype_id = bettype.id
                db.create(entity=ddresult_entity)
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) ddresult files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchDDResult' in f]
    for filepath in data_filelist:
        filename = util.get_filename_from_path(filepath)
        LOG.debug('Parsing ' + filename)
        xml_string = util.get_cleaned_xml_string(filepath=filepath)
        
        # Convenience flag when developing
        if False:
            util.write_file(
                data=util.get_html_unescape(html_string=xml_string), 
                filepath=filename, 
                encoding='utf-8'
            )
            util.write_file(data=xml_string, filepath=filename, encoding='utf-8')
            exit(0)
        
        root = util.xml_string_to_object(xml_string=xml_string)
        ddresult = root.Body.fetchDDResultResponse.result
        print(ddresult.date.date)
        print(ddresult.date.month)
        print(ddresult.date.year)
        print(ddresult.poolClosed)
        print(ddresult.saleOpen)
        print(ddresult.timestamp.date.date)
        print(ddresult.timestamp.date.month)
        print(ddresult.timestamp.date.year)
        print(ddresult.timestamp.time.hour)
        print(ddresult.timestamp.time.minute)
        print(ddresult.timestamp.time.second)
        print(ddresult.timestamp.time.tenth)
        print(ddresult.track.code)
        print(ddresult.track.domesticText)
        print(ddresult.track.englishText)
        print(ddresult.trackKey.trackId)
        print(ddresult.turnover.currency)
        print(ddresult.turnover.sum)
        print(ddresult.betType.code)
        print(ddresult.betType.domesticText)
        print(ddresult.betType.englishText)
        print(ddresult.finalOddses.FinalDoubleOdds.finalOdds)
        print(ddresult.finalOddses.FinalDoubleOdds.startNrLeg1)
        print(ddresult.finalOddses.FinalDoubleOdds.startNrLeg2)
        print(ddresult.possibleOddses)
        print(ddresult.scratchedLeg1)
        print(ddresult.scratchedLeg2)
        print(ddresult.winnersLeg1.int)
        print(ddresult.winnersLeg2.int)
        
if __name__ == "__main__":
    pass
    