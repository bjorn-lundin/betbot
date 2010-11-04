#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import datetime
import gzip

def get_date(data):
    date = 'NODATE'
    months = ['januari', 'februari', 'mars', 'april', 'maj', 'juni', 'juli', 
              'augusti','september', 'oktober', 'november', 'december']
    p = re.compile('(\w+) \w+ (\d{1,2}) (\w+) (\d{4})', (re.DOTALL | re.IGNORECASE | re.UNICODE))
    f = p.search(data)
    if f:
        year = int(f.group(4))
        month = int(months.index(f.group(3).lower()) + 1)
        day = int(f.group(2))
        date = datetime.date(year, month, day).strftime("%Y%m%d")
    return date

if __name__ == '__main__':
    data_dir = '/home/user/nonobet_new_all'
    source_files = os.listdir(data_dir)
    pattern = 'raceday_(\d+)_race_(\d+).'
    for file in source_files:
        match = re.match(pattern, file)
        if match:
            f_in = open(os.path.join(data_dir, file), 'rb')
            data = f_in.read()
            outfile = get_date(data) + '_rd_' + match.group(1) + '_r_' + match.group(2) + '.html.gz'
            print('infile:', file,'| outfile:', outfile)
            f_out = gzip.open(os.path.join(data_dir, outfile), 'wb')
            f_out.write(data)
            f_out.close()
            f_in.close()
