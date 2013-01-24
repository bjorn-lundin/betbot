#!/bin/bash




INPUT_FILE=$1

bet_type_list="dry_run_less_than_3.5_goals \
 away_full_one_goal_lead_time \
 horses_winner_lay_bet \
 home_full_one_goal_lead_time \
 dry_run_more_than_0.5_goals \
 dry_run_hounds_winner_lay_bet \
 horses_place_back_bet \
 hounds_place_back_bet \
 dry_run_hounds_place_back_bet \
 dry_run_hounds_place_lay_bet \
 dry_run_horses_winner_lay_bet \
 dry_run_hounds_winner_favorite_lay_bet \
 hounds_place_lay_bet \
 dry_run_horses_winner_favorite_lay_bet \
 sendoff_no \
 dry_run_horses_place_back_bet \
 dry_run_horses_place_lay_bet \
 dry_run_sendoff_no \
 dry_run_tie_no_bet \
 dry_run_score_sum_is_even \
 dry_run_less_than_4.5_goals"


date_list="13 14 15 16 17 18 19 20 21 22 23"

for TYP in $bet_type_list ; do 
#  for d in $date_list ; do 
      typ=$(echo $TYP | tr '[A-Z]' '[a-z]')
      echo "grep -i $TYP $INPUT_FILE "
      grep -i $TYP $INPUT_FILE > target/$typ.dat
#  done
done