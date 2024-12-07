

set s [socket localhost 27124]
fconfigure $s -buffering none 
puts $s "avail=2342.0,expos=3245.94"
close $s 
