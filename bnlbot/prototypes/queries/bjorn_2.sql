select MW.*,MP.* from AMARKETS MW, AMARKETS MP 
        where MW.EVENTID = MP.EVENTID
        and MW.STARTTS = MP.STARTTS 
        and MW.MARKETID = '1.114498877' 
        and MP.MARKETTYPE = 'PLACE' 
        and MW.MARKETTYPE = 'WIN'