#!/bin/bash



#    gnuplot -e "animal='$animal'" \
#            -e "bet_name='$bet_name'" \
#            -e "bet_type='$bet_type'" \
#            -e "index='" + str(simrun.index) + "\'\" \
#            -e "start_date='$the_date'" \
#            -e "stop_date='$the_date'" \
#            -e "datafil='$filname'" \
#            -e "datadir='$datadir'" plot_simulation.gpl





while getopts "i:t:" opt; do
  case $opt in
    i)
      input=$OPTARG
      ;;

*)
      echo "$0 -w [football|animals] -t [daily|weekly|monthly]" >&2
      exit 1
      ;;
  esac
done


filelist=$(ls sims/*.gpi)


for input in $filelist ; do
  output=""

  while read line ; do
    output="$output -e $line "
  done < $input


  gnuplot $output map.gpl
done

