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
  echo "plotting $input"
  gnuplot $output map.gpl
done


#graph_type='biweekly'
#animal='horse'
#bet_name='back'
#bet_type='Plats'
#variant='normal_lay_bet'
#index='None'
#start_date='2013-01-30'
#stop_date='2013-02-13'
#datafil='simulation3-horse-Plats-back-2013-01-30-2013-02-13-None.dat'
#datadir='sims'

TARGET_ROOT=~/Dropbox/graphs

for input in $filelist ; do
    while read line ; do
#      echo $line
      key=$(echo $line | cut -f1 -d=)
      value=$(echo $line | cut -f2 -d\')

      if [ $key == "graph_type" ] ; then
         graph_type=$value
      elif [ $key == "animal" ] ; then
         animal=$value
      elif [ $key == "bet_name" ] ; then
         bet_name=$value
      elif [ $key == "bet_type" ] ; then
         bet_type=$value
      elif [ $key == "variant" ] ; then
         variant=$value
      elif [ $key == "datafil" ] ; then
         datafil=$value
      elif [ $key == "datadir" ] ; then
         datadir=$value
      fi

    done < $input
    #remove .gpi
    base=$(basename $input)


    dat=${base%.*}
    gpi=$dat.gpi
    png=$dat.png

#    echo "------------"
#    echo "input $input"
#    echo "dat   $dat"
#    echo "gpi   $gpi"
#    echo "png   $png"

    DESTINATION=$animal/$bet_type/$graph_type/$bet_name/$variant
    DESTINATION_DAT=dat

#    echo "dest $DESTINATION"
#    echo "dest $DESTINATION_DAT"

    [ ! -d $TARGET_ROOT/$DESTINATION ] && mkdir -p $TARGET_ROOT/$DESTINATION
    [ ! -d $TARGET_ROOT/$DESTINATION/$DESTINATION_DAT ] && mkdir -p $TARGET_ROOT/$DESTINATION_DAT

#    echo "mv $datadir/$dat $TARGET_ROOT/$DESTINATION_DAT/"
#    echo "mv $datadir/$gpi $TARGET_ROOT/$DESTINATION_DAT/"
#    echo "mv $datadir/$png $TARGET_ROOT/$DESTINATION/"


    [ -f $datadir/$dat ] && mv $datadir/$dat $TARGET_ROOT/$DESTINATION_DAT/ && echo "moved $datadir/$dat"
    [ -f $datadir/$gpi ] && mv $datadir/$gpi $TARGET_ROOT/$DESTINATION_DAT/ && echo "moved $datadir/$gpi"
    [ -f $datadir/$png ] && mv $datadir/$png $TARGET_ROOT/$DESTINATION/     && echo "moved $datadir/$png"

done



