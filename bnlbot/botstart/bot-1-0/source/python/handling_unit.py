#!/usr/bin/python
import pygame
import sys
import time
from time import strftime
import os
import json
 
#Set the framebuffer device to be the TFT
#os.environ["SDL_FBDEV"] = "/dev/fb1"

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
 
    while True:
        displayTime()
        pygame.display.flip()
        time.sleep(10)
 
        #graph = pygame.image.load("graph.gif")
        #graph = pygame.transform.rotate(graph, 270)
        #graphrect = graph.get_rect()
        #screen.blit(graph, graphrect)
        #pygame.display.flip()
        #time.sleep(10)
 
        displayText('Out. Humidity', 30, 1, (200,200,1), True )
        pygame.display.flip()
        time.sleep(10)
 
 
 
if __name__ == '__main__':
    main()

