import re

swedish_months = {
    'januari':1,
    'februari':2,
    'mars':3,
    'april':4,
    'maj':5,
    'juni':6,
    'juli':7,
    'augusti':8,
    'september':9,
    'oktober':10,
    'november':11,
    'december':12,
}

def parse_raceday_ids(data):
    '''Get race day ids from a download_history() data file. A race day
    represents a number of races at a specific track and date'''
    races = []
    patternString = "document.tdForm ,'(\d+)'"
    pattern = re.compile(patternString, re.DOTALL | re.IGNORECASE | re.UNICODE)
    resluts = re.finditer(pattern, data)
    for result in resluts:
        races.append(result.group(1))
    return races

def parse_race_ids(data):
    '''Get race ids. This function check if all race numbers have
    a matching race id. If not, all races has not been reported and
    the function returns an empty race_ids'''
    race_ids = {}
    race_id = 'tevdagId=\d+&loppId=(\d+).*?'
    race_number = '<FONT.*?>(\d+)</FONT>'
    race_number_length = 0
    race_number_pattern = re.compile(race_number, re.DOTALL | re.IGNORECASE | re.UNICODE)
    race_number_match = re.findall(race_number_pattern, data)
    if race_number_match:
        race_number_length = len(race_number_match)
    race_all = race_id + race_number
    race_all_pattern = re.compile(race_all, re.DOTALL | re.IGNORECASE | re.UNICODE)
    race_all_match = re.findall(race_all_pattern, data)
    if race_all_match:
        if (race_number_length > 0
            and race_number_length == len(race_all_match)):
            for id in race_all_match:
                race_ids[int(id[1])] = id[0]
    return race_ids

def get_race():
    '''Beginning of some kind of race parser, e.g. track and date...'''
    #    dateTrackPatternString = '.*?<B>(\w+) \w+ (\d+) (\w+) (\d+)</B>'
    #    dateTrackPattern = re.compile(dateTrackPatternString,
    #                       re.DOTALL | re.IGNORECASE)
    #    dateTrackMatch = re.match(dateTrackPattern, data)
    #    if dateTrackMatch:
    #        month = swedish_months[dateTrackMatch.group(3).lower()]
    #        d = datetime.date(int(dateTrackMatch.group(4)), int(month),
    #                          int(dateTrackMatch.group(2)))
    #        result['track'] = dateTrackMatch.group(1).lower()
    #        result['date'] = datetime.datetime.strftime(d, "%Y%m%d")
    pass

def get_tracks(data):
    outerPattern = '.*?<SELECT.*?name="valdBana".*?>(.*?)</SELECT>'
    innerPattern = '.*?<OPTION  VALUE="(\d+)">(.*?)\((.*?)\)</OPTION>.*?'
    outer = re.compile(outerPattern, re.DOTALL | re.IGNORECASE | re.UNICODE)
    inner = re.compile(innerPattern, re.DOTALL | re.IGNORECASE | re.UNICODE)
    outerResult = outer.match(data)
    if outerResult:
        tracks = re.findall(inner, outerResult.group(1))
    else:
        tracks = None
    return tracks

def main():
    f = open('test_data/historicRaceDays_200806.html', 'r')
    data = f.read()
    races = parse_raceday_ids(data)
    print (races)

    f = open('test_data/raceday_503039_race_676939.html', 'r')
    data = f.read()
    res = parse_race_ids(data)
    for key in sorted(res.keys()):
        print (key, ' ->> ' + res[key])
    
    f = open('test_data/incomplete_race_ids.html', 'r')
    data = f.read()
    res = parse_race_ids(data)
    if res:
        for key in sorted(res.keys()):
            print (key, ' ->> ' + res[key])
    else:
        print('Nope: All races not reported yet.')

if __name__ == "__main__":
    main()
