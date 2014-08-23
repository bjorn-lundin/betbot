# class def. from http://learn.adafruit.com/pi-video-output-using-pygame/pointing-pygame-to-the-framebuffer
# blah, blah...
#import os
#import random
#import time
#from time import strftime
#from time import sleep

import pygame
import psycopg2
import sys
import datetime
import signal
import pyscope
import thermal_printer


############ BNL start ####################
def signal_handler(signal, frame):
        pygame.event.post(pygame.event.Event(pygame.QUIT))
        print '\nYou pressed Ctrl+C, will post QUIT)\n'
############end signal_handler #######################

class global_obj():
    profit = 0
    exposure = 0
    time_to_print = None

    def __init__(self) :
      today = datetime.datetime.now()
      self.time_to_print = datetime.datetime(today.year, today.month, today.day, 23, 55, 0)

    ############end __init__ #######################

    def to_string(self) :
        print 'to_string.profit', self.profit
        print 'to_string.exposure', self.exposure
        print 'to_string.ts', self.ts
        print 'to_string.last_print_ts', self.last_print_ts
    ############end to_string #######################

############end global_obj #######################

class progress_bar():
    left   =  50
    top    = 220
    height =  10
    width  = 220

    def __init__(self,screen):
        self.s = screen
      
    def update(self,progress):
        RED   = (255, 0, 0) 
        GREEN = (0, 255, 0) 
        WHITE = (255, 255, 255) 
        BLACK = (0, 0, 0) 
        GRAY = (128,128,128)
    
        pygame.draw.rect(self.s, GREEN, pygame.Rect(0,0,320,240),1)
        pygame.draw.rect(self.s, WHITE, pygame.Rect(self.left, self.top, self.width*progress, self.height))
        pygame.draw.rect(self.s, WHITE, pygame.Rect(self.left, self.top, self.width, self. height), 1)

    ############ end update ###############

############ end progressbar ###############

#def findout_result_change(conn, g, s):
def findout_result_change(conn, g):
    #only if the real db is connected
    #get todays profit up til now
    today = datetime.datetime.now()
    start = datetime.datetime(today.year, today.month, today.day, 0, 0, 0)
    stop = datetime.datetime(today.year, today.month, today.day, 23, 59, 59)
    cur = conn.cursor()
    cur.execute("select sum(B.PROFIT)  \
                 from ABETS B   \
                 where B.BETWON is not NULL  \
                 and BETNAME not like 'DR%%'  \
                 and B.BETPLACED >= %s  \
                 and B.BETPLACED <= %s " ,
                 (start, stop))
    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[0]
        else :
          result = 0

    if result is None:
        result = 0

    g.profit = int(result)
    cur.close()
    conn.commit()

############ end findout_result_change ###############

def findout_exposure(conn, g):
    #only if the real db is connected
    #get current exposure
    today = datetime.datetime.now()
    start = datetime.datetime(today.year, today.month, today.day, 0, 0, 0)
    stop = datetime.datetime(today.year, today.month, today.day, 23, 59, 59)
    cur = conn.cursor()
    cur.execute("select sum(B.SIZE)  \
                 from ABETS B   \
                 where B.BETWON is NULL  \
                 and BETNAME not like 'DR%%'  \
                 and B.BETPLACED >= %s  \
                 and B.BETPLACED <= %s " ,
                 (start, stop))
    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[0]
        else :
          result = 0

    if result is None:
        result = 0

    g.exposure = int(result)
    cur.close()
    conn.commit()
############ end findout_exposure ###############

def print_to_printer(p,g):
    p.linefeed()
    p.print_text("-----------------------")
    p.linefeed()
    p.print_text(str(g.time_to_print))
    p.linefeed()
    p.print_text("Totalt " + str(g.profit) + " kr vinst idag!\n")
    p.linefeed()
    p.print_text("-----------------------")
    p.linefeed()
    p.linefeed()
    p.linefeed()

############ end print_to_printer ###############

def show(c,g,s,p):
  #check and perhaps print to screen
#  findout_result_change(c, g, s)
  findout_result_change(c, g)
  s.display_profit(g.profit)
  findout_exposure(c, g)
  s.display_exposure(g.exposure)
  today = datetime.datetime.now()

  if today > g.time_to_print :
        print_to_printer(p,g)
        #next print time is a day from now
        g.time_to_print = g.time_to_print + datetime.timedelta(days=1)
        
########### end show #############################

## start main
#set signal handler for ctrl-C
signal.signal(signal.SIGINT, signal_handler)

# Create an instance of the PyScope class
s = pyscope.pyscope()
pb = progress_bar(s.screen)
g = global_obj()
p = thermal_printer.thermal_printer(serialport='/dev/ttyAMA0')

cnt = 600
maxcnt = cnt / 1.0 # make it a float
while True:
    cnt = cnt + 1
    event = pygame.event.poll()
#    print 'eventname = ', pygame.event.event_name(event.type)
    if event.type is pygame.QUIT:
        break
    elif event.type is pygame.KEYDOWN:
       keyname = pygame.key.name(event.key)
#       print 'keyname = ', keyname
       if event.key == pygame.K_ESCAPE:
           break
    elif event.type is pygame.NOEVENT:
        if cnt >= maxcnt :
            s.clearScreen()
            try:
                c = psycopg2.connect("dbname=bnl \
                      user=bnl \
                      host=db.nonodev.com \
                      password=BettingFotboll1$ \
                      sslmode=require \
                      application_name=serial_printer")
                pb.update(0.0)
                show(c,g,s,p)
                cnt = 0
                c.close()
            except psycopg2.OperationalError:
                s.displayText('Bad Network?' , 30, 1, (200,200,1), True )
        else :
            progress = cnt / maxcnt
            pb.update(progress)

    pygame.display.update()
    pygame.time.delay(100)

#c.close()
