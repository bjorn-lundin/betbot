#!/bin/bash

TMP_FILE=tmp.tmp

FILES=$(ls *.dat)
for f in $FILES ; do
  echo "fix $f - $(date)"
  #remove rows with Eventid in it
  grep -v Eventid $f > $TMP_FILE
  cat $TMP_FILE > $f
  
  #do some plotting here
  
done
rm -f $TMP_FILE  

