 # basic environment for BETBOT on Linux
 # 2013-04-11 BNL original version
 #

 ######### These NEEDS to be set by YOU start ###############
 export BETBOT_ROOT=$HOME/bnlbot
 export BETBOT_DATABASE_USER=bnl
 export BETBOT_DATABASE_PASSWORD=bnl
 export BETBOT_DATABASE=betting
 ######### These NEEDS to be set by YOU stop ###############


 #if you have other compilers and tclsh
# export GNATHOME=/opt/gnat/gpl_2010
# export TCLHOME=/opt/tcl/8.4.19
# export GNUHOME=/opt/gnu

 #BETBOT stuff
 export BETBOTCLUSTERID=$(hostname)
 export BETBOT_TARGET=$BETBOT_ROOT/target
 export BETBOT_SOURCE=$BETBOT_ROOT/source
 export BETBOT_CONFIG=$BETBOT_ROOT/config
 export BETBOT_SCRIPT=$BETBOT_ROOT/script
 export OS_ARCHITECTURE=lnx_x86

 #useful aliases

 export MC_ROOT=/usr
 alias mc='LANG=C . $MC_ROOT/share/mc/bin/mc-wrapper.sh -c'
 alias mcedit='LANG=C $MC_ROOT/bin/mcedit -c'
 alias to='. $BETBOT_SCRIPT/global/to.ksh'
 alias make_extract_package='tclsh $BETBOT_SCRIPT/local/make_extract_package.tcl'

 #Repository Stuff
 alias make_table_package='tclsh $BETBOT_SCRIPT/local/make_table_package.tcl'
 alias make_view='tclsh $BETBOT_SCRIPT/local/make_view.tcl'

