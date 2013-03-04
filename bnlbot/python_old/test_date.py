
import datetime
import os, sys


def start_stop_of_week(year, week):
    start=str(year) + '-01-05'
    my_date = datetime.datetime.strptime(start,'%Y-%m-%d')
    (y,w,d) = my_date.isocalendar()
    while w != week : 
        my_date = my_date + datetime.timedelta(days=+7)
        (y,w,d) = my_date.isocalendar()

    start_date = my_date + datetime.timedelta(days=-d+1)
    stop_date  = my_date + datetime.timedelta(days=7-d)

    print 'start_date', start_date
    print 'stop_date', stop_date

###########
# main
#make print flush now!
sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

start_stop_of_week(2013,6)
start_stop_of_week(2013,7)
start_stop_of_week(2013,13)
