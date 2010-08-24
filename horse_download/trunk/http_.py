import urllib
import urllib2
import random
import time
import socket
import util_

# Settings
requestHeaders = {'User-agent' :
    'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.1.5) ' +
    'Gecko/20091102 Firefox/3.5.5'}
requestTimeout = 10 # Request timeout in seconds
requestRetries = 5  # If exceptions occur, retry this many times
#minDelayTime = 8    # Seconds
#maxDelayTime = 15   # Seconds
minDelayTime = 2    # Seconds
maxDelayTime = 6   # Seconds
socket.setdefaulttimeout(requestTimeout)

def get_current_race_days(logger):
    requestUrl = 'http://www.travsport.se/sresultat?kommando=tevlingsDagar'
    requestData = {}
    httpResponse = http_request(requestUrl, requestData, logger)
    data = httpResponse.read().decode('iso-8859-1')
    return data 

def get_monthly_race_days(time, logger):
    '''time in the format "200710"'''
    requestUrl = 'http://www.travsport.se/sresultat'
    requestData = {'kommando':'tevlingsDagar', 'valdManad':time}
    httpResponse = http_request(requestUrl, requestData, logger)
    data = httpResponse.read().decode('iso-8859-1')
    return data 

def get_first_race(raceDayId, logger):
    requestUrl = 'http://www.travsport.se/sresultat'
    requestData = {'kommando':'tevlingsdagVisa', 'tevdagId':raceDayId}
    httpResponse = http_request(requestUrl, requestData, logger)
    data = httpResponse.read().decode('iso-8859-1')
    return data

def get_race(race_day_id, race_id, logger):
    requestUrl = 'http://www.travsport.se/sresultat'
    requestData = {'kommando':'tevlingsdagVisa', 'tevdagId':race_day_id,
        'loppId':race_id}
    httpResponse = http_request(requestUrl, requestData, logger)
    data = httpResponse.read().decode('iso-8859-1')
    return data

def http_request(requestUrl, requestData, logger):
    logger.log('http_request: ' + requestUrl + ', ' + str(requestData))
    request = urllib2.Request(requestUrl, urllib.urlencode(requestData),
        requestHeaders)
    keepRequesting = True
    response = None
    tries = 0
    while keepRequesting:
        tries += 1
        delay()
        if tries <= requestRetries:
            try:
                response = urllib2.urlopen(request)
            except urllib2.HTTPError, e:
                logger.log('HTTPError: ' + str(e.reason))
                #print (e.reason)
                continue
            except urllib2.URLError, e:
                logger.log('URLError: ' + str(e.reason))
                #print (e.reason)
                continue
            except socket.error, e:
                logger.log('Socket Error: ' + str(e))
                continue
            else:
                keepRequesting = False
        else:
            logger.log('Number of request retries has exeeded limit: ' +
                str(requestRetries))
            keepRequesting = False
    return response
        
def report_headers(response):
    for key in response.headers:
        print(key + ": " + response.headers[key])

def delay():
    for delay in random.sample(range(minDelayTime, maxDelayTime + 1), 1):
        time.sleep(delay)

def main():
    logfile = 'test_log.txt'
    logger = util_.Logger(logfile)
    http_request("http://localhost/kalle", {}, logger)

if __name__ == "__main__":
    main()
