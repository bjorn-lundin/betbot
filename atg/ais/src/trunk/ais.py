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
        timeout=30  #timeout in seconds
    )
    cache = ws_client.options.cache
    cache.setduration(days=10) #months, weeks, days, hours, seconds
    return ws_client

def call_ais_service(params=None, date=None, 
                     track=None, ret_if_local=False):
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
        # for fetchWinnersList
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
        # for fetchRaceDayCalendar
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
        file_name = file_name_dict['filename']
        file_list = util.list_files_in_dir(params['datadir'])
        if file_list and file_name in file_list:
            if ret_if_local:
                LOG.info('Using excisting file ' + file_name)
                xml_data = util.read_file(file_name_dict=file_name_dict)
            else:
                LOG.info('Data already saved in {file_name}'
                         .format(file_name=file_name))
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
            util.write_file(result=params['client'].last_received(), 
                            file_name_dict=file_name_dict)
    return result
    
def raceday_calendar(params=None):
    '''
    Calls AIS service fetchRaceDayCalendar
    '''
    params['service'] = 'fetchRaceDayCalendar'
    result = call_ais_service(params=params, ret_if_local=True)
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
                        btype = db.Bettype.create(btype)
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
                db.Raceday.create(raceday)

def racing_card_service(params=None, date=None, 
                        track=None, ret_if_local=False):
    '''
    Calls AIS service fetchRacingCard
    
    Racing cards consists of a lot of static information and 
    should be fetched sparingly. Racing cards should only be 
    fetched for upcoming races.
    '''
    params['service'] = 'fetchRacingCard'
    call_ais_service(params=params, date=date, track=track, 
                     ret_if_local=ret_if_local)
    
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

def download_history_via_calendar(params=None):
    '''
    The purpose of this method is to fetch historic
    data at late at night every day.
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
    # TODO: Add iteration over all
    # saved racedays to eventually enable
    # loading db from scratch with local data
    raceday_calendar(params=params)
    event_array_service(params=params)
    racedays = db.Raceday.read_all()
#    fetch_winner_list={}
#    now = datetime.datetime.now() - datetime.timedelta(days=1)
    now = datetime.datetime.now()
    date_now = datetime.date(now.year, now.month, now.day)

    for raceday in racedays:
        date = raceday.raceday_date
        track = raceday.track_id
        raceday_date = datetime.date(date.year, date.month, date.day)
        
#        if date not in fetch_winner_list.keys():
#            fetch_winner_list[date]=False
        
        # If upcomming raceday
        if raceday_date == (date_now + datetime.timedelta(days=1)):
            pass
        
        # If raceday with result
        if raceday_date <= date_now:
            racing_card_service(
                params=params, 
                date=date, 
                track=track,
                ret_if_local = False
            )
            track_bet_info_service(
                params=params, 
                date=date, 
                track=track,
                ret_if_local = False
            )
            for race in raceday.races:
                for bettype in race.bettypes:
#                    if bt.name_code in \
#                        ['V4', 'V5', 'V64', 'V65', 'V75', 'V86']:
#                        fetch_winner_list[date] = True
                    bettype = bettype_loopup[bettype.name_code]
                    pool_info_service(
                        params=params, 
                        bettype=bettype, 
                        date=date, 
                        track=track, 
                        ret_if_local=False
                    )
                    result_service(
                        params=params, 
                        bettype=bettype, 
                        date=date, 
                        track=track,
                        ret_if_local=False
                    )
# TODO: Why error NoDataFoundException all the time!!! 
#    for fetch_date in fetch_winner_list.keys():
#        if fetch_date <= date_now:
#            if fetch_winner_list[fetch_date]:
#                winner_list_service(params=params, date=fetch_date,
#                                    ret_if_local=False)
