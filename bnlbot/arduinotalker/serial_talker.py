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
    cur.execute("""
                 select sum(B.PROFIT)
                 from ABETS B
                 where B.BETNAME = %s
                 and B.BETWON is not NULL
                 and B.EXESTATUS = 'SUCCESS'
                 and B.STATUS in ('SETTLED')
                 and B.BETPLACED >= %s
                 and B.BETPLACED <= %s """ ,
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
    cur.execute("""
                 select
                   sum(B.PROFIT)
                 from ABETS B
                 where B.BETNAME = %s
                 and B.BETWON is not NULL
                 and B.EXESTATUS = 'SUCCESS'
                 and B.STATUS in ('SETTLED')
                 and B.BETPLACED >= %s
                 and B.BETPLACED <= %s """,
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

def get_bet_ratio(conn, betname, delta_days)  :
    result=0
    cur = conn.cursor()
#                 "and B.BETMODE = 2 " \
    cur.execute("""
                  select
                    BETNAME,
                    ((case side
                      when 'LAY'  then sum(PROFIT)/(sum(SIZEMATCHED) * (avg(PRICEMATCHED)-1))
                      when 'BACK' then sum(PROFIT)/sum(SIZEMATCHED)
                    end)*100.0) as PROFITRATIO
                  from
                    ABETS
                  where BETPLACED::date > (select CURRENT_DATE - interval '%s days')
                    and BETWON is not null
                    and EXESTATUS = 'SUCCESS'
                    and STATUS in ('SETTLED')
                    and BETNAME = %s
                  group by
                    BETNAME,SIDE
                  having
                    sum(SIZEMATCHED) > 0
                    and max(BETPLACED)::date >= '2015-01-01'
                  order by
                    PROFITRATIO desc
                """,(delta_days,betname)
                )

    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[1]
        else :
          result = 0

    if result == None :
       result = 0


    if result <= -100.0 :
       result = -99.99

    if result >= 100.0 :
       result = 99.99

    return result
    cur.close()
    conn.commit()
#end print_bet_ratio



def main(g):
  # return
  # Main program block
  buff = ""
  conn = psycopg2.connect("dbname=bnl \
                         user=bnl \
                         host=prod.nonodev.com \
                         password=ld4BC9Q51FU9CYjC21gp \
                         sslmode=require \
                         application_name=serial_talker")

  bets = ['BACK_1_10_07_1_2_PLC_1_01',
          'BACK_1_10_10_1_2_PLC_1_01',
          'BACK_1_06_1_10_05_07_1_2_PLC_1_01',
          'BACK_1_11_1_15_01_04_1_2_PLC_1_01',
          'BACK_1_11_1_15_05_07_1_2_PLC_1_01',
          'BACK_1_11_1_15_08_10_1_2_PLC_1_01',
          'BACK_1_96_2_00_08_10_1_2_WIN_1_70',
          'LAY_1_80_10_WIN_4_10']

  row0 = {}
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 6
  row0['typ'] = 'Namn/# dagar sedan'

  lcd_row_0 = '%(typ)33s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  buff += '-------------------------------------------------------------------\r\n'
  buff += lcd_row_0 + '\r\n'
  buff += '-------------------------------------------------------------------\r\n'
#  print lcd_row_0


  for bet in bets :
    row1 = {}
    # offset days from monday
    row1['0'] = get_row(conn, bet,   row0['0'])
    row1['1'] = get_row(conn, bet, - row0['1'])
    row1['2'] = get_row(conn, bet, - row0['2'])
    row1['3'] = get_row(conn, bet, - row0['3'])
    row1['4'] = get_row(conn, bet, - row0['4'])
    row1['5'] = get_row(conn, bet, - row0['5'])
    row1['6'] = get_row(conn, bet, - row0['6'])

    if len(bet) > 33 :
      row1['typ'] = bet[:32].strip()
    else :
      row1['typ'] = bet

    lcd_row_1 = '%(typ)33s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row1
    buff += lcd_row_1 + '\r\n'

  row0['typ'] = 'Namn/# veckor sedan'
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 'Summa'
  buff += '-------------------------------------------------------------------\r\n'
  lcd_row_0 = '%(typ)33s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6s' % row0
  buff += lcd_row_0 + '\r\n'
  buff += '-------------------------------------------------------------------\r\n'

  for bet in bets :
    row2 = {}
    row2['0'] = get_row_weeks_back(conn, bet,   row0['0'])
    row2['1'] = get_row_weeks_back(conn, bet, - row0['1'])
    row2['2'] = get_row_weeks_back(conn, bet, - row0['2'])
    row2['3'] = get_row_weeks_back(conn, bet, - row0['3'])
    row2['4'] = get_row_weeks_back(conn, bet, - row0['4'])
    row2['5'] = get_row_weeks_back(conn, bet, - row0['5'])
    #remove HORSES_ from HORSES_WIN_9.0_10.0_GREENUP_GB_LB_7_2_5.0
    if len(bet) > 33 :
      row1['typ'] = bet[:32].strip()
    else :
      row2['typ'] = bet


    row2['6'] = int(row2['0']) +  int(row2['1']) + int(row2['2']) + \
                int(row2['3']) +  int(row2['4']) + int(row2['5'])
    lcd_row_2 = '%(typ)33s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row2
    buff += lcd_row_2 + '\r\n'

  row0['typ'] = 'S(profit)/S(size.m.)'
  row0['0'] = 4
  row0['1'] = 7
  row0['2'] = 14
  row0['3'] = 28
  row0['4'] = 182
  row0['5'] = 365
  row0['6'] = 900
  lcd_row_0 = '%(typ)33s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  buff += '-------------------------------------------------------------------\r\n'
  buff += lcd_row_0 + '\r\n'
  buff += '-------------------------------------------------------------------\r\n'

  for bet in bets :
    row3 = {}
    row3['0'] = get_bet_ratio(conn, bet, row0['0'])
    row3['1'] = get_bet_ratio(conn, bet, row0['1'])
    row3['2'] = get_bet_ratio(conn, bet, row0['2'])
    row3['3'] = get_bet_ratio(conn, bet, row0['3'])
    row3['4'] = get_bet_ratio(conn, bet, row0['4'])
    row3['5'] = get_bet_ratio(conn, bet, row0['5'])
    row3['6'] = get_bet_ratio(conn, bet, row0['6'])
    if len(bet) > 33 :
      row1['typ'] = bet[:32].strip()
    else :
      row3['typ'] = bet

    lcd_row_3 = '%(typ)33s%(0)6.2f%(1)6.2f%(2)6.2f%(3)6.2f%(4)6.2f%(5)6.2f%(6)6.2f' % row3
    buff += lcd_row_3 + '\r\n'


  #clear screen
  tmp = sp.call('clear',shell=True)
  #print to screen
  print buff[:-2]

  conn.close()
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

  g = Global_Obj()
  while True:
      try:
          main(g)
      except psycopg2.OperationalError:
          print 'Db not reachable or started?'
      except psycopg2.DatabaseError:
          print 'Bad database connection - dberror?'

#      time.sleep(60)
      for x in range(1, 48):
        time.sleep(1)
        sys.stdout.write('.')
      sys.stdout.write(' -> updating...')
