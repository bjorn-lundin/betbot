#######################
## framebuffer stuff

import os
import pygame
import datetime
#import time
#from time import strftime
#from time import sleep
#import random
#import psycopg2
#import sys

class pyscope :
    screen = None;

    def __init__(self):
        "Ininitializes a new pygame screen using the framebuffer"
        # Based on "Python GUI in Linux frame buffer"
        # http://www.karoltomala.com/blog/?p=679
        #Set the framebuffer device to be the TFT
        os.environ["SDL_FBDEV"] = "/dev/fb1"
        disp_no = os.getenv("DISPLAY")
        if disp_no:
            print "I'm running under X display = {0}".format(disp_no)
        else:    
            print "I'm NOT running under X display "
            # Check which frame buffer drivers are available
            # Start with fbcon since directfb hangs with composite output
            drivers = ['fbcon', 'directfb', 'svgalib']
            found = False
            for driver in drivers:
                # Make sure that SDL_VIDEODRIVER is set
                if not os.getenv('SDL_VIDEODRIVER'):
                    os.putenv('SDL_VIDEODRIVER', driver)
                try:
                    pygame.display.init()
                except pygame.error:
                    print 'Driver: {0} failed.'.format(driver)
                    continue
                found = True
                break
    
            if not found:
                raise Exception('No suitable video driver found!')
                
                
        size = (pygame.display.Info().current_w, pygame.display.Info().current_h)
        print "Framebuffer size: %d x %d" % (size[0], size[1])
        self.screen = pygame.display.set_mode(size, pygame.FULLSCREEN)
        # Clear the screen to start
        self.screen.fill((0, 0, 0))
        # Initialise font support
        pygame.font.init()
        # Render the screen
        pygame.display.update()

    def __del__(self):
        "Destructor to make sure pygame shuts down, etc."

    def test(self):
        # Fill the screen with red (255, 0, 0)
        red = (255, 0, 0)
        self.screen.fill(red)
        # Update the display
        pygame.display.update()
     
    def clearScreen(self) :
        self.screen.fill((0, 0, 0))
    
     
    def displayText(self, sometext, size, line, color, clearScreen):
     
        """Used to display text to the screen. displayText is only configured to display
        two lines on the TFT. Only clear screen when writing the first line"""
        if clearScreen:
            self.clearScreen()
     
        font = pygame.font.Font(None, size)
        text = font.render(sometext, 0, color)
        textpos = text.get_rect()
        textpos.centerx = 160
        if line == 1:
             textpos.centery = 50
             self.screen.blit(text,textpos)
        elif line == 2:
            textpos.centery = 140
            self.screen.blit(text,textpos)


    def display_profit(self,profit):
        pygame.mouse.set_visible(0)
        today = datetime.datetime.now()
        self.displayText('Vinst ' + str(today)[:-7] , 30, 1, (200,200,1), True )
        self.displayText(str(profit) + "", 200, 2, (150,150,255), False )
        pygame.display.flip()
#        pygame.display.update()
