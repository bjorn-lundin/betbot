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
                             
  ser = serial.Serial(
    port='/dev/ttyUSB0',
    baudrate=38400,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS)

  ser.open()
                             
  bets = ['HOUNDS_WINNER_LAY_BET',
          'HORSES_PLACE_LAY_BET_6_10',
          'HOUNDS_WINNER_LAY_BET_13_14',
          "DRY_RUN_HORSES_WINNER_LAY_BET",
          "DRY_RUN_HOUNDS_WINNER_LAY_BET_15_18",
          "DRY_RUN_HOUNDS_WINNER_LAY_BET_16_19",
          "DRY_RUN_HOUNDS_WINNER_LAY_BET_17_18",
          "DRY_RUN_HOUNDS_WINNER_LAY_BET_LAST",
          "DRY_RUN_HOUNDS_PLACE_LAY_BET",
          "DRY_RUN_HOUNDS_PLACE_LAY_BET_3_9",
          "DRY_RUN_HOUNDS_WINNER_BACK_BET"   ]
             
  ser.write('-----------------------------------------------------------------------------\r\n')

  row0 = {}
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 6
  row0['typ'] = 'Typ av bet/Antal dagar sedan'
  
  lcd_row_0 = '%(typ)35s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  ser.write(lcd_row_0 + '\r\n')


  ser.write('-----------------------------------------------------------------------------\r\n')


  for bet in bets :                               
    row1 = {}
    row1['0'] = get_row(conn, bet, 0)
    row1['1'] = get_row(conn, bet, -1)
    row1['2'] = get_row(conn, bet, -2)
    row1['3'] = get_row(conn, bet, -3)
    row1['4'] = get_row(conn, bet, -4)
    row1['5'] = get_row(conn, bet, -5)
    row1['6'] = get_row(conn, bet, -6)
    row1['typ'] = bet
    lcd_row_1 = '%(typ)35s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row1
#    print lcd_row_1
    ser.write(lcd_row_1 + '\r\n')
    
    
  ser.write('-----------------------------------------------------------------------------\r\n')
  ser.write('\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n')
 

  ser.close()


#  ser.write('1') # clear display
#  sleep(1)
#  ser.write('3,0,0,'+ lcd_row_1 ) # string
#  sleep(2)
#  ser.write('3,1,0,'+ lcd_row_2) # string
#  ser.write('2,0,3,'+lcd_row_1) # numeric


    
  
if __name__ == '__main__':
  #make print flush now!
  sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
  main()

