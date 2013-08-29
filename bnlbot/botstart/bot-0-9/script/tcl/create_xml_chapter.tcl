
#set Bet_Name_List [list horses_win_lay5_ie horses_win_lay5_ie_go horses_win_lay5_gb]
set Bet_Name_List [list [lindex $argv 0]]
set Powerday_List [list 107 207 307 114 214 314 121 221 321 128 228 328 135 235 335]


foreach Bet_Name $Bet_Name_List {
  puts "<?xml version=\'1.0\' encoding=\'iso8859-1\'?>"
  puts "<chapter xml:id=\'$Bet_Name\' xmlns=\'http://docbook.org/ns/docbook\' version=\'5.0\' >"
  puts "<title>$Bet_Name</title>"

  foreach Powerday $Powerday_List {
    puts "<mediaobject>"
    puts "    <imageobject>"
    puts "      <imagedata fileref=\'../script/plot/$Powerday/$Bet_Name.png\'"
    puts "                 align=\'center\'"
    puts "                 width=\'100%\'"
    puts "                 scalfit=\'1\'/>"
    puts "    </imageobject>"
    puts "</mediaobject>    "
  }
  puts "</chapter>"
}



    
