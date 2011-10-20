import re
import datetime

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

def get_date(data):
    '''Get date from a race file'''
    date = 'NODATE'
    months = ['januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 
              'augusti','september', 'oktober', 'november', 'december']
    p = re.compile('(\w+) \w+ (\d{1,2}) (\w+) (\d{4})', (re.DOTALL | re.IGNORECASE | re.UNICODE))
    f = p.search(data)
    if f:
        year = int(f.group(4))
        month = int(months.index(f.group(3).lower()) + 1)
        day = int(f.group(2))
        date = datetime.date(year, month, day).strftime("%Y%m%d")
    return date

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
