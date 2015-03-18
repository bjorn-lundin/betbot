'''
DB queries for Betfair analysis

Betfair specifics
-----------------
eventtypeid
    1 = football
    7 = horses
    4339 = hounds

For horses
    7 -> WIN, PLACE

Bjorn specifics
---------------
aprices
    Starting odds about 10 seconds before race start

apricefinish
    Winner odds during race

araceprice
    Place odds during race (and others e.g. football etc.?)
'''

QUERIES = \
    [
        [
            'Getting all events'
            ,
            '''
            SELECT * FROM aevents LIMIT 1;
            '''
        ]
        ,
        [
            'Counting events from 2014-09-03'
            ,
            '''
            SELECT COUNT(*) FROM aevents
            WHERE
                date(opents) = '2014-09-03';
            '''
        ]
        ,
        [
            'Events from 2014-09-03 in GB'
            ,
            '''
            SELECT * FROM aevents
            WHERE
                date(opents) = '2014-09-03' AND
                countrycode = 'GB'
            LIMIT 1;
            '''
        ]
        ,
        [
            'Horse events from 2014-09-03 in GB'
            ,
            '''
            SELECT * FROM aevents
            WHERE
                date(opents) = '2014-09-06' AND
                countrycode = 'GB' AND
                eventtypeid = 7;
            '''
        ]
        ,
        [
            'WIN markets 2014-09-03 for eventid 27259029'
            ,
            '''
            SELECT * FROM amarkets
            WHERE
                markettype = 'WIN' AND
                startts::date = '2014-09-03' AND
                eventid = '27259029';
            '''
        ]
        ,
        [
            'PLACE markets 2014-09-03 for eventid 27259029'
            ,
            '''
            SELECT * FROM amarkets
            WHERE
                markettype = 'PLACE' AND
                startts::date = '2014-09-03' AND
                eventid = '27259029';
            '''
        ]
        ,
        [
            'Runners marketid 1.115273091/2014-09-03/eventid 27259029'
            ,
            '''
            SELECT * FROM arunners
            WHERE marketid = '1.115273091'
            '''
        ]
        ,
        [
            'Win odds marketid 1.115273091/selectionid 8491112'
            ,
            '''
            SELECT * FROM araceprices
            WHERE
                marketid = '1.115273091' AND
                selectionid = 8491112
            '''
        ]
    ]

