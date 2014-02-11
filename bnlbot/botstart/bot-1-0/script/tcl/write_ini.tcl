


#i=min horses
#j=min_num_runners_better_ranked
#k=race_favorite_max_price


proc do_echo {low high i j k} { 
  puts "\[HORSES_WIN_${low}_${high}_LAY_GB_${i}_${j}_${k}\]"
  puts "enabled=true"
  puts "bet_size=30.0"
  puts "max_daily_profit=100000.0"
  puts "max_daily_loss=-5000.0"
  puts "countries=GB"
  puts "max_price=$high"
  puts "min_price=$low"
  puts "mode=sim"
  puts "no_of_winners=1"
  puts "min_num_runners=$i"
  puts "max_num_runners=25"
  puts "allowed_days=al"
  puts "green_up_mode=None"
  puts "max_num_in_the_air=15"
  puts "max_exposure=1200.0"
  puts "min_num_runners_better_ranked=$j"
  puts "race_favorite_max_price=$k"
  puts ""
}


foreach l [list 30 35 40 45 50  ] {
  foreach h [list 50 60 70 ] {
    if {[expr $l < $h ]} {
      foreach i [list 6 7 ] {
        foreach j [list 1 ] {
          foreach k [list 4.0 5.0 6.0] {
            do_echo $l $h $i $j $k
          }
        }
      }
    }
  }
}




#proc do_echo2 {low high i j k} { 
#  puts "\[HORSES_WIN_${low}_${high}_LAY_GB_${i}_${j}_${k}\]"
#  puts "enabled=true"
#  puts "bet_size=30.0"
#  puts "max_daily_profit=100000.0"
#  puts "max_daily_loss=-5000.0"
#  puts "countries=GB"
#  puts "max_price=$high"
#  puts "min_price=$low"
#  puts "mode=sim"
#  puts "no_of_winners=1"
#  puts "min_num_runners=$i"
#  puts "max_num_runners=25"
#  puts "allowed_days=al"
#  puts "green_up_mode=None"
#  puts "max_num_in_the_air=15"
#  puts "max_exposure=1200.0"
#  puts "min_num_runners_better_ranked=$j"
#  puts "race_favorite_max_price=$k"
#  puts ""
#}
#
#
#
#
#
#do_echo2  8 10 7 2 3.5
#do_echo2  9 11 7 2 3.5
#do_echo2 10 12 7 2 3.5
#do_echo2 11 13 7 2 3.5
#do_echo2 12 14 7 2 3.5
#do_echo2  8 11 7 2 3.5
#do_echo2  9 12 7 2 3.5
#do_echo2 10 13 7 2 3.5
#do_echo2 11 14 7 2 3.5
#do_echo2  8 12 7 2 3.5
#do_echo2  9 13 7 2 3.5
#do_echo2 10 14 7 2 3.5
#do_echo2  8 13 7 2 3.5
#do_echo2  9 14 7 2 3.5
























