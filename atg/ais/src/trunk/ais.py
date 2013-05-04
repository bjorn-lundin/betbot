#-*- coding: utf-8 -*-
'''
Contain methods that map to actual AIS WS calls
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
from suds.client import MethodNotFound, WebFault
from urllib2 import URLError
import logging
import db
import util
import socket
import datetime
import re
import time

LOG = logging.getLogger('AIS')

def init_ws_client(url, username, password):
    '''
    Initiates SUDS WS client
    Use static WSDL file instead of relying on cache?
    See ->
    http://stackoverflow.com/questions/7739613/python-soap-client-use-suds-or-something-else
    '''
    LOG.info('Initiating WS client')
    from suds.client import Client
    ws_client = Client(
        url,
        username=username,
        password=password,
        timeout=180  #timeout in seconds
    )
    cache = ws_client.options.cache
    cache.setduration(days=10) #months, weeks, days, hours, seconds
    return ws_client

def call_ais_service(params=None, date=None, track=None, 
                     ret_if_local=False, download_delay=0):
    '''
    Call an AIS web service
    '''
    LOG.info('Calling ' + params['service'] 
             + ' with date={date}, track={track}'
             .format(date=date, track=track))
    result = None
    file_name_dict = None
    xml_data = None
    
    if date and track:
        file_name_dict = util.generate_file_name(
            datadir=params['datadir'],
            ais_service=params['service'],
            date=date,
            track=track,
            ais_version=params['ais_version'],
            ais_type=params['ais_type']
        )
    elif date and not track:
        # The parameters show this is a filename
        # for fetchWinnersList or fetchRaceDayCalendar
        # from local history file
        file_name_dict = util.generate_file_name(
            datadir=params['datadir'],
            ais_service=params['service'],
            date=date,
            track='all',
            ais_version=params['ais_version'],
            ais_type=params['ais_type']
        )
    else:
        # The parameters show this is a filename
        # for fetchRaceDayCalendar fetched today
        file_name_dict = util.generate_file_name(
            datadir=params['datadir'],
            ais_service=params['service'],
            date=datetime.datetime.now(),
            track='all',
            ais_version=params['ais_version'],
            ais_type=params['ais_type'],
        )

    # If the result has already been downloaded,
    # read data from downloaded file instead of calling
    # web service
    if params['save_soap_file']:
        filename = file_name_dict['filename']
        datapath = params['datadir']
        filelist = util.list_files(datapath)
        if filelist and filename in filelist:
            if ret_if_local:
                LOG.info('Using excisting file ' + filename)
                xml_data = util.read_file(
                    util.create_file_path(
                        path=datapath,
                        filename=filename
                    )
                )
            else:
                LOG.debug('Data already saved in {filename}'
                         .format(filename=filename))
                return result
    try:
        service_method = getattr(params['client'].service, params['service'])
        if date and track:
            if xml_data:
                result = service_method(
                    util.date_to_struct(params['client'], date),
                    util.track_id_to_struct(params['client'], track),
                    __inject={'reply':xml_data}
                )
            else:
                result = service_method(
                    util.date_to_struct(params['client'], date),
                    util.track_id_to_struct(params['client'], track)
                )
        elif date and not track:
            if xml_data:
                result = service_method(
                    util.date_to_struct(params['client'], date),
                    __inject={'reply':xml_data}
                )
            else:
                result = service_method(
                    util.date_to_struct(params['client'], date)
                )
        else:
            if xml_data:
                result = service_method(__inject={'reply':xml_data})
            else:
                result = service_method()

        if 'download_delay' in params:
            download_delay = params['download_delay']
        if download_delay > 0:
            LOG.debug('Delaying download with ' + 
                      str(download_delay) + ' seconds')
            time.sleep(download_delay)
    except URLError:
        LOG.exception(params['service'])
    except MethodNotFound:
        LOG.exception(params['service'])
    except WebFault:
        LOG.exception(params['service'])
    except socket.timeout:
        LOG.exception(params['service'])
    except socket.error:
        LOG.exception(params['service'])
    except:
        LOG.exception('Unexpected error! ' + params['service'])
    
    if result is None:
        LOG.error('Service call resulted in empty (None) result')
    else:
        if params['save_soap_file'] and xml_data is None:
            filepath = util.create_file_path(
                params['datadir'], 
                file_name_dict['filename']
            )
            util.write_file(
                data=params['client'].last_received(), 
                filepath=filepath
            )
    return result
    
def raceday_calendar_service(params=None, date=None, ret_if_local=False):
    '''
    Calls AIS service fetchRaceDayCalendar
    '''
    params['service'] = 'fetchRaceDayCalendar'
    result = call_ais_service(params=params, date=date, 
                              ret_if_local=ret_if_local)
    if result:
        for racedayinfo in result.raceDayInfos.RaceDayInfo:
            # Get raceday
            raceday = db.Raceday(racedayinfo)
            if not db.Raceday.read(raceday):
                # Get and save all bettypes in all races
                # this raceday
                for bettype in racedayinfo.betTypes.BetType:
                    btype = db.Bettype(bettype=bettype)
                    if not db.Bettype.read(btype):
                        db.create(entity=btype)
                # Get all races this raceday
                races = []
                for race in racedayinfo.raceInfos.RaceInfo:
                    race_bettypes = []
                    # For every race join each bettype
                    for btc in race.betTypeCodes.string:
                        btype = db.Bettype()
                        btype.name_code = btc
                        btype = db.Bettype.read(btype)
                        race_bettypes.append(btype)
                    # Create race, add bettypes and append
                    # to collection
                    race = db.Race(race)
                    race.bettypes = race_bettypes
                    races.append(race)
                # Append races
                raceday.races = races
                db.create(entity=raceday)

def racing_card_service(params=None, date=None, 
                        track=None, ret_if_local=False):
    '''
    Calls AIS service fetchRacingCard
    
    Racing cards consists of a lot of static information and 
    should be fetched sparingly. Racing cards should only be 
    fetched for upcoming races.
    '''
    params['service'] = 'fetchRacingCard'
    call_ais_service(
        params=params, 
        date=date,
        track=track,
        ret_if_local=ret_if_local
    )
    
def track_bet_info_service(params=None, date=None, 
                           track=None, ret_if_local=False):
    '''
    Calls AIS service fetchTrackBetInfo
    
    To get scratchings, driver changes and track condition 
    for upcoming meetings, use the event handling mechanism 
    and/or the fetchTrackBetInfo method.
    '''
    params['service'] = 'fetchTrackBetInfo'
    call_ais_service(params=params, date=date, 
                     track=track, ret_if_local=ret_if_local)

def winner_list_service(params=None, date=None, ret_if_local=False):
    '''
    Calls AIS service fetchWinnersList
    
    This method returns a WinnersList array which holds 
    information about the winning high value systems for 
    the bettypes V86, V75, V65, V64, V5 and V4.
    '''
    params['service'] = 'fetchWinnersList'
    call_ais_service(params=params, date=date, ret_if_local=ret_if_local)

def pool_info_service(params=None, bettype=None, date=None, 
                      track=None, ret_if_local=False):
    '''
    Calls AIS service fetchXXPoolInfo
    
    Fetch pool information for the chosen bet type.
    '''
    params['service'] = 'fetch' + bettype + 'PoolInfo'
    call_ais_service(params=params, date=date, track=track,
                     ret_if_local=ret_if_local)
    
def result_service(params=None, bettype=None, date=None, 
                   track=None, ret_if_local=False):
    '''
    Calls AIS service fetchXXResult
    
    Fetch tote result information for the chosen bet type.
    '''
    params['service'] = 'fetch' + bettype + 'Result'
    call_ais_service(params=params, date=date, track=track,
                     ret_if_local=ret_if_local)

def event_array_service(params=None, ret_if_local=False):
    '''
    Calls AIS service fetchEventArray
    
    Clients using the AIS for live updates must use 
    the Event handling mechanism.
    '''
    params['service'] = 'fetchEventArray'
    call_ais_service(params=params, ret_if_local=ret_if_local)

def load_eod_raceday_into_db(params=None):
    '''
    Iterate over all saved (local) raceday calendar files and 
    save the data into database.
    '''
    filelist = sorted(util.list_files(params['datadir']))
    calendar_filelist = [f for f in filelist if 'fetchRaceDayCalendar' in f]
    pattern = re.compile(r'.*?(\d\d\d\d)(\d\d)(\d\d).*?') # r = raw string
    # Get all loaded filenames from db
    all_loaded = db.LoadedEODFiles.read_all()
    loaded_files = []
    for loaded in all_loaded:
        loaded_files.append(loaded.filename)
    # Compare with filename
    for filename in calendar_filelist:
        if filename not in loaded_files:
            now = datetime.datetime.now()
            lef = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=lef)
        
            result = re.match(pattern, filename)
            raceday_date = datetime.date(
                int(result.group(1)),
                int(result.group(2)),
                int(result.group(3))
            )
            LOG.info('Loading ' + filename + ' into db')
            raceday_calendar_service(params=params, date=raceday_date, 
                                     ret_if_local=True)
        
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
    vppoolinfo_data.print_all_data(datadir=datadir)

def eod_download_via_calendar(params=None):
    '''
    The purpose of this method is to fetch historic
    an/or end of day data late at night every day.
    '''
    # Bettype name_code to service name mapping
    bettype_loopup = {
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

    raceday_calendar_service(params=params, ret_if_local=True)
    event_array_service(params=params)
    racedays = db.Raceday.read_all()
#    now = datetime.datetime.now() - datetime.timedelta(days=1)
    now = datetime.datetime.now()
    date_now = datetime.date(now.year, now.month, now.day)
    raceday_exclude = params['raceday_exclude']
    
    for raceday in racedays:
        date = raceday.raceday_date
        track = raceday.track_id
        raceday_date = datetime.date(date.year, date.month, date.day)
        
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
            if track in raceday_exclude and \
                    str(raceday_date) == raceday_exclude[track]:
                LOG.info('Raceday exclude date={date}, track={track}'
                 .format(track=track, date=raceday_date))
                continue
        
            racing_card_service(
                params=params, 
                date=date, 
                track=track,
            )
            
            track_bet_info_service(
                params=params, 
                date=date, 
                track=track,
            )

            for race in raceday.races:
                for bettype in race.bettypes:
                    bettype = bettype_loopup[bettype.name_code]
                    pool_info_service(
                        params=params, 
                        bettype=bettype, 
                        date=date, 
                        track=track, 
                    )
                    
                    result_service(
                        params=params, 
                        bettype=bettype, 
                        date=date, 
                        track=track,
                    )
