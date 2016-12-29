#!/usr/bin/python
# -*- coding: latin-1 -*-
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

    mon = day - datetime.timedelta(today.weekday())
    sun = mon + datetime.timedelta(days = 6)

    mon2 = datetime.datetime(mon.year, mon.month, mon.day, 0, 0, 0)
    sun2 = datetime.datetime(sun.year, sun.month, sun.day, 23, 59, 59)
    cur = conn.cursor()
    cur.execute("""
       select
          round(
                 sum(
                       case SUM_PROFIT > 0
                         when TRUE then SUM_PROFIT * (1.0 - (0.065))
                         when FALSE then SUM_PROFIT
                       end
                 ),
                 0
               )::numeric as PROFIT
       from
         PROFIT_PER_MARKET_AND_BETNAME
       where true
         and BETNAME = %s
         and STARTTS >= %s
         and STARTTS <= %s
       order by PROFIT desc  """ ,
         (betname, mon2, sun2))

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
    cur = conn.cursor()
    cur.execute("""
       select
          round(
                 sum(
                       case SUM_PROFIT > 0
                         when TRUE then SUM_PROFIT * (1.0 - (0.065))
                         when FALSE then SUM_PROFIT
                       end
                 ),
                 0
               )::numeric as PROFIT
       from
         PROFIT_PER_MARKET_AND_BETNAME
       where true
         and BETNAME = %s
         and STARTTS >= %s
         and STARTTS <= %s
       order by PROFIT desc  """ ,
             (betname,day_start,day_stop))

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
    ################################## end get_row

def get_profit(conn, betname, delta_days)  :
    cur = conn.cursor()
    cur.execute("""
       select
         round(
                sum(
                      case SUM_PROFIT > 0
                        when TRUE then SUM_PROFIT * (1.0 - (0.065))
                        when FALSE then SUM_PROFIT
                      end
                ),
                0
              )::numeric as PROFIT
      from
        PROFIT_PER_MARKET_AND_BETNAME
      where true
        and STARTTS::date > (select CURRENT_DATE - interval '%s days')
        and betname = %s
      order by PROFIT desc
                """,(delta_days,betname))

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
    ################################## end get_profit

def get_lay_risk(conn, betname, delta_days)  :
    cur = conn.cursor()
    cur.execute("""
        select sum(RISK) from (
        select
           MARKETID,
           max(SIZEMATCHED * (PRICEMATCHED-1)) as RISK
        from
          ABETS
        where true
        and STARTTS::date > (select CURRENT_DATE - interval '%s days')
          and BETNAME = %s
        group by MARKETID
        ) TMP
         """,(delta_days,betname))

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
    ################################## end get_lay_risk

def get_back_risk(conn, betname, delta_days)  :
    cur = conn.cursor()
    cur.execute("""
        select sum(RISK) from (
        select
           MARKETID,
           sum(SIZEMATCHED) as RISK
        from
          ABETS
        where true
        and STARTTS::date > (select CURRENT_DATE - interval '%s days')
          and BETNAME = %s
        group by MARKETID
        ) TMP
         """,(delta_days,betname))

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
    ################################## end get_back_risk

def get_bet_ratio(conn, betname, delta_days)  :

    # 1 if is laybet
    # 2 get sum risked

    # 3 if is backbet
    # 4 get sum risked

    # 5 get sum profit

    profit=0.0
    risked=1.0

    if betname[:3] == "LAY" :
      risked = get_lay_risk(conn, betname, delta_days)

    elif betname[:4] == "BACK" :
      risked = get_back_risk(conn, betname, delta_days)

    profit = get_profit(conn, betname, delta_days)
    #print betname, str(risked), str(profit)
    
    if int(risked) <= 0 : 
      return 0 # avoid div0

    return 100.0 * float(profit) / float(risked)
############
#end get_bet_ratio

def main(g):
  # return
  # Main program block
  buff = ""
  conn = psycopg2.connect("dbname=bnl \
                         user=bnl \
                         host=betbot.nonobet.com \
                         password=ld4BC9Q51FU9CYjC21gp \
                         sslmode=require \
                         application_name=serial_talker")

  bets = ['BACK_1_10_07_1_2_PLC_1_01',
          'BACK_1_11_1_15_05_07_1_2_PLC_1_01',
          'LAY_2_2_4_11_17_WIN']

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
  buff += '---------------------------------------------------------------------------\r\n'
  buff += lcd_row_0 + '\r\n'
  buff += '---------------------------------------------------------------------------\r\n'
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
  buff += '---------------------------------------------------------------------------\r\n'
  lcd_row_0 = '%(typ)33s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6s' % row0
  buff += lcd_row_0 + '\r\n'
  buff += '---------------------------------------------------------------------------\r\n'

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
  buff += '---------------------------------------------------------------------------\r\n'
  buff += lcd_row_0 + '\r\n'
  buff += '---------------------------------------------------------------------------\r\n'

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

      for x in range(1, 48):
        time.sleep(1)
        sys.stdout.write('.')
      sys.stdout.write(' -> updating...')
