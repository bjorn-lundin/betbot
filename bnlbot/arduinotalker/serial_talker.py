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
import serial
import signal




    
class ThermalPrinter(object):
    """ 
        
        Thermal printing library that controls the "micro panel thermal printer" sold in
        shops like Adafruit and Sparkfun (e.g. http://www.adafruit.com/products/597). 
        Mostly ported from Ladyada's Arduino library 
        (https://github.com/adafruit/Adafruit-Thermal-Printer-Library) to run on
        BeagleBone and Raspberry Pi.

        Currently handles printing image data and text, but the rest of the
        built-in functionality like underlining and barcodes are trivial
        to port to Python when needed.

        If on BeagleBone or similar device, remember to set the mux settings
        or change the UART you are using. See the beginning of this file for
        default setup.

        Thanks to Matt Richardson for the initial pointers on controlling the
        device via Python.

        @author: Lauri Kainulainen 

    """

    # default serial port for the Beagle Bone
    #SERIALPORT = '/dev/ttyO2'
    # this might work better on a Raspberry Pi
    SERIALPORT = '/dev/ttyAMA0'

    BAUDRATE = 19200
    TIMEOUT = 3

    # pixels with more color value (average for multiple channels) are counted as white
    # tweak this if your images appear too black or too white
    black_threshold = 48
    # pixels with less alpha than this are counted as white
    alpha_threshold = 127

    printer = None

    _ESC = chr(27)

    # These values (including printDensity and printBreaktime) are taken from 
    # lazyatom's Adafruit-Thermal-Library branch and seem to work nicely with bitmap 
    # images. Changes here can cause symptoms like images printing out as random text. 
    # Play freely, but remember the working values.
    # https://github.com/adafruit/Adafruit-Thermal-Printer-Library/blob/0cc508a9566240e5e5bac0fa28714722875cae69/Thermal.cpp
    
    # Set "max heating dots", "heating time", "heating interval"
    # n1 = 0-255 Max printing dots, Unit (8dots), Default: 7 (64 dots)
    # n2 = 3-255 Heating time, Unit (10us), Default: 80 (800us)
    # n3 = 0-255 Heating interval, Unit (10us), Default: 2 (20us)
    # The more max heating dots, the more peak current will cost
    # when printing, the faster printing speed. The max heating
    # dots is 8*(n1+1). The more heating time, the more density,
    # but the slower printing speed. If heating time is too short,
    # blank page may occur. The more heating interval, the more
    # clear, but the slower printing speed.
    
    def __init__(self, heatTime=80, heatInterval=2, heatingDots=7, serialport=SERIALPORT):
        self.printer = serial.Serial(serialport, self.BAUDRATE, timeout=self.TIMEOUT)
        self.printer.write(self._ESC) # ESC - command
        self.printer.write(chr(64)) # @   - initialize
        self.printer.write(self._ESC) # ESC - command
        self.printer.write(chr(55)) # 7   - print settings
        self.printer.write(chr(heatingDots))  # Heating dots (20=balance of darkness vs no jams) default = 20
        self.printer.write(chr(heatTime)) # heatTime Library default = 255 (max)
        self.printer.write(chr(heatInterval)) # Heat interval (500 uS = slower, but darker) default = 250

        # Description of print density from page 23 of the manual:
        # DC2 # n Set printing density
        # Decimal: 18 35 n
        # D4..D0 of n is used to set the printing density. Density is 50% + 5% * n(D4-D0) printing density.
        # D7..D5 of n is used to set the printing break time. Break time is n(D7-D5)*250us.
        printDensity = 15 # 120% (? can go higher, text is darker but fuzzy)
        printBreakTime = 15 # 500 uS
        self.printer.write(chr(18))
        self.printer.write(chr(35))
        self.printer.write(chr((printDensity << 4) | printBreakTime))

    def reset(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(64))

    def linefeed(self):
        self.printer.write(chr(10))

    def justify(self, align="L"):
        pos = 0
        if align == "L":
            pos = 0
        elif align == "C":
            pos = 1
        elif align == "R":
            pos = 2
        self.printer.write(self._ESC)
        self.printer.write(chr(97))
        self.printer.write(chr(pos))

    def bold_off(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(69))
        self.printer.write(chr(0))

    def bold_on(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(69))
        self.printer.write(chr(1))

    def font_b_off(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(33))
        self.printer.write(chr(0))

    def font_b_on(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(33))
        self.printer.write(chr(1))

    def underline_off(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(45))
        self.printer.write(chr(0))

    def underline_on(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(45))
        self.printer.write(chr(1))

    def inverse_off(self):
        self.printer.write(chr(29))
        self.printer.write(chr(66))
        self.printer.write(chr(0))

    def inverse_on(self):
        self.printer.write(chr(29))
        self.printer.write(chr(66))
        self.printer.write(chr(1))

    def upsidedown_off(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(123))
        self.printer.write(chr(0))

    def upsidedown_on(self):
        self.printer.write(self._ESC)
        self.printer.write(chr(123))
        self.printer.write(chr(1))
        
    def barcode_chr(self, msg):
        self.printer.write(chr(29)) # Leave
        self.printer.write(chr(72)) # Leave
        self.printer.write(msg)     # Print barcode # 1:Abovebarcode 2:Below 3:Both 0:Not printed
        
    def barcode_height(self, msg):
        self.printer.write(chr(29))  # Leave
        self.printer.write(chr(104)) # Leave
        self.printer.write(msg)      # Value 1-255 Default 50
        
    def barcode_height(self):
        self.printer.write(chr(29))  # Leave
        self.printer.write(chr(119)) # Leave
        self.printer.write(chr(2))   # Value 2,3 Default 2
        
    def barcode(self, msg):
        """ Please read http://www.adafruit.com/datasheets/A2-user%20manual.pdf
            for information on how to use barcodes. """
        # CODE SYSTEM, NUMBER OF CHARACTERS        
        # 65=UPC-A    11,12    #71=CODEBAR    >1
        # 66=UPC-E    11,12    #72=CODE93    >1
        # 67=EAN13    12,13    #73=CODE128    >1
        # 68=EAN8    7,8    #74=CODE11    >1
        # 69=CODE39    >1    #75=MSI        >1
        # 70=I25        >1 EVEN NUMBER           
        self.printer.write(chr(29))  # LEAVE
        self.printer.write(chr(107)) # LEAVE
        self.printer.write(chr(65))  # USE ABOVE CHART
        self.printer.write(chr(12))  # USE CHART NUMBER OF CHAR 
        self.printer.write(msg)
        
    def print_text(self, msg, chars_per_line=None):
        """ Print some text defined by msg. If chars_per_line is defined, 
            inserts newlines after the given amount. Use normal '\n' line breaks for 
            empty lines. """ 
        if chars_per_line == None:
            self.printer.write(msg)
        else:
            l = list(msg)
            le = len(msg)
            for i in xrange(chars_per_line + 1, le, chars_per_line + 1):
                l.insert(i, '\n')
            self.printer.write("".join(l))
            print "".join(l)

    def print_markup(self, markup):
        """ Print text with markup for styling.

        Keyword arguments:
        markup -- text with a left column of markup as follows:
        first character denotes style (n=normal, b=bold, u=underline, i=inverse, f=font B)
        second character denotes justification (l=left, c=centre, r=right)
        third character must be a space, followed by the text of the line.
        """
        lines = markup.splitlines(True)
        for l in lines:
            style = l[0]
            justification = l[1].upper()
            text = l[3:]

            if style == 'b':
                self.bold_on()
            elif style == 'u':
               self.underline_on()
            elif style == 'i':
               self.inverse_on()
            elif style == 'f':
                self.font_b_on()

            self.justify(justification)
            self.print_text(text)
            if justification != 'L':
                self.justify()

            if style == 'b':
                self.bold_off()
            elif style == 'u':
               self.underline_off()
            elif style == 'i':
               self.inverse_off()
            elif style == 'f':
                self.font_b_off()

    def convert_pixel_array_to_binary(self, pixels, w, h):
        """ Convert the pixel array into a black and white plain list of 1's and 0's
            width is enforced to 384 and padded with white if needed. """
        black_and_white_pixels = [1] * 384 * h
        if w > 384:
            print "Bitmap width too large: %s. Needs to be under 384" % w
            return False
        elif w < 384:
            print "Bitmap under 384 (%s), padding the rest with white" % w

        print "Bitmap size", w

        if type(pixels[0]) == int: # single channel
            print " => single channel"
            for i, p in enumerate(pixels):
                if p < self.black_threshold:
                    black_and_white_pixels[i % w + i / w * 384] = 0
                else:
                    black_and_white_pixels[i % w + i / w * 384] = 1
        elif type(pixels[0]) in (list, tuple) and len(pixels[0]) == 3: # RGB
            print " => RGB channel"
            for i, p in enumerate(pixels):
                if sum(p[0:2]) / 3.0 < self.black_threshold:
                    black_and_white_pixels[i % w + i / w * 384] = 0
                else:
                    black_and_white_pixels[i % w + i / w * 384] = 1
        elif type(pixels[0]) in (list, tuple) and len(pixels[0]) == 4: # RGBA
            print " => RGBA channel"
            for i, p in enumerate(pixels):
                if sum(p[0:2]) / 3.0 < self.black_threshold and p[3] > self.alpha_threshold:
                    black_and_white_pixels[i % w + i / w * 384] = 0
                else:
                    black_and_white_pixels[i % w + i / w * 384] = 1
        else:
            print "Unsupported pixels array type. Please send plain list (single channel, RGB or RGBA)"
            print "Type pixels[0]", type(pixels[0]), "haz", pixels[0]
            return False

        return black_and_white_pixels


    def print_bitmap(self, pixels, w, h, output_png=False):
        """ Best to use images that have a pixel width of 384 as this corresponds
            to the printer row width. 
            
            pixels = a pixel array. RGBA, RGB, or one channel plain list of values (ranging from 0-255).
            w = width of image
            h = height of image
            if "output_png" is set, prints an "print_bitmap_output.png" in the same folder using the same
            thresholds as the actual printing commands. Useful for seeing if there are problems with the 
            original image (this requires PIL).

            Example code with PIL:
                import Image, ImageDraw
                i = Image.open("lammas_grayscale-bw.png")
                data = list(i.getdata())
                w, h = i.size
                p.print_bitmap(data, w, h)
        """
        counter = 0
        if output_png:
            import Image, ImageDraw
            test_img = Image.new('RGB', (384, h))
            draw = ImageDraw.Draw(test_img)

        self.linefeed()
        
        black_and_white_pixels = self.convert_pixel_array_to_binary(pixels, w, h)        
        print_bytes = []

        # read the bytes into an array
        for rowStart in xrange(0, h, 256):
            chunkHeight = 255 if (h - rowStart) > 255 else h - rowStart
            print_bytes += (18, 42, chunkHeight, 48)
            
            for i in xrange(0, 48 * chunkHeight, 1):
                # read one byte in
                byt = 0
                for xx in xrange(8):
                    pixel_value = black_and_white_pixels[counter]
                    counter += 1
                    # check if this is black
                    if pixel_value == 0:
                        byt += 1 << (7 - xx)
                        if output_png: draw.point((counter % 384, round(counter / 384)), fill=(0, 0, 0))
                    # it's white
                    else:
                        if output_png: draw.point((counter % 384, round(counter / 384)), fill=(255, 255, 255))
                
                print_bytes.append(byt)
        
        # output the array all at once to the printer
        # might be better to send while printing when dealing with 
        # very large arrays...
        for b in print_bytes:
            self.printer.write(chr(b))   
        
        if output_png:
            test_print = open('print-output.png', 'wb')
            test_img.save(test_print, 'PNG')
            print "output saved to %s" % test_print.name
            test_print.close()           



############ BNL start ####################
def signal_handler(signal, frame):
        print 'You pressed Ctrl+C!\n'
        sys.exit(0)


def printout_result_change(conn, pl, gl):
    #only if the real db is connected   
    if gl.source == 1 : return
    #get todays profit up til now
#    print 'in printout_result_change'
    today = datetime.datetime.now()
    start = datetime.datetime(today.year, today.month, today.day, 0, 0, 0)
    stop = datetime.datetime(today.year, today.month, today.day, 23, 59, 59)
    cur = conn.cursor()
    cur.execute("select sum(B.PROFIT) " \
                 "from ABETS B  " \
                 "where B.BETWON is not NULL " \
                 "and B.BETPLACED >= %s " \
                 "and B.BETPLACED <= %s " ,
                   (start, stop))
    if cur.rowcount >= 1 :
        row = cur.fetchone()
        if row :
          result = row[0]
        else :
          result = 0
    profit = int(result)
#    print 'cur.rowcount', cur.rowcount
#    print 'profit', profit
#    print 'gl.profit', gl.profit
#    print 'today.day', today.day
#    print 'gl.ts.day', gl.ts.day

    if ( today.year > gl.ts.year ) or \
       ( today.year == gl.ts.year and today.month > gl.ts.month  )  or \
       ( today.year == gl.ts.year and today.month == gl.ts.month and today.day > gl.ts.day ) :
#        print 'wrong day, reset day and profit'
        gl.profit = 0
        gl.ts = today
    elif today.day == gl.ts.day:
        if profit > gl.profit :
           # print 'happy'
            p.linefeed()
            p.print_text(str(today) + '\n')
            p.print_text("yes :-) " + str(profit) + " vinst hittils\n")
            p.print_text("-----------------------")
            p.linefeed()
            p.linefeed()
            p.linefeed()

        elif profit < gl.profit :
#            print 'sad'
            p.linefeed()
            p.print_text(str(today) + '\n')
            p.print_text("Nej :-( " + str(profit) + " förlust hittils\n")
            p.print_text("-----------------------")
            p.linefeed()
            p.linefeed()
            p.linefeed()
#        else :
#            print 'noprint'
        gl.profit = profit
    cur.close()
    conn.commit()
 #   print 'out printout_result_change'

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




def main(g,p):
  # return
  # Main program block
  buff = ""
  if g.source == 1 :
    g.source = 2
  else :
    g.source = 1

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

    bets = ['HORSES_WIN_BACK_FINISH_1.10_7.0',
            'HORSES_PLC_BACK_FINISH_1.10_7.0_1',
            'HORSES_WIN_BACK_FINISH_1.15_7.0',
            'HORSES_PLC_BACK_FINISH_1.15_7.0_1',
            'HORSES_WIN_LAY_FINISH_1.15_7.0_3',
            'DR_HORSES_WIN_LAY_FINISH_1.15_7.0_3',
            'DR_HORSES_WIN_LAY_FINISH_1.15_7.0_4',
            'HUMAN_MATCH_3.5_6.0_GREENUP_GB_LB',
            'HORSES_WIN_6.8_8.2_LAY_GB_7_1_6']


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

  lcd_row_0 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row0
  buff += lcd_row_0 + '\r\n'
#  print lcd_row_0

  buff += '------------------------------------------------------------------------------\r\n'

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
    #remove HORSES_ from HORSES_WIN_9.0_10.0_GREENUP_GB_LB_7_2_5.0
    row1['typ'] = bet[7:]
    lcd_row_1 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row1
    buff += lcd_row_1 + '\r\n'
  buff += '------------------------------------------------------------------------------\r\n'

  row0['typ'] = 'Typ av bet/result veckor tillbaka'
  row0['0'] = 0
  row0['1'] = 1
  row0['2'] = 2
  row0['3'] = 3
  row0['4'] = 4
  row0['5'] = 5
  row0['6'] = 'Summa'
  lcd_row_0 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6s' % row0
  buff += lcd_row_0 + '\r\n'
  buff += '------------------------------------------------------------------------------\r\n'

  for bet in bets :
    row2 = {}
    row2['0'] = get_row_weeks_back(conn, bet,  0)
    row2['1'] = get_row_weeks_back(conn, bet, -1)
    row2['2'] = get_row_weeks_back(conn, bet, -2)
    row2['3'] = get_row_weeks_back(conn, bet, -3)
    row2['4'] = get_row_weeks_back(conn, bet, -4)
    row2['5'] = get_row_weeks_back(conn, bet, -5)
    #remove HORSES_ from HORSES_WIN_9.0_10.0_GREENUP_GB_LB_7_2_5.0
    row2['typ'] = bet[7:]

    row2['6'] = int(row2['0']) +  int(row2['1']) + int(row2['2']) + \
                int(row2['3']) +  int(row2['4']) + int(row2['5'])
    lcd_row_2 = '%(typ)36s%(0)6d%(1)6d%(2)6d%(3)6d%(4)6d%(5)6d%(6)6d' % row2
    buff += lcd_row_2 + '\r\n'

  #print to screen  
  print buff[:-2]
  #check and perhaps print to printer  
  printout_result_change(conn, p, g)
    
  conn.close()
#  return source

#  sys.stdout.write("fghj")
#  ser = serial.Serial(
#    port='/dev/ttyUSB0',
#    baudrate=38400,
#    parity=serial.PARITY_NONE,
#    stopbits=serial.STOPBITS_ONE,
#    bytesize=serial.EIGHTBITS)
#  ser.open()
#  ser.write(buff)
#  ser.close()
#############################################################

class Global_Obj():
    source = 1
    profit = 0
    ts =  datetime.datetime.now() - datetime.timedelta(days=1)
    def to_string(self) :
        print 'to_string.source', self.source
        print 'to_string.profit', self.profit
        print 'to_string.ts', self.ts
    
if __name__ == '__main__':
  #make print flush now!
  sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)
  signal.signal(signal.SIGINT, signal_handler)
#  global_source = 1
#  global_profit = 0
  #make it yesterday to force check due to wrong day
#  global_today =  datetime.datetime.now() - datetime.timedelta(days=1)
  g = Global_Obj()
  
  p = ThermalPrinter(serialport=ThermalPrinter.SERIALPORT)
  
  
  
  while True:
#      print '------------'
#      g.to_string()
      main(g,p)
      time.sleep(60)
#      for x in range(0, 78):
#        time.sleep(1)
#        sys.stdout.write('.')

