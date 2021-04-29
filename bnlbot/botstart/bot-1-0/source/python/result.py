"""
 Pygame base template for opening a window

 Sample Python/Pygame Programs
 Simpson College Computer Science
 http://programarcadegames.com/
 http://simpson.edu/computer-science/

 Explanation video: http://youtu.be/vRB_983kUMc
"""

import sys
import time
from time import strftime
import os
import urllib3
import json
import requests
import pygame
import logging
from logging.handlers import RotatingFileHandler


urllib3.disable_warnings()

# Define some colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
GREEN = (99, 255, 99)
RED = (255, 66, 66)

#URL='https://lundin.duckdns.org'
URL='https://192.168.1.7'

def isnumeric(s):
  try:
    f=float(s)
    return True
  except ValueError:
    return False


log = logging.getLogger('my_logger')
log.setLevel(logging.DEBUG)
#log.basicConfig(level=logging.DEBUG, format='%(asctime)s %(levelname)s:%(message)s')
handler = RotatingFileHandler('botresult.log', maxBytes=2000000, backupCount=10)
log.addHandler(handler)


def puts(what,size,x,y):
#    log.debug(what + " size=" + str(size) + " x=" + str(x) + " y=" +str(y))
    font = pygame.font.SysFont("freserif", size)
    color = WHITE
    if isnumeric(what):
        n = int(float(what))
        color = GREEN
        if n < 0 :
            color = RED
         
    text = font.render(what, True, color)
    screen.blit(text, (x - text.get_width() // 2, y - text.get_height() // 2))
#    time.sleep(1)


def get_data(sess, context):
   payload = {'context': context, 'dummy': str(time.time())}
   r = sess.get(URL, params=payload, verify=False)
   data = json.loads(r.text)
#   log.debug("today %s"  % data['total'] )
   return data

log.debug("start")
#logging.basicConfig(filename='botresult.log',level=logging.DEBUG, format='%(asctime)s %(levelname)s:%(message)s')
s = None
os.environ["SDL_FBDEV"] = "/dev/fb1"


pygame.init()
# Set the width and height of the screen [width, height]
size = (320, 240)
screen = pygame.display.set_mode(size)
pygame.mouse.set_visible(0)

done = False
clock = pygame.time.Clock()
cnt = 100
# -------- Main Program Loop -----------
while not done:
  try:
    # --- Main event loop

    # --- Limit to 1 frames per second
    cnt = cnt + 1

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True
        elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
            done = True

    if cnt > 100 :
      cnt = 0
      # --- Game logic should go here

      # --- Screen-clearing code goes here

      # Here, we clear the screen to white. Don't put other drawing commands
      # above this, or they will be erased with this command.

      # If you want a background image, replace this clear with blit'ing the
      # background image.
      screen.fill(BLACK)

      #get a seession  if not already in one
      payload = {'context': 'check_logged_in', 'dummy': str(time.time())}
      if s == None :
        s = requests.session()

      r = s.get(URL, params=payload, verify=False)

      if r.status_code == 200:
        pass
      elif r.status_code == 401:
      # login needed
        payload = {'username': 'bnl', 'context': 'login'}
        r = s.post(URL, params=payload, verify=False)

      today = get_data(s, 'todays_bets_total')
      this_week = get_data(s, 'thisweeks_bets_total')
      last_week = get_data(s, 'lastweeks_bets_total')
      this_month = get_data(s, 'thismonths_bets_total')
      last_month = get_data(s, 'lastmonths_bets_total')

      # --- Drawing code should go here
      puts(str(int(today['total'])),     150, 160,  60)
      puts(str(int(this_week['total'])),  75,  80, 140)
      puts(str(int(last_week['total'])),  75,  80, 200)
      puts(str(int(this_month['total'])), 75, 240, 140)
      puts(str(int(last_month['total'])), 75, 240, 200)

      # --- Go ahead and update the screen with what we've drawn.
      pygame.display.flip()
    else:
#      log.debug("sleeping %s"  % str(cnt) )
      clock.tick(1)

  except ValueError :
    log.exception("ValueError exception - server down? try again.")
    screen.fill(RED)
    puts("server down?", 50, 160, 120)
    pygame.display.flip()

  except Exception :
    log.exception("generic exception")
    screen.fill(RED)
    puts("generic exception", 50, 160, 120)
    pygame.display.flip()

# Close the window and quit.
pygame.quit()
exit()
