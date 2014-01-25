#
#import

import time
from time import sleep
import sys 
import os
import psycopg2
import datetime
import serial

def get_row_weeks_back(conn, betname, delta_weeks)  :
    result = 0
    today = datetime.datetime.now() 
    day = today + datetime.timedelta(days = int(delta_weeks * 7))
#    day_stop  = datetime.datetime(day.year, day.month, day.day, 23, 59, 59)

    mon = day - datetime.timedelta(today.weekday())
    sun = mon + datetime.timedelta(days = 6)

#    print 'mon', mon
#    print 'sun', sun

    mon2 = datetime.datetime(mon.year, mon.month, mon.day, 0, 0, 0)
    sun2 = datetime.datetime(sun.year, sun.month, sun.day, 23, 59, 59)
#    print 'mon2', mon2
#    print 'sun2', sun2
    
    cur = conn.cursor()
    cur.execute("select sum(B.PROFIT) " \
                 "from ABETS B  " \
                 "where B.BETNAME = %s " \
                 "and B.BETWON is not NULL " \
                 "and B.BETPLACED >= %s " \
                 "and B.BETPLACED <= %s " ,
                   (betname, mon2, sun2))
  
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

    return result 
    ################################## end get_row_days
  
def get_row(conn, betname, delta_days)  :
    result = 0

    day = datetime.datetime.now() + datetime.timedelta(days = delta_days) 
    day_start = datetime.datetime(day.year, day.month, day.day,  0,  0,  0)
    day_stop  = datetime.datetime(day.year, day.month, day.day, 23, 59, 59)
#    print betname, day_start, day_stop
    cur = conn.cursor()
    cur.execute("select " \
                 "sum(B.PROFIT) " \
                 "from ABETS B " \
                 "where B.BETNAME = %s " \
                 "and B.BETWON is not NULL " \
                 "and B.BETPLACED >= %s " \
                 "and B.BETPLACED <= %s ",
                   (betname,day_start,day_stop))  
#    print betname, 'rc', cur.rowcount, 'start', day_start, 'stop', day_stop
    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[0]
        else :
          result = 0

    if result == None :
       result = 0

    cur.close()
    conn.commit()
    return result 
    ################################## end get_row
def main():
  # Main program block

  now = datetime.datetime.now()
  if now.minute % 2 == 0 :
    source = 2
  else :
    source = 2
    return

  if source == 1 :
    conn = psycopg2.connect("dbname='bnl' \
                           user='bnl' \
                           host='192.168.0.13' \
                           password=None") 

    bets = ['DR_HORSES_WIN_LAY_LATE_GB_30_60',
            'DR_HORSES_WIN_LAY_LATE_IE_35_50',
            'DR_HORSES_WIN_LAY_GO_EARLY_GB_30_60',
            'DR_HORSES_WIN_LAY_EARLY_GB_10_90',
            'DR_HORSES_WIN_BACK_GB_60_05',
            'DR_HORSES_WIN_LAY_LATE_GB_35_50',
            'DR_HORSES_WIN_LAY_EARLY_FR_30_60',
            'DR_HORSES_WIN_LAY_EARLY_GB_30_60',
            'DR_HOUNDS_WIN_BACK_GB_45_07'   ]

  elif source == 2 :
    conn = psycopg2.connect("dbname='bnls' \
                           user='bnl' \
                           host='nonodev.com' \
                           password='BettingFotboll1$' ")

    bets = ['HORSES_WIN_FAV2_GB',
            'HORSES_WIN_FAV4_IE',
            'HORSES_PLC_LAY4_GB',
            'HORSES_PLC_LAY4_IE',
            'HORSES_WIN_LAY5_IE',
            'HORSES_WIN_LAY4_GB',  
            'HOUNDS_WIN_FAV5_GB',
            'HOUNDS_WIN_FAV4_GB',    
            'DRY_RUN_HORSES_WIN_LAY_15_21_5_200_0']
                             
  ser = serial.Serial(
    port='/dev/ttyUSB0',
    baudrate=38400,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS)

  ser.open()
             
#  ser.write('-----------------------------------------------------------------------------\r\n')

  row0 = {}
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 6
  row0['typ'] = 'Typ av bet/antal dagar sedan'
  
  lcd_row_0 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  ser.write(lcd_row_0 + '\r\n')
#  print lcd_row_0


  ser.write('------------------------------------------------------------------------------\r\n')

  for bet in bets :                               
    row1 = {}
    # offset days from monday 
    row1['0'] = get_row(conn, bet,  0)
    row1['1'] = get_row(conn, bet, -1)
    row1['2'] = get_row(conn, bet, -2)
    row1['3'] = get_row(conn, bet, -3)
    row1['4'] = get_row(conn, bet, -4)
    row1['5'] = get_row(conn, bet, -5)
    row1['6'] = get_row(conn, bet, -6)
    row1['typ'] = bet
    lcd_row_1 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row1
 #   print lcd_row_1
    ser.write(lcd_row_1 + '\r\n')
    
  ser.write('------------------------------------------------------------------------------\r\n')
  row0['typ'] = 'Typ av bet/result veckor tillbaka'    
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 'Summa'
  lcd_row_0 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6s' % row0
  ser.write(lcd_row_0 + '\r\n')
  ser.write('------------------------------------------------------------------------------\r\n')

  for bet in bets :                               
    row2 = {}
    row2['0'] = get_row_weeks_back(conn, bet,  0)
    row2['1'] = get_row_weeks_back(conn, bet, -1)
    row2['2'] = get_row_weeks_back(conn, bet, -2)
    row2['3'] = get_row_weeks_back(conn, bet, -3)
    row2['4'] = get_row_weeks_back(conn, bet, -4)
    row2['5'] = get_row_weeks_back(conn, bet, -5)
#    row2['6'] = get_row_weeks_back(conn, bet, -6)
    row2['typ'] = bet

    row2['6'] = int(row2['0']) +  int(row2['1']) + int(row2['2']) + \
                int(row2['3']) +  int(row2['4']) + int(row2['5'])     
    lcd_row_2 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row2
#    print lcd_row_2
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

