#!/bin/bash
domain=lundin.duckdns.org
token=c223b17c-f292-4c23-9ead-41ed91e01704
url="https://www.duckdns.org/update?domains=${domain}&token=${token}&ip="
echo url=${url} | curl -k -o /var/log/duck.log -K -
