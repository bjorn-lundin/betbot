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
{
    'q1':
    '''
SELECT
    p.marketid,
    p.pricets,
    r.runnername,
    p.selectionid,
    p.backprice,
    p.layprice,
    p.totalmatched
FROM
    aevents e,
    amarkets m,
    arunners r,
    apricesfinish p
WHERE
    e.eventid = m.eventid              -- joins
    AND m.marketid = r.marketid        -- joins
    AND m.marketid = p.marketid        -- joins
    AND r.selectionid = p.selectionid  -- joins
    AND r.status IN ('WINNER','LOSER') -- e.g. not 'REMOVED'
    AND e.eventtypeid = 7              -- horses
    AND m.markettype = 'WIN'           -- normal win market
    AND p.pricets::date = '2014-09-02'
    AND p.marketid = '1.115258242'
ORDER BY
    p.pricets, p.selectionid
    '''
    ,
    ##############################################################
    'q-with-marketid':
    '''
SELECT
    p.marketid,
    p.pricets,
    r.runnername,
    p.selectionid,
    p.backprice,
    p.layprice,
    p.totalmatched
FROM
    aevents e,
    amarkets m,
    arunners r,
    apricesfinish p
WHERE
    e.eventid = m.eventid
    AND m.marketid = r.marketid
    AND m.marketid = p.marketid
    AND r.selectionid = p.selectionid
    AND r.status IN %s
    AND e.eventtypeid = 7
    AND m.markettype = %s
    AND p.pricets::date IN %s
    AND p.marketid IN %s
ORDER BY
    p.pricets, p.selectionid
    '''
    ,
    ##############################################################
    'q-without-marketid':
    '''
SELECT
    p.marketid,
    p.pricets,
    r.runnername,
    p.selectionid,
    p.backprice,
    p.layprice,
    p.totalmatched
FROM
    aevents e,
    amarkets m,
    arunners r,
    apricesfinish p
WHERE
    e.eventid = m.eventid
    AND m.marketid = r.marketid
    AND m.marketid = p.marketid
    AND r.selectionid = p.selectionid
    AND r.status IN %s
    AND e.eventtypeid = 7
    AND m.markettype = %s
    AND p.pricets::date IN %s
ORDER BY
    p.pricets, p.selectionid
    '''
}

def named(name):
    '''
    Return query by name
    '''
    query = None
    if name in QUERIES:
        query = QUERIES[name]
    return query
