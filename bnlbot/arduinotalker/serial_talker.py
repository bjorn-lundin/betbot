#!/usr/bin/python
# -*- coding: latin-1 -*-
#
#import

import time
from time import sleep
import sys
import os
import psycopg2
import datetime
#import serial
import signal
import subprocess as sp

############ BNL start ####################
def signal_handler(signal, frame):
        print '\nYou pressed Ctrl+C!\nExiting...\n'
        sys.exit(0)
        
###################################

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

#                 "and B.BETMODE = 2 " \
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
#                 "and B.BETMODE = 2 " \
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

def print_bet_ratio(conn)  :
    cur = conn.cursor()
#                 "and B.BETMODE = 2 " \
    cur.execute("""
                select 
                  BETNAME, 
                  sum(PROFIT) / sum(SIZEMATCHED) as PROFITRATIO 
                from 
                  ABETS 
                where BETPLACED::date > (select CURRENT_DATE - interval '4 days') 
                  and BETWON is not null 
                  and EXESTATUS = 'SUCCESS' 
                  and STATUS in ('SETTLED') 
                  and SIDE = 'BACK' 
                group by 
                  BETNAME 
                having 
                  sum(SIZEMATCHED) > 0 
                  and max(BETPLACED)::date >= '2015-01-01' 
                order by 
                  PROFITRATIO desc 
                  """
                  );

    if cur.rowcount >= 1 :
        rows = cur.fetchall()
        print ""
        print "------------------------------------------------------------------------------"
        print "   bets order based on winnings (sum(PROFIT) / sum(SIZEMATCHED)) 4 days back"
        print "   35, 25, 15, 10, 8, 7 %"
        print "------------------------------------------------------------------------------"
        for row in rows:
           r={}
           r['0']=row[0]
           r['1']=row[1]*100
          # print row,r
           print '%(0)37s  %(1).2f' % r
           #print row[0],row[1]

        print "------------------------------------------------------------------------------"
    cur.close()
    conn.commit()
#end print_bet_ratio
    
    

def main(g):
  # return
  # Main program block
  buff = ""
  if g.source == 1 :
    g.source = 2
  else :
    g.source = 2

  if g.source == 1 :
    conn = psycopg2.connect("dbname=dry \
                           user=bnl \
                           host=db.nonodev.com \
                           password=BettingFotboll1$ \
                           sslmode=require \
                           application_name=serial_talker")

    bets = ['HORSES_WIN_22.0_24.0_6_25_BACK_GB',
            'HORSES_WIN_7.4_8.4_6_25_LAY_GB',
            'HORSES_WIN_26.0_26.0_6_25_BACK_GB',
            'HORSES_WIN_30.0_30.0_6_50_LAY_GB',
            'HORSES_WIN_14.5_14.5_6_25_BACK_IE',
            'HORSES_WIN_30.0_30.0_6_50_LAY_IE',
            'HUMAN_PENALTY-TAKEN_NO_1.3_BACK_AL',
            'HUMAN_SENDING-OFF_NO_1.3_BACK_AL',
            'HUMAN_HAT-TRICKED-SCORED_NO_1.02_BACK_AL'   ]

  elif g.source == 2 :
    conn = psycopg2.connect("dbname=bnl \
                           user=bnl \
                           host=db.nonodev.com \
                           password=BettingFotboll1$ \
                           sslmode=require \
                           application_name=serial_talker")

    bets = ['HORSES_PLC_BACK_FINISH_1.10_7.0_1',
            'HORSES_PLC_BACK_FINISH_1.10_20.0_1',
            'HORSES_PLC_BACK_FINISH_1.10_30.0_1',
            'HORSES_PLC_BACK_FINISH_1.25_12.0_1',
            'HORSES_PLC_BACK_FINISH_1.40_50.0_1',
            'HORSES_PLC_BACK_FINISH_1.50_30.0_1',
            'HORSES_WIN_LAY_FINISH_1.10_20.0_3',
            'HORSES_WIN_LAY_FINISH_1.10_20.0_4',            
            'HORSES_WIN_LAY_FINISH_1.10_30.0_3',
            'HORSES_WIN_LAY_FINISH_1.10_30.0_4']
    
    #bets = ['HORSES_WIN_LAY_FINISH_1.10_20.0_3',
    #        'HORSES_WIN_LAY_FINISH_1.10_20.0_4',            
    #        'HORSES_WIN_LAY_FINISH_1.10_30.0_3',
    #        'HORSES_WIN_LAY_FINISH_1.10_30.0_4']

  row0 = {}
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 6
  if g.source == 1 :
    row0['typ'] = 'TEST Typ av bet/antal dagar sedan'
  else :
    row0['typ'] = 'REAL Typ av bet/antal dagar sedan'

  lcd_row_0 = '%(typ)37s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  buff += lcd_row_0 + '\r\n'
#  print lcd_row_0

  buff += '-------------------------------------------------------------------------------\r\n'

  for bet in bets :
    row1 = {}
    # offset days from monday
    row1['0'] = 0;#get_row(conn, bet,  0)
    row1['1'] = 0;#get_row(conn, bet, -1)
    row1['2'] = 0;#get_row(conn, bet, -2)
    row1['3'] = 0;#get_row(conn, bet, -3)
    row1['4'] = 0;#get_row(conn, bet, -4)
    row1['5'] = 0;#get_row(conn, bet, -5)
    row1['6'] = 0;#get_row(conn, bet, -6)
                
    if len(bet) > 37 :
      row1['typ'] = bet[7:]
    else :
      row1['typ'] = bet
        
    lcd_row_1 = '%(typ)37s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row1
    buff += lcd_row_1 + '\r\n'
  buff += '-------------------------------------------------------------------------------\r\n'

  row0['typ'] = 'Typ av bet/result veckor tillbaka'
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 'Summa'
  lcd_row_0 = '%(typ)37s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6s' % row0
  buff += lcd_row_0 + '\r\n'
  buff += '-------------------------------------------------------------------------------\r\n'

  for bet in bets :
    row2 = {}
    row2['0'] = 0;#get_row_weeks_back(conn, bet,  0)
    row2['1'] = 0;#get_row_weeks_back(conn, bet, -1)
    row2['2'] = 0;#get_row_weeks_back(conn, bet, -2)
    row2['3'] = 0;#get_row_weeks_back(conn, bet, -3)
    row2['4'] = 0;#get_row_weeks_back(conn, bet, -4)
    row2['5'] = 0;#get_row_weeks_back(conn, bet, -5)
    #remove HORSES_ from HORSES_WIN_9.0_10.0_GREENUP_GB_LB_7_2_5.0
    if len(bet) > 37 :
      row2['typ'] = bet[7:]
    else :
      row2['typ'] = bet
    

    row2['6'] = int(row2['0']) +  int(row2['1']) + int(row2['2']) + \
                int(row2['3']) +  int(row2['4']) + int(row2['5'])
    lcd_row_2 = '%(typ)37s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row2
    buff += lcd_row_2 + '\r\n'

    
    
  #clear screen
  tmp = sp.call('clear',shell=True)   
  #print to screen  
  print buff[:-2]
  print_bet_ratio(conn)    
  conn.close()
#  return source

#  ser = serial.Serial(
#    port='/dev/rfcomm0',
#    baudrate=19200,
#    parity=serial.PARITY_NONE,
#    stopbits=serial.STOPBITS_ONE,
#    bytesize=serial.EIGHTBITS)
#  ser.open()
#  ser.write(buff)
#  ser.close()
#############################################################

class Global_Obj():
    source = 1
    ts =  datetime.datetime.now() - datetime.timedelta(days=1)
    def to_string(self) :
        print 'to_string.source', self.source
        print 'to_string.ts', self.ts
    
if __name__ == '__main__':
  #make print flush now!
  sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
  signal.signal(signal.SIGINT, signal_handler)
  #make it yesterday to force check due to wrong day
  g = Global_Obj()
  
  
  while True:
      try:
          main(g)
      except psycopg2.OperationalError:
          print 'Bad network?'
      except psycopg2.DatabaseError:
          print 'Bad database connection?'

#      time.sleep(60)
      for x in range(1, 60):
        time.sleep(1)
        sys.stdout.write('.')
      sys.stdout.write(' -> updating...')  
