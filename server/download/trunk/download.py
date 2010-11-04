#!/usr/bin/env python

import ConfigParser
import os
import sys
import http_
import parser_
import util_
import re

conf = ConfigParser.SafeConfigParser()
config_file = 'download.conf'
config_file_path = os.path.join(sys.path[0], config_file)
if os.path.exists(config_file_path):
    conf.read(config_file_path)
else:
    print('Please create ' + config_file_path + ' before continuing!')
    exit(1)

datadir = conf.get('DEFAULT', 'datadir')
logfile = conf.get('DEFAULT', 'logfile')
historic_prefix = 'historicRaceDays_'
raceday_date_pattern = '\d+'
raceday_prefix = '_rd_'
race_prefix = '_r_'
file_postfix = '.html.gz'
get_historic_data = False

logger = util_.Logger(logfile)
logger.doPrint = True

def get_current_raceday_ids():
    '''Get collection of current month's races.'''
    raceday_ids = []
    year_month = util_.current_date().split('-')
    file = historic_prefix + year_month[0] + year_month[1] + file_postfix
    logger.log('Downloading current monthly race results')
    data = http_.get_current_race_days(logger)
    logger.log('Saving current monthly race results in ' + file)
    util_.write_data(datadir, file, data)
    parsed_raceday_ids = parser_.parse_raceday_ids(data)
    for raceday_id in parsed_raceday_ids:
        logger.log('Extracting raceday id: ' + raceday_id)
        raceday_ids.append(raceday_id)
    return raceday_ids

def get_historic_raceday_ids():
    '''Get monthly collections of historic races.'''
    # TODO: Make this a dynamic loop instead. Set start year and build up until
    # current month
    historicRaces = {
        '2008':['01','02','03','04','05','06','07','08','09','10','11','12'],
        '2009':['01','02','03','04','05','06','07','08','09','10','11','12'],
    }
    filelist = util_.get_files(datadir, historic_prefix)
    for year in historicRaces:
        for month in historicRaces[year]:
            time = year + month
            logger.log('Processing history ' + time)
            file = historic_prefix + time + file_postfix
            if file not in filelist:
                logger.log('Writing historic races ' + file)
                util_.write_data(datadir, file,
                    http_.get_monthly_race_days(time, logger))
            else:
                logger.log('Already saved history ' + file)
    raceday_ids = []
    filelist = util_.get_files(datadir, historic_prefix)
    for file in filelist:
        data = util_.read_data(datadir, file)
        parsed_raceday_ids = parser_.parse_raceday_ids(data)
        for raceday_id in parsed_raceday_ids:
            logger.log('Extracting historic raceday id: ' + raceday_id)
            raceday_ids.append(raceday_id)
    return raceday_ids

def get_race_ids(raceday_ids):
    for raceday_id in raceday_ids:
        filelist = util_.get_files(datadir, raceday_prefix + raceday_id)
        if filelist:
            data = util_.read_data(datadir, filelist[0])
            races = parser_.parse_race_ids(data)
            if races:
                for race in races.keys():
                    race_id = races[race]
                    logger.log('Checking raceday/race id: ' + \
                        raceday_id + '/' + race_id)
                    file_ending = raceday_prefix + raceday_id + race_prefix + \
                        race_id + file_postfix
                    for file in filelist:
                        if not re.match(raceday_date_pattern + file_ending, file):
                            logger.log('Downloading race id: ' + \
                                raceday_id + ' ' + race_id)
                            data = http_.get_race(raceday_id, race_id, logger)
                            date = parser_.get_date(data)
                            file = date + file_ending
                            logger.log('Writing race id: ' + file)
                            util_.write_data(datadir, file, data)
                        else:
                            logger.log('Already saved race id ' + file)
            else:
                logger.log('No races found in ' + filelist[0])
        else:
            logger.log('Downloading first race id in raceday id ' + raceday_id)
            data = http_.get_first_race(raceday_id, logger)
            if data:
                races = parser_.parse_race_ids(data)
                # Found a race day that didn't have any valid race,
                # only races named 'k'
                # Need to check if any races
                if races:
                    # Found a race day that didn't have a race 1.
                    # Sorting the keys so that e.g. race 2 can be the first key
                    sortedRaces = sorted(races.keys())
                    firstRaceId = races[sortedRaces[0]]
                    file_ending = raceday_prefix + raceday_id + race_prefix + \
                        firstRaceId + file_postfix
                    date = parser_.get_date(data)
                    file = date + file_ending
                    logger.log('Writing race id: ' + file)
                    util_.write_data(datadir, file, data)
                    # Recursive call since now there is data
                    logger.log('Recursive call with raceday id ' + raceday_id)
                    get_race_ids([raceday_id])
                else:
                    logger.log('No or incomplete races found in raceday '
                        + raceday_id)
            else:
                logger.log('No data in raceday ' + raceday_id)

def main():
    '''Important! When running this in a cron job, make sure all races
    has been reported. Else when getting the first race to extract all
    race ids, all ids will not be present and there is currently no
    mechanism reload the first race'''

    # Current races
    raceday_ids = get_current_raceday_ids()
    get_race_ids(raceday_ids)
    # Historic races
    if get_historic_data:
        raceday_ids = get_historic_raceday_ids()
        get_race_ids(raceday_ids)

if __name__ == "__main__":
    main()
