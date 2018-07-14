set i 0
set j_list  "1.05 1.06 1.07 1.08 1.09 1.10 1.11 1.12 1.13 1.14 1.15 1.16 1.17 1.18 1.19 1.20 1.21 1.22 1.23 1.24 1.25 "

while  {1==1} {
  incr i
  if {$i == 10 } {
    break
  }
  
  foreach j $j_list {
    if {$i < 10 } {
      set ii "0$i.00"
    } else {
      set ii "$i.00"
    }

    puts "update abets set betname = \'WIN_BACK_$j\_$ii\' where betname = \'WIN_BACK_$j\_$i.00\';"
    puts "update abets set betname = \'PLC_BACK_$j\_$ii\' where betname = \'PLC_BACK_$j\_$i.00\';"
    puts "commit;"
  }
}
puts {\q}

