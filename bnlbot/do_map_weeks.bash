#!/bin/bash

TARGET_ROOT=~/Dropbox/graphs
DESTINATION_DAT=dat
LIST_OF_FILES=~/bnlbot/tmp/file_list.dat
pattern1="hound horse"
pattern2="lay back"


#    gnuplot -e "animal='$animal'" \
#            -e "bet_name='$bet_name'" \
#            -e "bet_type='$bet_type'" \
#            -e "index='" + str(simrun.index) + "\'\" \
#            -e "start_date='$the_date'" \
#            -e "stop_date='$the_date'" \
#            -e "datafil='$filname'" \
#            -e "datadir='$datadir'" plot_simulation.gpl

rm -f $LIST_OF_FILES
for p1 in $pattern1 ; do
    for p2 in $pattern2 ; do
        ls sims/*$p1*$p2*.gpi >> $LIST_OF_FILES
    done
done

while read FILENAME ; do

    echo "plotting $FILENAME"
    filelist=$FILENAME
    for input in $filelist ; do
       output=""
       while read line ; do
          output="$output -e $line "
       done < $input
       echo "plotting $input"
       gnuplot $output map_weeks.gpl
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
            elif [ $key == "max_daily_loss" ] ; then
               max_daily_loss=$value
            fi
        done < $input

        base=$(basename $input)

        dat=${base%.*}
        gpi=$dat.gpi
        png=$dat.png

        #    echo "------------"
        #    echo "input $input"
        #    echo "dat   $dat"
        #    echo "gpi   $gpi"
        #    echo "png   $png"

#        DESTINATION=$animal/$bet_name/$bet_type/$graph_type/$variant/$max_daily_loss
#        [ ! -d $TARGET_ROOT/$DESTINATION ] && mkdir -p $TARGET_ROOT/$DESTINATION
#        [ -f $datadir/$png ] && mv $datadir/$png $TARGET_ROOT/$DESTINATION/ && echo "moved $datadir/$png"
    done

done < $LIST_OF_FILES

#yesterday=$(date +%Y-%m-%d -d "-1 day")
#tar_gz_file=dat-$yesterday.tar.gz
#echo "compressing files to $tar_gz_file"
#rm -f $tar_gz_file
#tar cfz $tar_gz_file sims/
#[ ! -d $TARGET_ROOT/$DESTINATION_DAT ] && mkdir -p $TARGET_ROOT/$DESTINATION_DAT
#[ -f $tar_gz_file ] && mv $tar_gz_file $TARGET_ROOT/$DESTINATION_DAT/ && echo "moved $tar_gz_file to $TARGET_ROOT/$DESTINATION_DAT"


