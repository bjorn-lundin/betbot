#


#import

import time
from time import sleep
import sys 
import os
import psycopg2
import datetime
import serial


 
def get_row_weeks_back(conn, bet_type, delta_weeks)  :
    result = 0
    today = datetime.datetime.now() 
    day = today + datetime.timedelta(days = int(delta_weeks * 7))
    day_stop  = datetime.datetime(day.year, day.month, day.day, 23, 59, 59)

    ds = day_stop - datetime.timedelta(days = 6) 
    day_start = datetime.datetime(ds.year, ds.month, ds.day, 0, 0, 0)

#    print day_start, day_stop
    
    cur = conn.cursor()
    cur.execute("select sum(PROFIT) " \
                 "from BET_WITH_COMMISSION " \
                 "where BET_TYPE = %s " \
                 "and CODE = %s " \
                 "and BET_PLACED >= %s " \
                 "and BET_PLACED <= %s " ,
                   (bet_type, 'S', day_start, day_stop))
  
#    print bet_type, 'rc', cur.rowcount, 'start', day_start, 'stop', day_stop
     
    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[0]  
        else :
          result = 0
    cur.close()
    conn.commit()
    if result == None :
       result = 0   

#    print bet_type, 'rc', cur.rowcount, 'start', day_start, 'stop', day_stop, result

  
    return result 
    ################################## end get_row_days



  
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
                             
  bets = ['HORSES_WINNER_LAY_BET',
          'DRY_RUN_HORSES_WINNER_LAY_BET',
          'HOUNDS_WINNER_LAY_BET_13_14',
          'DRY_RUN_HOUNDS_WINNER_LAY_BET_13_14',
          'DRY_RUN_HOUNDS_WINNER_BACK_BET_45_07',
          'DRY_RUN_HORSES_WINNER_LAY_BET_ALL',
          'DRY_RUN_HORSES_WINNER_LAY_BET_ALL_GO',
          'DRY_RUN_HOUNDS_WINNER_BACK_BET_3_02',
          'DRY_RUN_HOUNDS_WINNER_BACK_BET'   ]
             
#  ser.write('-----------------------------------------------------------------------------\r\n')

  row0 = {}
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 6
  row0['typ'] = 'Typ av bet/Antal dagar sedan'
  
  lcd_row_0 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  ser.write(lcd_row_0 + '\r\n')


  ser.write('------------------------------------------------------------------------------\r\n')

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
    lcd_row_1 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row1
#    print lcd_row_1
    ser.write(lcd_row_1 + '\r\n')
    
  ser.write('------------------------------------------------------------------------------\r\n')
  row0['typ'] = 'Typ av bet/result veckor tillbaka'    
  lcd_row_0 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  ser.write(lcd_row_0 + '\r\n')
  ser.write('------------------------------------------------------------------------------\r\n')

  for bet in bets :                               
    row2 = {}
    row2['0'] = get_row_weeks_back(conn, bet, 0)
    row2['1'] = get_row_weeks_back(conn, bet, -1)
    row2['2'] = get_row_weeks_back(conn, bet, -2)
    row2['3'] = get_row_weeks_back(conn, bet, -3)
    row2['4'] = get_row_weeks_back(conn, bet, -4)
    row2['5'] = get_row_weeks_back(conn, bet, -5)
    row2['6'] = get_row_weeks_back(conn, bet, -6)
    row2['typ'] = bet
    lcd_row_2 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row2
#    print lcd_row_1
    ser.write(lcd_row_2 + '\r\n')
    
#  ser.write('-----------------------------------------------------------------------------\r\n')
#  ser.write('\r\n\r\n\r\n\r\n\r\n\r\n')
 

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

