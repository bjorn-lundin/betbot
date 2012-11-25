'''
Contain methods that map to actual AIS WS calls
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
from suds.client import WebFault
import logging
import db

LOG = logging.getLogger('AIS')

def init_ws_client(url, username, password):
    LOG.info('Initiating WS client')
    from suds.client import Client
    ws_client = Client(url, username=username, password=password)
    cache = ws_client.options.cache
    cache.setduration(days=10) #months, weeks, days, hours, seconds
    return ws_client

def write_methods_file(client, datadir):
    '''
    Writing as report of methods and types found in WSDL
    '''
    LOG.info('Writing methods')
    filehandle = open(datadir + '/ais_methods.txt', 'w')
    filehandle.write(str(client))
    filehandle.close()

def write_wsdl_file(client, datadir):
    '''
    Writes the WSDL to file
    '''
    LOG.info('Writing WSDL')
    filehandle = open(datadir + '/ais_wsdl.xml', 'w')
    filehandle.write(str(client.wsdl))
    filehandle.close()

def write_result_file(data_dir, method, result):
    '''
    Writes the result of a method call to file,
    i.e. a description of the resulet object
    '''
    LOG.info('Writing result from ' + method)
    filehandle = open(data_dir + '/' + method + '_OUTPUT.txt', 'w')
    filehandle.write(str(result))
    filehandle.close()

def raceday_calendar(client, data_dir, result_file=True):
    '''
    Calls AIS service fetchRaceDayCalendar
    
    TODO: Check from and to date before creating db entity?
    result.fromdate
    result.todate
    '''
    ais_service_name = 'fetchRaceDayCalendar'
    LOG.info('Calling ' + ais_service_name)
    try:
        result = client.service.fetchRaceDayCalendar()
    except WebFault as fault:
        print ('code=%s, string=%s' 
               % (fault.fault.faultcode, fault.fault.faultstring))
    
    if result_file:
        write_result_file(data_dir, ais_service_name, result)
    
    
    for racedayinfo in result.raceDayInfos.RaceDayInfo:
        # Get and save all bettypes in all races
        # this raceday
        for bettype in racedayinfo.betTypes.BetType:
            bt = db.Bettype(bettype=bettype)
            bt = bt.save()
        # Get all races this raceday
        races = []
        for race in racedayinfo.raceInfos.RaceInfo:
            race_bettypes = []
            # For every race join each bettype
            for btc in race.betTypeCodes.string:
                bt = db.Bettype()
                bt = bt.get(btc)
                race_bettypes.append(bt)
            # Create race, add bettypes and append
            # to collection
            r = db.Race(race)
            r.bettypes = race_bettypes
            races.append(r)
        # Get raceday
        rd = db.Raceday(racedayinfo)
        # Append races
        rd.races = races
        rd.save()

def current_event_sequence_number(client):
    '''
    Calls AIS service fetchCurrentEventSequenceNumber
    '''
    LOG.info('Calling fetchCurrentEventSequenceNumber')
    
    try:
        result = client.service.fetchCurrentEventSequenceNumber()
    except WebFault as fault:
        print ('code=%s, string=%s' 
               % (fault.fault.faultcode, fault.fault.faultstring))
    print(result)

def event_array():
    '''
    Calls AIS service fetchEventArray
    '''
    LOG.info('Calling fetchEventArray')
    pass


def raceday_calendar_simple(client):
    '''
    Calls AIS service fetchRaceDayCalendarSimple
    '''
    LOG.info('Calling fetchRaceDayCalendarSimple')
    result = client.factory.create('ns3:ArrayOfRaceDaySimple')
    print(result) 

    result = client.factory.create('ns3:RaceDaySimple')
    print(result) 
    try:
        result = client.service.fetchRaceDayCalendarSimple()
    except WebFault as fault:
        print ('code=%s, string=%s' 
               % (fault.fault.faultcode, fault.fault.faultstring))
    print(result.raceDay.RaceDaySimple[0].track.domesticText)
    for race in result.raceDay.RaceDaySimple:
        print(race.track.domesticText)

def vp_result(date, track):
    '''
    Calls AIS service fetchVPResult
    '''
    LOG.info('Calling fetchVPResult')
    pass

def vp_result_race(date, track, race_number):
    '''
    Calls AIS service fetchVPResultRace
    '''
    #ns4:AtgDate aDate, ns3:TrackKey aTrack, xs:int aRaceNo, 
    LOG.info('Calling fetchVPResultRace')
    pass

def winners_list(date):
    '''
    Calls AIS service fetchWinnersList
    '''
    LOG.info('Calling fetchWinnersList')
    #ns4:AtgDate aDate, 
    pass
