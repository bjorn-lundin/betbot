#!/usr/bin/python
#


#import

import time
from time import sleep
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
  
 #   print bet_type, 'rc', cur.rowcount, 'start', day_start, 'stop', day_stop
     
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
  row1['0'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", 0)
  row1['1'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", -1)
  row1['2'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", -2)
  row1['3'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", -3)
  row1['4'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", -4)
  row1['5'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", -5)
  row1['6'] = get_row(conn, "HOUNDS_WINNER_LAY_BET", -6)



  row2['0'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", 0)
  row2['1'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", -1)
  row2['2'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", -2)
  row2['3'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", -3) 
  row2['4'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", -4)
  row2['5'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", -5)
  row2['6'] = get_row(conn, "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18", -6)


  lcd_row_1 = 'HOUNDS_WINNER_LAY_BET               %(0)5d%(1)5d%(2)5d%(3)5d%(4)5d%(5)5d%(6)5d' % row1
  lcd_row_2 = 'DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18 %(0)5d%(1)5d%(2)5d%(3)5d%(4)5d%(5)5d%(6)5d' % row2

#  print lcd_row_1
#  print lcd_row_2
#  print row1
#  print row2



#  lcd_row_1 = 'G%(today)5d%(yest)5d%(dbyest)5d' % row1
#  lcd_row_2 = 'H%(today)5d%(yest)5d%(dbyest)5d' % row2



  ser = serial.Serial(
    port='/dev/ttyUSB0',
    baudrate=38400,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS)


  ser.open()

#  ser.write('1') # clear display
#  sleep(1)
#  ser.write('3,0,0,'+ lcd_row_1 ) # string
#  sleep(2)
#  ser.write('3,1,0,'+ lcd_row_2) # string
#  ser.write('2,0,3,'+lcd_row_1) # numeric

  ser.write(lcd_row_1 + '\r\n')
  ser.write(lcd_row_2 + '\r\n')
  ser.close()

    
  
if __name__ == '__main__':
  #make print flush now!
  sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
  main()

