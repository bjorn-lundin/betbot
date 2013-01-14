Time zone
---------
Due to problems with Python datetime module (its inability to handle 
time zones correctly), set the production system time zone to 
'Europe/Stockholm' to match ATG in Stockholm, Sweden.

1. Check that hw clock uses UTC -> /etc/default/rcS -> UTC=yes
2. What is the current tz? -> /etc/timezone
3. Set new tz -> sudo dpkg-reconfigure tzdata

CET -> Europe/Stockholm
UTC -> Etc/UTC

Virtual Environment path
------------------------
Make sure run.sh contains the correct Python VIRTUAL_ENV path,
e.g. -> export VIRTUAL_ENV="/home/joabi/production/ais/py_env"
