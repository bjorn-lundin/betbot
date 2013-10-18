

#From TclGetOpt, to parse command line options
package provide Get_Opt 1.0

set optind 0
set optindc 0

proc getopt { argslist optstring optret argret } {
  global optind optindc
  upvar $optret retvar
  upvar $argret optarg

# default settings for a normal return
  set optarg ""
  set retvar ""
  set retval 0

# check if we're past the end of the args list
  if { $optind < [ llength $argslist ] } then {

# if we got -- or an option that doesn't begin with -, return (skipping
# the --).  otherwise process the option arg.
    switch -glob -- [ set arg [ lindex $argslist $optind ]] {
      "--" {
             incr optind
           }

      "-*" {
             if { $optindc < 1 } then {
               set optindc 1
             }

             set opt [ string index $arg $optindc ]

             if { [ incr optindc ] == [ string length $arg ] } then {
               set arg [ lindex $argslist [ incr optind ]]
               set optindc 0
             }

             if { [ string match "*$opt*" $optstring ] } then {
               set retvar $opt
               set retval 1
               if { [ string match "*$opt:*" $optstring ] } then {
                 if { $optind < [ llength $argslist ] } then {
                   set optarg [ string range $arg $optindc end ]
                   incr optind
                   set optindc 0
                 } else {
                   set optarg "Option requires an argument -- $opt"
                   set retvar $optarg
                   set retval -1
                 }
               }
             } else {
               set optarg "Illegal option -- $opt"
               set retvar $optarg
               set retval -1
             }
           }
    }
  }
  return $retval
}

