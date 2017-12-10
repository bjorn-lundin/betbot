#!/bin/bash



while read line
do
  case $line in
    refer*) 
      OK=false
    ;;
     ----*)  
      OK=false 
    ;;
    "")  
      OK=false 
    ;;
    "     *")  
      OK=false 
    ;;
         *)  
       OK=true
    ;;
  esac

  if [ $OK == "true" ] ; then

    #lay=0002.42,tics=18 |  12.86


    f1=$(echo $line | cut -d'|' -f1)
    fsum=$(echo $line | cut -d'|' -f2)

    #f1=lay=0002.42,tics=18 
    #fsum=12.86


    tmp1=$(echo $f1 | cut -d',' -f1)
    price=$(echo $tmp1 | cut -d'=' -f2)


    tmp2=$(echo $f1 | cut -d',' -f2)
    dtics=$(echo $tmp2 | cut -d'=' -f2)


    price_new=$($BOT_TARGET/bin/price_to_tics --value=$price)

    echo "$price_new|$dtics|$fsum"

    if [ $dtics == "41" ] ; then
      echo ""
    fi
  fi

done < "${1:-/dev/stdin}"




