#!/usr/bin/env python
#-*- coding: utf-8 -*-
'''
Data handling regarding raceday data
'''
from __future__ import division, absolute_import
from __future__ import print_function, unicode_literals
import logging
import util
import db
import datetime

LOG = logging.getLogger('AIS')

def load_into_db(datadir=None):
    filelist = sorted(util.list_files_with_path(datadir))
    racingcard_filelist = [f for f in filelist if 'fetchRaceDayCalendar' in f]
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
            racedaycalendar = root.Body.fetchRaceDayCalendarResponse.result
            from_date = util.strings_to_date(
                racedaycalendar.fromdate.year,
                racedaycalendar.fromdate.month,
                racedaycalendar.fromdate.date
            )
            to_date = util.strings_to_date(
                racedaycalendar.todate.year,
                racedaycalendar.todate.month,
                racedaycalendar.todate.date
            )
            racedaycalendar_entity = \
                db.RacedayCalendar.read(from_date, to_date)
            if racedaycalendar_entity is None:
                racedaycalendar_entity = db.RacedayCalendar()
                racedaycalendar_entity.from_date = from_date
                racedaycalendar_entity.to_date = to_date
                db.create(racedaycalendar_entity)
            for racedayinfo in racedaycalendar.raceDayInfos.getchildren():
                track_atg_id = int(racedayinfo.trackKey.trackId)
                track = db.Track.read(atg_id=track_atg_id)
                if track is None:
                    track = db.Track()
                    track.atg_id = track_atg_id
                    track.code = unicode(racedayinfo.track.code)
                    track.domestic_text = unicode(racedayinfo.track.domesticText)
                    track.english_text = unicode(racedayinfo.track.englishText)
                    db.create(track)
                raceday_date = util.strings_to_date(
                    racedayinfo.raceDayDate.year,
                    racedayinfo.raceDayDate.month,
                    racedayinfo.raceDayDate.date
                )
                virt_track_id = None
                virt_bet_types = None
                try:
                    racedayinfo.multipleTrackPoolSetups
                except AttributeError:
                    racedayinfo.multipleTrackPoolSetups = None
                if racedayinfo.multipleTrackPoolSetups is not None:
                    for multipletrackpoolsetup in racedayinfo.multipleTrackPoolSetups.getchildren():
                        # Only one unique virtual track for one raceday
                        if virt_track_id is None:
                            virt_track_id = int(multipletrackpoolsetup.trackKey.trackId)
                        if virt_bet_types is None:
                            virt_bet_types = set()
                        bettype_name_code = unicode(multipletrackpoolsetup.betType.code)
                        bettype_entity = db.Bettype.read(bettype_name_code)
                        if bettype_entity is None:
                            bettype_entity = db.Bettype()
                            bettype_entity.name_code = bettype_name_code
                            bettype_entity.name_domestic_text = unicode(multipletrackpoolsetup.betType.domesticText)
                            db.create(bettype_entity)
                        virt_bet_types.add(bettype_entity)
                raceday = db.Raceday.read(
                    raceday_date=raceday_date, 
                    track_id=track.id, 
                    virt_track_id=virt_track_id)
                if raceday is None:
                    raceday = db.Raceday()
                    raceday.country_code = unicode(racedayinfo.country.code)
                    raceday.country_domestic_text = unicode(racedayinfo.country.domesticText)
                    raceday.country_english_text = unicode(racedayinfo.country.englishText)
                    first_race_date = util.strings_to_date(
                        racedayinfo.firstRacePostTime.date.year,
                        racedayinfo.firstRacePostTime.date.month,
                        racedayinfo.firstRacePostTime.date.date
                    )
                    raceday.first_race_posttime_date = first_race_date
                    first_race_time = util.strings_to_time(
                        hour=racedayinfo.firstRacePostTime.time.hour,
                        minute=racedayinfo.firstRacePostTime.time.minute,
                        second=racedayinfo.firstRacePostTime.time.second,
                        tenth=racedayinfo.firstRacePostTime.time.tenth
                    )
                    raceday.first_race_posttime_time = first_race_time
                    first_race_time_utc = util.strings_to_time(
                        hour=racedayinfo.firstRacePostTimeUTC.time.hour,
                        minute=racedayinfo.firstRacePostTimeUTC.time.minute,
                        second=racedayinfo.firstRacePostTimeUTC.time.second,
                        tenth=racedayinfo.firstRacePostTimeUTC.time.tenth
                    )
                    raceday.first_race_posttime_utc_time = first_race_time_utc
                    raceday.includes_final_race = bool(racedayinfo.includesFinalRace)
                    raceday.international = bool(racedayinfo.international)
                    raceday.international_betting = bool(racedayinfo.internationalBetting)
                    raceday.meeting_number = int(racedayinfo.meetingNumber)
                    raceday.meetingtype_code = unicode(racedayinfo.meetingType.code)
                    raceday.meetingtype_domestic_text = unicode(racedayinfo.meetingType.domesticText)
                    raceday.meetingtype_english_text = unicode(racedayinfo.meetingType.englishText)
                    raceday.racecard_available = bool(racedayinfo.raceCardAvailable)
                    raceday.raceday_date = raceday_date
                    raceday.trot = bool(racedayinfo.trot)
                    raceday.track_id = track.id
                    raceday.virt_track_id = virt_track_id
                    if virt_bet_types is not None:
                        for bet_type in virt_bet_types:
                            raceday.virt_bet_types.append(bet_type)

                    # Parameter added in AIS 9
                    # racedayinfo.canceled
                    try:
                        racedayinfo.canceled
                    except AttributeError:
                        racedayinfo.canceled = False
                    raceday.cancelled = bool(racedayinfo.canceled)
                    db.create(raceday)

                    races_and_bettypes = \
                        get_races_and_bettypes(
                            racedayinfo=racedayinfo,
                            filename=filename
                        )

                    for raceinfo in racedayinfo.raceInfos.getchildren():
                        race_nr = int(raceinfo.raceNr)
                        race = db.Race.read(
                            raceday_date=raceday_date, 
                            race_nr=race_nr,
                            track_atg_id=track_atg_id
                        )
                        if race is None:
                            race = db.Race()
                            race.has_result = bool(raceinfo.hasResult)
                            race.post_time = util.strings_to_time(
                                hour=raceinfo.postTime.hour,
                                minute=raceinfo.postTime.minute,
                                second=raceinfo.postTime.second,
                                tenth=raceinfo.postTime.tenth
                            )
                            race.post_time_utc = util.strings_to_time(
                                hour=raceinfo.postTimeUTC.hour,
                                minute=raceinfo.postTimeUTC.minute,
                                second=raceinfo.postTimeUTC.second,
                                tenth=raceinfo.postTimeUTC.tenth
                            )
                            race.race_nr = race_nr
                            race.race_type_code = unicode(raceinfo.raceType.code)
                            race.race_type_domestic_text = unicode(raceinfo.raceType.domesticText)
                            race.race_type_english_text = unicode(raceinfo.raceType.englishText)
                            race.track_surface_code = unicode(raceinfo.trackSurface.code)
                            race.track_surface_domestic_text = unicode(raceinfo.trackSurface.domesticText)
                            race.track_surface_english_text = unicode(raceinfo.trackSurface.englishText)
                            race.raceday_id = raceday.id
#                             for bettype in races_and_bettypes[race_nr]:
#                                 if isinstance(bettype, db.BettypeChild):
#                                     race.bettype_childs.append(bettype)
#                                 else:
#                                     race.bettypes.append(bettype)
                            for bettype in races_and_bettypes[race_nr]:
                                race.bettypes.append(bettype)
                            
                            # Parameter added in AIS 9
                            # raceinfo.canceled
                            try:
                                raceinfo.canceled
                            except AttributeError:
                                raceinfo.canceled = False
                            race.cancelled = bool(raceinfo.canceled)
                            db.create(race)
                    
            now = datetime.datetime.now()
            loaded_file = db.LoadedEODFiles(filename=filename, loadtime=now)
            db.create(entity=loaded_file)

def get_races_and_bettypes(racedayinfo=None, filename=None):
    '''
    Create struct containing race numbers and 
    all bet type objects belonging to each race 
    '''
#     bettype_nbr_of_legs_index = {
#         'DD':2,
#         'V3':3,
#         'V65':6,
#         'P':0,
#         'TV':0,
#         'V':0,
#         'T':0,
#         'LD':2,
#         'V5':5,
#         'V4':4,
#         'K':0,
#         'V75':7,
#         'SK':0,
#         'V86':8,
#         'V64':6
#     }
    
    races_and_bettypes = {}
    for bettype in racedayinfo.betTypes.getchildren():
        # TODO: Create static list to avoid this check 
        # every time?
        bettype_name_code = unicode(bettype.name.code)
        bettype_entity = db.Bettype.read(bettype_name_code)
        if bettype_entity is None:
            bettype_entity = db.Bettype()
            bettype_entity.name_code = bettype_name_code
            bettype_entity.name_domestic_text = unicode(bettype.name.domesticText)
            db.create(bettype_entity)
#         try:
#             nbr_of_legs = bettype_nbr_of_legs_index[bettype.name.code]
#         except KeyError:
#             LOG.exception('Bet type not registered: ' + bettype_name_code)
#             continue
        race_numbers = []
        for race_nr in bettype.races.getchildren():
            race_numbers.append(race_nr)
#         if len(race_numbers) == 0:
#             LOG.info(
#                 'Bet type ' + bettype_name_code + \
#                 ' is missing races in ' + filename
#             )
#             continue
        # All races will have bettype_code, e.g. V, P and V75
        for race_nbr in race_numbers:
            if race_nbr not in races_and_bettypes:
                races_and_bettypes[race_nbr] = set()
            races_and_bettypes[race_nbr].add(bettype_entity)
        # All combo bets need bettype sub-parts like V75-1 and DD-2
#         if nbr_of_legs > 0:
#             for leg_nbr in range(nbr_of_legs):
#                 bettype_child_name = bettype.name.code + '-' + unicode(leg_nbr+1)
#                 bettype_child_entity = \
#                     db.BettypeChild.read(name_code_child=bettype_child_name)
#                 if bettype_child_entity is None:
#                     bettype_child_entity = db.BettypeChild()
#                     bettype_child_entity.name_code_child = bettype_child_name
#                     bettype_child_entity.bettype_id = bettype_entity.id
#                     db.create(bettype_child_entity)
#                 race_nbr = race_numbers[leg_nbr]
#                 if race_nbr not in races_and_bettypes:
#                     races_and_bettypes[race_nbr] = set()
#                 races_and_bettypes[race_nbr].add(bettype_child_entity)
    return races_and_bettypes    

def print_all_data(datadir=None):
    '''
    Iterate over all saved (local) fetchRaceDayCalendar files and
    print the data.
    '''
    filelist = sorted(util.list_files_with_path(datadir))
    data_filelist = [f for f in filelist if 'fetchRaceDayCalendar' in f]
    print(data_filelist)
    for filepath in data_filelist:
        filename = util.get_filename_from_path(filepath)
        print(filename)
        xml_string = util.get_cleaned_xml_string(filepath=filepath)
        
        # Convenience flag when developing
        if False:
            util.write_file(
                data=util.get_html_unescape(html_string=xml_string), 
                filepath=filename, 
                encoding='utf-8'
            )
            exit(0)
        
        root = util.xml_string_to_object(xml_string=xml_string)
        racedaycalendar = root.Body.fetchRaceDayCalendarResponse.result
        print(unicode(racedaycalendar.fromdate.date))
        print(unicode(racedaycalendar.fromdate.month))
        print(unicode(racedaycalendar.fromdate.year))
        print(unicode(racedaycalendar.todate.date))
        print(unicode(racedaycalendar.todate.month))
        print(unicode(racedaycalendar.todate.year))
        
        # Parameter added in AIS 9
        # racedaycalendar.multipleTrackPoolSetups
        try:
            racedaycalendar.multipleTrackPoolSetups
        except AttributeError:
            racedaycalendar.multipleTrackPoolSetups = None
        if racedaycalendar.multipleTrackPoolSetups is not None:
            for multipletrackpoolsetup in racedaycalendar.multipleTrackPoolSetups.getchildren():
                print(unicode(multipletrackpoolsetup.betType.code))
                print(unicode(multipletrackpoolsetup.betType.domesticText))
                print(unicode(multipletrackpoolsetup.betType.englishText))
                for trackdata in multipletrackpoolsetup.hostTrack.getchildren():
                    print(unicode(trackdata.track.code))
                    print(unicode(trackdata.track.domesticText))
                    print(unicode(trackdata.track.englishText))
                    print(unicode(trackdata.trackKey.trackId))
                for leginfo in multipletrackpoolsetup.legInfo.getchildren():
                    print(unicode(leginfo.hostTrack.track.code))
                    print(unicode(leginfo.hostTrack.track.domesticText))
                    print(unicode(leginfo.hostTrack.track.englishText))
                    print(unicode(leginfo.hostTrack.trackKey.trackId))
                    print(unicode(leginfo.legNr))
                    print(unicode(leginfo.raceNr))
                    print(unicode(leginfo.trot))
                    print(unicode(multipletrackpoolsetup.multipleTrackName))
                    print(unicode(multipletrackpoolsetup.multipleTrackNameEnglish))
                    print(unicode(multipletrackpoolsetup.raceDayDate.year))
                    print(unicode(multipletrackpoolsetup.raceDayDate.month))
                    print(unicode(multipletrackpoolsetup.raceDayDate.date))
                    print(unicode(multipletrackpoolsetup.track.code))
                    print(unicode(multipletrackpoolsetup.track.domesticText))
                    print(unicode(multipletrackpoolsetup.track.englishText))
                    print(unicode(multipletrackpoolsetup.trackKey.trackId))
        for racedayinfo in racedaycalendar.raceDayInfos.getchildren():
            print(unicode(racedayinfo.country.code))
            print(unicode(racedayinfo.firstRacePostTime.date.date))
            print(unicode(racedayinfo.firstRacePostTime.date.month))
            print(unicode(racedayinfo.firstRacePostTime.date.year))
            print(unicode(racedayinfo.firstRacePostTime.time.hour))
            print(unicode(racedayinfo.firstRacePostTime.time.minute))
            print(unicode(racedayinfo.firstRacePostTime.time.second))
            print(unicode(racedayinfo.firstRacePostTime.time.tenth))
            print(unicode(racedayinfo.firstRacePostTimeUTC.date.date))
            print(unicode(racedayinfo.firstRacePostTimeUTC.date.month))
            print(unicode(racedayinfo.firstRacePostTimeUTC.date.year))
            print(unicode(racedayinfo.firstRacePostTimeUTC.time.hour))
            print(unicode(racedayinfo.firstRacePostTimeUTC.time.minute))
            print(unicode(racedayinfo.firstRacePostTimeUTC.time.second))
            print(unicode(racedayinfo.firstRacePostTimeUTC.time.tenth))
            print(unicode(racedayinfo.includesFinalRace))
            print(unicode(racedayinfo.international))
            print(unicode(racedayinfo.internationalBetting))
            print(unicode(racedayinfo.itspEventCode))
            print(unicode(racedayinfo.meetingNumber))
            print(unicode(racedayinfo.meetingType.code))
            print(unicode(racedayinfo.meetingType.domesticText))
            print(unicode(racedayinfo.meetingType.englishText))
            # Parameter added in AIS 9
            # racedayinfo.multipleTrackPoolSetups
            try:
                racedayinfo.multipleTrackPoolSetups
            except AttributeError:
                racedayinfo.multipleTrackPoolSetups = None
            if racedayinfo.multipleTrackPoolSetups is not None:
                for multipletrackpoolsetup in racedayinfo.multipleTrackPoolSetups.getchildren():
                    print(unicode(multipletrackpoolsetup.betType.code))
                    print(unicode(multipletrackpoolsetup.betType.domesticText))
                    print(unicode(multipletrackpoolsetup.betType.englishText))
                    for trackdata in multipletrackpoolsetup.hostTrack.getchildren():
                        print(unicode(trackdata.track.code))
                        print(unicode(trackdata.track.domesticText))
                        print(unicode(trackdata.track.englishText))
                        print(unicode(trackdata.trackKey.trackId))
                    for leginfo in multipletrackpoolsetup.legInfo.getchildren():
                        print(unicode(leginfo.hostTrack.track.code))
                        print(unicode(leginfo.hostTrack.track.domesticText))
                        print(unicode(leginfo.hostTrack.track.englishText))
                        print(unicode(leginfo.hostTrack.trackKey.trackId))
                        print(unicode(leginfo.legNr))
                        print(unicode(leginfo.raceNr))
                        print(unicode(leginfo.trot))
                    print(unicode(multipletrackpoolsetup.multipleTrackName))
                    print(unicode(multipletrackpoolsetup.multipleTrackNameEnglish))
                    print(unicode(multipletrackpoolsetup.raceDayDate.year))
                    print(unicode(multipletrackpoolsetup.raceDayDate.month))
                    print(unicode(multipletrackpoolsetup.raceDayDate.date))
                    print(unicode(multipletrackpoolsetup.track.code))
                    print(unicode(multipletrackpoolsetup.track.domesticText))
                    print(unicode(multipletrackpoolsetup.track.englishText))
                    print(unicode(multipletrackpoolsetup.trackKey.trackId))
            print(unicode(racedayinfo.raceCardAvailable))
            print(unicode(racedayinfo.raceDayDate.date))
            print(unicode(racedayinfo.raceDayDate.month))
            print(unicode(racedayinfo.raceDayDate.year))
            print(unicode(racedayinfo.track.code))
            print(unicode(racedayinfo.track.domesticText))
            print(unicode(racedayinfo.track.englishText))
            print(unicode(racedayinfo.trackKey.trackId))
            print(unicode(racedayinfo.trot))
            # Parameter added in AIS 9
            # racedayinfo.canceled
            try:
                racedayinfo.canceled
            except AttributeError:
                racedayinfo.canceled = False
            print(unicode(racedayinfo.canceled))
            for bettype in racedayinfo.betTypes.getchildren():
                print(unicode(bettype.hasResult))
                print(unicode(bettype.name.code))
                print(unicode(bettype.name.domesticText))
                print(unicode(bettype.name.englishText))
                print(unicode(bettype.national))
                for race_nr in bettype.races.getchildren():
                    print(unicode(race_nr))
            for raceinfo in racedayinfo.raceInfos.getchildren():
                for bettype_code in raceinfo.betTypeCodes.getchildren():
                    print(unicode(bettype_code))
                print(unicode(raceinfo.hasResult))
                print(unicode(raceinfo.postTime.hour))
                print(unicode(raceinfo.postTime.minute))
                print(unicode(raceinfo.postTime.second))
                print(unicode(raceinfo.postTime.tenth))
                print(unicode(raceinfo.postTimeUTC.hour))
                print(unicode(raceinfo.postTimeUTC.minute))
                print(unicode(raceinfo.postTimeUTC.second))
                print(unicode(raceinfo.postTimeUTC.tenth))
                print(unicode(raceinfo.raceNr))
                print(unicode(raceinfo.raceType.code))
                print(unicode(raceinfo.raceType.domesticText))
                print(unicode(raceinfo.raceType.englishText))
                print(unicode(raceinfo.trackSurface.code))
                print(unicode(raceinfo.trackSurface.domesticText))
                print(unicode(raceinfo.trackSurface.englishText))
                # Parameter added in AIS 9
                # raceinfo.canceled
                try:
                    raceinfo.canceled
                except AttributeError:
                    raceinfo.canceled = False
                print(unicode(raceinfo.canceled))
            # Parameter added in AIS 9
            # racedayinfo.sportSystemId
            try:
                racedayinfo.sportSystemId
            except AttributeError:
                racedayinfo.sportSystemId = None
            print(unicode(racedayinfo.sportSystemId))

if __name__ == "__main__":
    print_all_data('/home/joakim/projects/ais/latest_dl_error_data')
    