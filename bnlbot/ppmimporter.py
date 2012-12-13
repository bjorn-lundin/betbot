
import sys
import os


class PPM_Importer(object):
    """base object"""



    def treat_line(self, line) :
        keys = ['FONDNUMMER', 'FONDBOLAG', 'FONDNAMN', 'VALUTA','DATUM',\
                'VALUTAKURS_K' ,'VALUTAKURS_S','FONDKURS_K' ,'FONDKURS_S', \
                'FONDKURS_SEK_K' ,'FONDKURS_SEK_S' ]
        vals = line.split("\n")
        temp = dict(zip(keys, vals))
        print temp
    
    ##################################### 
    
    def main(self) :
        f = open('/Users/bnl/Downloads/ppm/Fondkurser_2004.txt')
        self.lines = f.readlines()
        f.close()

        for line in self.lines :
             self.treat_line(line)
    ##################################### 


sys.stdout = os.fdopen(sys.stdout.fileno(), 'w', 0)

importer = PPM_Importer()
importer.main()