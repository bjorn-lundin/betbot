#!/usr/bin/python
#


#import

import time
import sys 
import os
import psycopg2
import datetime
import serial

  
def get_row(conn, bet_type, delta_days)  :
    result = 0

    day = datetime.datetime.now() + datetime.timedelta(days = delta_days) 
    day_start = datetime.datetime(day.year, day.month, day.day,  0,  0,  0)
    day_stop  = datetime.datetime(day.year, day.month, day.day, 23, 59, 59)

#    print day_start, day_stop
    
    cur = conn.cursor()
    cur.execute("select " \
                     "sum(PROFIT), " \
                     "BET_PLACED::date " \
                 "from " \
                     "BET_WITH_COMMISSION " \
                 "where " \
                     "BET_TYPE = %s " \
                 "and " \
                     "CODE = %s " \
                 "and " \
                     "BET_PLACED >= %s " \
                 "and " \
                     "BET_PLACED <= %s " \
                 "group by " \
                     "BET_PLACED::date " \
                 "order by " \
                     "BET_PLACED::date desc ", 
                   (bet_type,'S',day_start,day_stop))
  
    print bet_type, 'rc', cur.rowcount
     
    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[0]  
        else :
          result = 0
    cur.close()
    conn.commit()
   
    return result 
    ################################## end get_row
def main():
  # Main program block
  conn = psycopg2.connect("dbname='betting' \
                             user='bnl' \
                             host='192.168.0.13' \
                             password=None") 
  row1 = {}
  row2 = {}    
  row1['today']  = get_row(conn, "DRY_RUN_HORSES_PLACE_LAY_BET_6_10", 0)
  row1['yest']   = get_row(conn, "HOUNDS_WINNER_LAY_BET", 0)
  row1['dbyest'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_16_19", 0)

  row2['today']  = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_17_18", 0)
  row2['yest']   = get_row(conn, "DRY_RUN_HORSES_WINNER_LAY_BET", 0)
  row2['dbyest'] = get_row(conn, "DRY_RUN_HOUNDS_PLACE_LAY_BET_3_9", 0)

  lcd_row_1 = '-%(today)5d%(yest)5d%(dbyest)5d' % row1
  lcd_row_2 = '-%(today)5d%(yest)5d%(dbyest)5d' % row2

  print lcd_row_1
  print lcd_row_2
  print row1
  print row2


  ser = serial.Serial(
    port='/dev/ttyUSB0',
    baudrate=9600,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS)


  ser.open()
  ser.write('1') # clear display
  ser.write('3,0,0,HOUNDS_WINNER_LAY_BET') # string
  ser.write('2,0,1,'+lcd_row_1) # string
  ser.close()

    
  
if __name__ == '__main__':
  #make print flush now!
  sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
  main()

