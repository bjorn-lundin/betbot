#!/usr/bin/python
 
import pygame
import sys
import time
from time import strftime
import os
import httplib
import urllib
import json
 
time_stamp_prev=0
 
#Set the framebuffer device to be the TFT
os.environ["SDL_FBDEV"] = "/dev/fb1"
 
#Get emoncms feed latest data
def getFeedVal(feedId):
    conn = httplib.HTTPConnection("*******SITE**********")
    conn.request("GET", "/emoncms3/feed/value.json?apikey=*******API**********&id=" + feedId)
    response = conn.getresponse()
    #print response.status, response.reason
    data = response.read()
    conn.close()
    return data
 
def getWUnder():
    global time_stamp_prev
    # Only fetch latest data once every while, or we will violate WU's rules
    if (time.time() - time_stamp_prev) > 15*60:
        time_stamp_prev = time.time()
        f = urllib.urlopen('http://api.wunderground.com/api/*******W.U. key**********/geolookup/conditions/q/sofia.json')
        json_string = f.read()
        parsed_json = json.loads(json_string)
        #temp_c = parsed_json['current_observation']['temp_c']
        #print "Current temperature in %s is: %s" % (location, temp_c)
        #Also see http://www.wunderground.com/weather/api/d/docs?d=resources/icon-sets
        iconurl = parsed_json['current_observation']['icon_url']
        urllib.urlretrieve (iconurl, "graph.gif")
        f.close()
 
        #http://www.wunderground.com/weather/api/d/docs?d=layers/satellite
        urllib.urlretrieve ("http://api.wunderground.com/api/*******W.U. key**********/satellite/q/KS/Sofia.gif?width=160&height=128&basemap=1","satellite.gif")
 
def displayTime():
#    """Used to display date and time on the TFT"""
    screen.fill((0,0,0))
    font = pygame.font.Font(None, 50)
    now=time.localtime()
 
    for setting in [("%H:%M:%S",60),("%d  %b",10)] :
         timeformat,dim=setting
         currentTimeLine = strftime(timeformat, now)
         text = font.render(currentTimeLine, 0, (0,250,150))
         Surf = pygame.transform.rotate(text, -90)
         screen.blit(Surf,(dim,20))
 
def displayText(text, size, line, color, clearScreen):
 
    """Used to display text to the screen. displayText is only configured to display
    two lines on the TFT. Only clear screen when writing the first line"""
    if clearScreen:
        screen.fill((0, 0, 0))
 
    font = pygame.font.Font(None, size)
    text = font.render(text, 0, color)
    textRotated = pygame.transform.rotate(text, -90)
    textpos = textRotated.get_rect()
    textpos.centery = 80  
    if line == 1:
         textpos.centerx = 90
         screen.blit(textRotated,textpos)
    elif line == 2:
        textpos.centerx = 40
        screen.blit(textRotated,textpos)
 
def main():
    global screen
    pygame.init()
 
    size = width, height = 128, 160
    black = 0, 0, 0
 
    pygame.mouse.set_visible(0)
    screen = pygame.display.set_mode(size)
 
#HP boiler=11
#Solar boiler=16
#Living room t=76
#Kids room t=18
#Outside temp=71
#Outside humidity=70
 
    while True:
 
        getWUnder()
 
        displayTime()
        pygame.display.flip()
        time.sleep(10)
 
        displayText('Outside Temp', 30, 1, (200,200,1), True )
        displayText(getFeedVal("71") + "C", 50, 2, (150,150,255), False )
 
        graph = pygame.image.load("graph.gif")
        graph = pygame.transform.rotate(graph, 270)
        graphrect = graph.get_rect()
        screen.blit(graph, graphrect)
 
        pygame.display.flip()
        time.sleep(10)
 
        displayText('Out. Humidity', 30, 1, (200,200,1), True )
        displayText(getFeedVal("70") + "%", 50, 2, (150,150,255), False )
        pygame.display.flip()
        time.sleep(10)
 
        displayText('Solar boiler', 30, 1, (200,200,1), True )
        displayText(getFeedVal("16") + "C", 50, 2, (150,150,255), False )
        pygame.display.flip()
        time.sleep(10)
 
        displayText('HP Boiler', 30, 1, (200,200,1), True )
        displayText(getFeedVal("11") + "C", 50, 2, (150,150,255), False )
        pygame.display.flip()
        time.sleep(10)
 
        urllib.urlretrieve ("http://******* path to my site**********.php", "graph.png")
        graph = pygame.image.load("graph.png")
        graph = pygame.transform.rotate(graph, 270)
        graphrect = graph.get_rect()
        screen.fill(black)
        screen.blit(graph, graphrect)
        pygame.display.flip()
        time.sleep(10)
 
        graph = pygame.image.load("satellite.gif")
        graph = pygame.transform.rotate(graph, 270)
        graphrect = graph.get_rect()
        screen.fill(black)
        screen.blit(graph, graphrect)
        pygame.display.flip()
        time.sleep(10)
 
if __name__ == '__main__':
    main()

