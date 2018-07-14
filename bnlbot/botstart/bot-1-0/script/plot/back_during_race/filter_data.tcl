#!/usr/bin/tclsh



catch { exec [file join $::env(BOT_TARGET) bin price_to_tics] --tictable } tictable
#puts $tictable
set dict1 [string map {| { }} $tictable]
#puts $dict1

#foreach id [dict keys $dict1] {
#    puts [dict get $dict1 $id]
#}

#exit


proc get_tic {price} {
  foreach id [dict keys $::dict1] {
      set dp [dict get $::dict1 $id]
      if {$dp == $price} {
        return $id
      }
  }
  return false
}

set old_leader_price 0

while { [gets stdin line] >= 0 } {
  if { [string length $line] == 0 } {
    set OK 0
  } else {
    set OK 1
  }

  if {$OK} {

    #PLC_BACK_1.17_03.00 | 34532
    set fields1 [split $line '|']

    set f1 [lindex $fields1 0]
    set fsum [lindex $fields1 1]   

    #if {$fsum < 0 } {
    #  set fsum 0.0
    #}


    #f1=PLC_BACK_1.17_03.00 
    #fsum=34532.00

    set fields2 [split $f1 '_']
    
    set leader_price  [lindex $fields2 2]
    set delta_price    [lindex $fields2 3]


    if { $leader_price != $old_leader_price } {
      puts ""
    }
    set old_leader_price $leader_price
#    if { $delta_price == "3" } {
#      if { $leader_price < "1.14" } {       
#         puts "$leader_price|01.00 | 0.0"
#         puts "$leader_price|02.00 | 0.0"
#      }
#    }

    puts "$leader_price|$delta_price|$fsum"

  }
}




