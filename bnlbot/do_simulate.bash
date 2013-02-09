#!/bin/bash

names="Vinnare Plats"
animals="horse hound"
bet_types="lay back"
names_football="Utvisning udda 0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 lagen straff"
#names_football="2.5 3.5 4.5 udda"
val="1 2"
start_date="2013-02-01"
stop_date="2013-02-07"

#date_list="2013-01-31 2013-02-01 2013-02-02 2013-02-03 2013-02-04 2013-02-05 2013-02-06"
date_list="2013-02-07"



while getopts "w:t:" opt; do
  case $opt in
    w)
      what=$OPTARG
      ;;
    t)
      time_type=$OPTARG
      ;;
    *)
      echo "$0 -w [football|animals] -t [daily|weekly|monthly]" >&2
      exit 1
      ;;
  esac
done

echo "$what , $time_type" >&2


case "$what" in

    football )
        case "$time_type" in
            weekly )
                for bet_name in $names_football ; do
                    for valet in $val ; do
                        python simulator3.py \
                          --bet_type=back \
                          --bet_name=$bet_name \
                          --saldo=10000 \
                          --start_date=$start_date \
                          --stop_date=$stop_date \
                          --size=30 \
                          --animal=human \
                          --index=$valet \
                          --summary --plot &
                    done
                done
            ;;

            daily)
                for d in $date_list ; do
                    for bet_name in $names_football ; do
                        for valet in $val ; do
                            python simulator3.py \
                              --bet_type=back \
                              --bet_name=$bet_name \
                              --saldo=10000 \
                              --start_date=$d \
                              --stop_date=$d \
                              --size=30 \
                              --animal=human \
                              --index=$valet \
                              --summary --plot &
                        done
                    done
                done
            ;;
          *)
           echo "fel 1"
          ;;
        esac    
    ;;         
             
    animals )  
        case "$time_type" in
            daily )
                for d in $date_list ; do
                    for bet_name in $names ; do
                        for bet_type in $bet_types ; do
                            for animal in $animals ; do
                                python simulator3.py \
                                  --bet_type=$bet_type \
                                  --bet_name=$bet_name \
                                  --saldo=10000 \
                                  --start_date=$d \
                                  --stop_date=$d \
                                  --size=30 \
                                  --animal=$animal \
                                  --summary --plot &
                            done
                        done
                    done
                done
            ;;
        
            weekly)
                for bet_name in $names ; do
                    for bet_type in $bet_types ; do
                        for animal in $animals ; do
                            python simulator3.py \
                              --bet_type=$bet_type \
                              --bet_name=$bet_name \
                              --saldo=10000 \
                              --start_date=$start_date \
                              --stop_date=$stop_date \
                              --size=30 \
                              --animal=$animal \
                              --summary --plot &
                        done
                    done
                done
            ;;
          *)
           echo "fel 2"
          ;;
        esac     
    ;;
 
    *)
       echo "$0 [football|animals]"
     ;;
     
esac
