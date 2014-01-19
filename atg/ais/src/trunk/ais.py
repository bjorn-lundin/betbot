#-*- coding: utf-8 -*-
'''
Contain methods that map to actual AIS WS calls
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import db
import util
import datetime
import time
import conf
import ais_httpclient
import re

LOG = logging.getLogger('AIS')

def call_ais_service(params=None, date=None, track_id=None):
    '''
    Call an AIS web service
    '''
    ais_service = params['service']
    ais_version=params['ais_version']
    ais_type=params['ais_type']
    LOG.info('Calling ' + ais_service 
             + ' with date={0}, track={1}'
             .format(date, track_id))
    result = None
    filename, filename_re = util.generate_file_name_2(
        ais_service=ais_service,
        date=date,
        track_id=track_id,
        ais_version=ais_version,
        ais_type=ais_type
    )
    # If the result has already been downloaded do nothing
    datapath = params['datadir']
    filelist = util.list_files(datapath)
    
    # When introducing new AIS version (AIS 9) the AIS
    # version number can no longer be part of comparison
    
    fn_re = re.compile(filename_re)
    
#     if filelist and filename in filelist:
    filematch = False
    if filelist:
        for file in filelist:
            m = fn_re.match(file)
            if m is not None:
                filematch = True
                break
    if filematch:
        LOG.debug('Data already saved in {0}'
                 .format(filename))
    else:
        request_data = util.get_request_data(
            ais_service=ais_service, 
            date=date, 
            track_id=track_id
        )
        result = ais_httpclient.get_data(request_data=request_data)
        if result is None:
            LOG.error('Service call resulted in empty (None) result')
        else:
            filepath = util.create_file_path(
                params['datadir'], 
                filename
            )
            util.write_file(
                data=result, 
                filepath=filepath
            )
        if 'download_delay' in params:
            download_delay = params['download_delay']
            if download_delay > 0:
                LOG.debug(
                    'Delaying download with ' + 
                    str(download_delay) + ' seconds'
                )
                time.sleep(download_delay)
    
def raceday_calendar_service(params=None, date=None):
    '''
    Calls AIS service fetchRaceDayCalendar
    '''
    params['service'] = 'fetchRaceDayCalendar'
    call_ais_service(params=params, date=date)
        
def racing_card_service(params=None, date=None, track_id=None):
    '''
    Calls AIS service fetchRacingCard
    
    Racing cards consists of a lot of static information and 
    should be fetched sparingly. Racing cards should only be 
    fetched for upcoming races.
    '''
    params['service'] = 'fetchRacingCard'
    call_ais_service(params=params, date=date, track_id=track_id)

def bettype_racing_card_service(params=None, date=None, 
                                bettype=None, track_id=None):
    '''
    Introduced in AIS 9 to be able to fetch racing cards for 
    multiple track pools
    
    Calls AIS service fetchBetTypeRacingCard
    
    Racing cards consists of a lot of static information and 
    should be fetched sparingly. Racing cards should only be 
    fetched for upcoming races.
    '''
    params['service'] = 'fetch' + bettype + 'RacingCard'
    call_ais_service(params=params, date=date, track_id=track_id)

def track_bet_info_service(params=None, date=None, track_id=None):
    '''
    Calls AIS service fetchTrackBetInfo
    
    To get scratchings, driver changes and track condition 
    for upcoming meetings, use the event handling mechanism 
    and/or the fetchTrackBetInfo method.
    '''
    params['service'] = 'fetchTrackBetInfo'
    call_ais_service(params=params, date=date, track_id=track_id)

def raceday_result_service(params=None, date=None, track_id=None):
    '''
    Calls AIS service fetchRaceDayResult
    
    Returns a comprehensive result for all races 
    and horses at the race day
    '''
    params['service'] = 'fetchRaceDayResult'
    call_ais_service(params=params, date=date, track_id=track_id)

def winner_list_service(params=None, date=None):
    '''
    Calls AIS service fetchWinnersList
    
    This method returns a WinnersList array which holds 
    information about the winning high value systems for 
    the bettypes V86, V75, V65, V64, V5 and V4.
    '''
    params['service'] = 'fetchWinnersList'
    call_ais_service(params=params, date=date)

def pool_info_service(params=None, bettype=None, date=None, track_id=None):
    '''
    Calls AIS service fetchXXPoolInfo
    
    Fetch pool information for the chosen bet type.
    '''
    params['service'] = 'fetch' + bettype + 'PoolInfo'
    
    # TODO: See conf for problem description
    for bettype_exclude in conf.AIS_RACEDAY_BETTYPE_EXCLUDE:
        if \
        (bettype == bettype_exclude['bettype']) and \
        (date == bettype_exclude['date']) and \
        (track_id == bettype_exclude['track']):
            LOG.info('Excluding PoolInfo bettype: ' + bettype + ', date: ' 
                     + str(date) + ', track: ' + str(track_id))
            return
    call_ais_service(params=params, date=date, track_id=track_id)
    
def result_service(params=None, bettype=None, date=None, track_id=None):
    '''
    Calls AIS service fetchXXResult
    
    Fetch tote result information for the chosen bet type.
    '''
    params['service'] = 'fetch' + bettype + 'Result'
    
    # TODO: See conf for problem description
    for bettype_exclude in conf.AIS_RACEDAY_BETTYPE_EXCLUDE:
        if \
        (bettype == bettype_exclude['bettype']) and \
        (date == bettype_exclude['date']) and \
        (track_id == bettype_exclude['track']):
            LOG.info('Excluding Result bettype: ' + bettype + ', date: ' 
                     + str(date) + ', track: ' + str(track_id))
            return
    call_ais_service(params=params, date=date, track_id=track_id)

def event_array_service(params=None):
    '''
    Calls AIS service fetchEventArray
    
    Clients using the AIS for live updates must use 
    the Event handling mechanism.
    '''
    params['service'] = 'fetchEventArray'
    call_ais_service(params=params)

def load_eod_raceday_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    racecard files and save the data into database.
    '''
    import raceday_data
    raceday_data.load_into_db(datadir=datadir)

def load_eod_racingcard_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    racecard files and save the data into database.
    '''
    import racingcard_data
    racingcard_data.load_into_db(datadir=datadir)

def load_eod_vppoolinfo_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    vppoolinfo files and save the data into database.
    '''
    import vppoolinfo_data
    vppoolinfo_data.load_into_db(datadir=datadir)

def load_eod_vpresult_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    vpresult files and save the data into database.
    '''
    import vpresult_data
    vpresult_data.load_into_db(datadir=datadir)

def load_eod_ddpoolinfo_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    ddpoolinfo files and save the data into database.
    '''
    import ddpoolinfo_data
    ddpoolinfo_data.load_into_db(datadir=datadir)

def load_eod_ddresult_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    ddresult files and save the data into database.
    '''
    import ddresult_data
    ddresult_data.load_into_db(datadir=datadir)

def load_eod_racedayresult_into_db(datadir=None):
    '''
    Pass on the call to iterate over all saved (local) 
    racedayresult files and save the data into database.
    '''
    import racedayresult_data
#    racedayresult_data.load_into_db(datadir=datadir)
    racedayresult_data.print_all_data(datadir=datadir)
    
def eod_download_via_calendar(params=None):
    '''
    The purpose of this method is to fetch historic
    an/or end of day data late at night every day.
    '''
    # Bettype name_code to service name mapping
    bettype_servicename = {
        'DD':'DD', # Dagens Dubbel
        'K':'Komb',
        'LD':'LD', # Lunch Dubbel
        'LK':'Komb', # Lördagskomb
        'P':'VP', # Plats
        'SK':'Komb', # Specialkomb
        'SOK':'Komb', # Söndagskomb
        'T':'Trio',
        'TV':'Tvilling',
        'V':'VP', # Vinnare
        'V3':'V3',
        'V4':'V4',
        'V5':'V5',
        'V64':'V64',
        'V65':'V65',
        'V75':'V75',
        'V86':'V86'
    }

    raceday_calendar_service(params=params)
    # Download further down rely on racedays in database
    load_eod_raceday_into_db(params['datadir'])
    event_array_service(params=params)
    racedays = db.Raceday.read_all()
#    now = datetime.datetime.now() - datetime.timedelta(days=1)
    now = datetime.datetime.now()
    date_now = datetime.date(now.year, now.month, now.day)
    raceday_exclude = params['raceday_exclude']
    
    for raceday in racedays:
        date = raceday.raceday_date
        track = db.Track.read(pk_id=raceday.track_id)
        track_id = track.atg_id
        raceday_date = datetime.date(date.year, date.month, date.day)
        virt_track_id = raceday.virt_track_id
        virt_bettypes = None
        if virt_track_id is not None:
            virt_bettypes = db.Bettype.virtual_bettypes_set(
                raceday_date=raceday_date, 
                virt_track_id=raceday.virt_track_id
            )
        
        # Upcomming raceday
        if raceday_date == (date_now + datetime.timedelta(days=1)):
            pass
        
        # Raceday with result in ATG database, from today and 
        # backwards according to AIS_RACEDAY_HISTORY
        date_then = None
        if params['ais_type'] == 'test':
            date_then = raceday_date
        else:
            raceday_history = params['raceday_history']
            date_then = date_now - datetime.timedelta(days=raceday_history)
        
        if raceday_date <= date_now and \
                raceday_date >= date_then:
            
            # Some racedays don't have the data they should. Check if
            # this raceday is stated in exclude list
            date_str = str(raceday_date)
            if date_str in raceday_exclude and \
                    track_id in raceday_exclude[date_str]:
                LOG.info('Raceday exclude date={date}, track={track_id}'
                 .format(track_id=track_id, date=raceday_date))
                continue
        
            racing_card_service(
                params=params, 
                date=date, 
                track_id=track_id
            )
            
            if virt_track_id is not None:
                for bettype in virt_bettypes:
                    bettype_racing_card_service(
                        params=params, 
                        date=date,
                        bettype=bettype,
                        track_id=virt_track_id
                    )
            
            track_bet_info_service(
                params=params, 
                date=date, 
                track_id=track_id,
            )
            
            raceday_result_service(
                params=params, 
                date=date, 
                track_id=track_id,
            )

            for race in raceday.races:
                for bettype in race.bettypes:
                    bettype = bettype_servicename[bettype.name_code]
                    this_track_id = track_id
                    if virt_bettypes and bettype in virt_bettypes:
                        this_track_id = virt_track_id
                    pool_info_service(
                        params=params, 
                        bettype=bettype, 
                        date=date, 
                        track_id=this_track_id,
                    )
                    result_service(
                        params=params, 
                        bettype=bettype, 
                        date=date, 
                        track_id=this_track_id,
                    )
