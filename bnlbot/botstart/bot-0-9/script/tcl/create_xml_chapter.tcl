

package require Pgtcl

set db "bnl"
set host "localhost"
set port 5432
#set user "bnl"
set Bet_Name_List [list [lindex $argv 0]]
#set Powerday_List [list 107 207 307 114 214 314 121 221 321 128 228 328 135 235 335]
set Powerday_List [list 107 207 307 114 214 314 121 221 321 128 228 328]

global Weekday_Profit_Array(null)
global Weekday_Count_Array(null)
global Weekday_Count_Pct_Array(null)

set ::conn [pg_connect $db -host $host -port $port]

foreach Bet_Name $Bet_Name_List {
  puts "<?xml version=\'1.0\' encoding=\'iso8859-1\'?>"
  puts "<chapter xml:id=\'$Bet_Name\' xmlns=\'http://docbook.org/ns/docbook\' version=\'5.0\' >"
  puts "<title>$Bet_Name</title>"

  foreach Powerday $Powerday_List {
    puts "<section xml:id=\'$Bet_Name\_$Powerday\'>"
    puts "<title>$Powerday</title>"
    puts "<mediaobject>"
    puts "  <imageobject>"
    puts "    <imagedata fileref=\'../script/plot/$Bet_Name\-$Powerday.png\'"
    puts "               align=\'left\'"
    puts "               width=\'80%\'"
    puts "               scalfit=\'1\'/>"
    puts "  </imageobject>"
    puts "</mediaobject>"

    set query " select \
        count('a'), \
        round(avg(b.profit)::numeric, 1) as avgprofit, \
        round(sum(b.profit)::numeric, 0) as sumprofit, \
        round(avg(b.price)::numeric, 1) as avgprice, \
        round((sum(b.profit)/avg(b.price))::numeric, 0) as sumprofit_price, \
        min(b.startts)::date as mindate, \
        max(b.startts)::date as maxdate, \
        max(b.startts)::date - min(b.startts)::date  + 1 as days, \
        round(count('a')/(max(b.startts)::date - min(b.startts)::date  + 1)::numeric,1) as betsperday, \
        round((sum(profit)/(max(b.startts)::date - min(b.startts)::date  + 1))::numeric, 0) as profitperday, \
        b.betmode, \
        e.countrycode, \
        b.powerdays, \
        b.betname, \
        case \
          when b.betname like '%LAY%' then round((sum(b.profit)/(avg(b.size)* (avg(b.price) -1)))::numeric, 0) \
          else round((sum(b.profit)/avg(b.size))::numeric, 0) \
        end as riskratio ,  \
        avg(b.size) as avg_size \
      from \
        abets b, amarkets m, aevents e \
      where \
        b.startts::date > (select current_date - interval '420 days') \
        and b.status = 'EXECUTION_COMPLETE' \
        and b.betwon is not null \
        and b.betname = '[string toupper $Bet_Name]' \
        and ( (b.betmode in (1,3,4) and b.powerdays = $Powerday) or (b.powerdays = 0)) \
        and b.marketid = m.marketid \
        and m.eventid = e.eventid \
      group by \
        e.countrycode, \
        b.betname, \
        b.powerdays, \
        b.betmode \
      having sum(b.profit) > -100000000.0 \
      order by \
        b.betmode "
    set res [pg_exec $::conn $query]

    set ntups [pg_result $res -numTuples]
    set Tuples {}
    for {set i 0} {$i < $ntups} {incr i} {
        lappend Tuples [pg_result $res -getTuple $i]
    }
    if { $ntups == 0 } {
       set Tuples [ list "0 0 0 0 0 - - 0 0 0 0"]
    }

    pg_result $res -clear

    puts "<table><title>Interesting facts about $Bet_Name with powerday : $Powerday</title>"
    puts "<tgroup cols=\"12\">"
    puts "<thead><row><entry>Mode</entry><entry>Profit/ Risk</entry><entry>Count</entry><entry>avg(Profit)</entry><entry>sum(Profit)</entry><entry>avg(Price)</entry>"
    puts "<entry>sum(Profit)/ avg(Price)</entry><entry>min(Date)</entry><entry>max(Date)</entry><entry>num(Days)</entry>"
    puts "<entry>Bets/Day</entry><entry>Profit/Day</entry></row></thead><tbody>"

    foreach Tuple $Tuples {
      set Mode [lindex $Tuple 10]
      set Smode {}
      switch $Mode {
         1 {set Smode "dry"}
         3 {set Smode "sim"}
         4 {set Smode "ref"}
        default {set Smode "unknown $Mode"}
      }
      puts "<row><entry>$Smode</entry><entry>[lindex $Tuple 14]</entry><entry>[lindex $Tuple 0]</entry> <entry>[lindex $Tuple 1]</entry>"
      puts "<entry>[lindex $Tuple 2]</entry><entry>[lindex $Tuple 3]</entry> <entry>[lindex $Tuple 4]</entry>"
      puts "<entry>[lindex $Tuple 5]</entry><entry>[lindex $Tuple 6]</entry> <entry>[lindex $Tuple 7]</entry>"
      puts "<entry>[lindex $Tuple 8]</entry><entry>[lindex $Tuple 9]</entry></row>"
    }
    puts "</tbody></tgroup></table>"

    # how is the income spread across weekdays?
    set query " select \
        round(sum(b.profit)::numeric, 0) as sumprofit, \
        b.powerdays, \
        b.betmode, \
        b.betname, \
        extract(dow from b.startts ) as weekday, \
        count(b.profit) as count \
      from \
        abets b, amarkets m, aevents e \
      where \
        b.startts::date > (select current_date - interval '420 days') \
        and b.status = 'EXECUTION_COMPLETE' \
        and b.betwon is not null \
        and b.betname = '[string toupper $Bet_Name]' \
        and b.marketid = m.marketid \
        and m.eventid = e.eventid \
        and ( (b.betmode in (1,3,4) and b.powerdays = $Powerday) or (b.powerdays = 0)) \
      group by \
        b.betname, \
        b.powerdays, \
        b.betmode, \
        weekday \
      having sum(b.profit) > -100000000.0 \
      order by \
        b.betmode, \
        weekday "
    set res [pg_exec $::conn $query]

    set ntups [pg_result $res -numTuples]
    set Tuples {}
    for {set i 0} {$i < $ntups} {incr i} {
        lappend Tuples [pg_result $res -getTuple $i]
    }
    if { $ntups == 0 } {
       set Tuples [ list "0 0 0 0 0"]
    }

    pg_result $res -clear

    puts "<table><title>Profit / num bets / % num bets distributed per weekday </title>"
    puts "<tgroup cols=\"8\">"
    puts "<thead><row><entry>mode</entry><entry>mon</entry><entry>tue</entry><entry>wed</entry><entry>thu</entry><entry>fri</entry><entry>sat</entry>"
    puts "<entry>sun</entry></row></thead>"
    puts "<tbody>"


    set Betmodes [list 1 3 4]
    set Days [list 1 2 3 4 5 6 0 ]

    foreach Betmode $Betmodes {
      foreach Weekday $Days {
        if {![info exists Weekday_Profit_Array($Betmode,$Weekday) ]} {
          set Weekday_Profit_Array($Betmode,$Weekday) 0
        }
        if {![info exists Weekday_Count_Array($Betmode,$Weekday) ]} {
          set Weekday_Count_Array($Betmode,$Weekday) 0
        }
        if {![info exists Weekday_Count_Pct_Array($Betmode,$Weekday) ]} {
          set Weekday_Count_Pct_Array($Betmode,$Weekday) 0
        }
      }
    }


    foreach Tuple $Tuples {
      set Betmode [lindex $Tuple 2]
      set Weekday [lindex $Tuple 4]
      set Weekday_Profit_Array($Betmode,$Weekday) [lindex $Tuple 0]
      set Weekday_Count_Array($Betmode,$Weekday) [lindex $Tuple 5]
    }


    foreach Betmode $Betmodes {
      set Tot_Num_Bets 0
      foreach Weekday $Days {
        set Tot_Num_Bets [expr $Tot_Num_Bets + $Weekday_Count_Array($Betmode,$Weekday)]
      }
      set Tot_Num_Bets  [expr $Tot_Num_Bets + 0.0] ; # make it a float

      foreach Weekday $Days {
        if {$Tot_Num_Bets > 0 } {
          set Weekday_Count_Pct_Array($Betmode,$Weekday) "[format "%.0f" [expr 100 * $Weekday_Count_Array($Betmode,$Weekday) / $Tot_Num_Bets ]]%"
        }
      }
    }


    foreach Betmode $Betmodes {
      set Mode $Betmode
      set Smode {}
      switch $Mode {
         1 {set Smode "dry"}
         3 {set Smode "sim"}
         4 {set Smode "ref"}
        default {set Smode "unknown $Mode"}
      }
      puts "<row><entry>$Smode</entry>"
      foreach Weekday $Days {
        puts "<entry>$Weekday_Profit_Array($Betmode,$Weekday)/$Weekday_Count_Array($Betmode,$Weekday)/$Weekday_Count_Pct_Array($Betmode,$Weekday)</entry>"
      }
      puts "</row>"
    }
    puts "</tbody></tgroup></table>"

    puts "</section>"
    puts "<?hard-pagebreak?>"
  }
  puts "</chapter>"
  pg_disconnect $::conn
}



