
TZ='Europe/Stockholm'
export TZ

export HOSTNAME=$(hostname)

OS=$(uname)

case "${OS}" in
    Linux)
      bits=$(uname -m)
      case ${bits} in
        i686)    export OS_ARCHITECTURE=lnx_x64 ;;
        x86_64)  export OS_ARCHITECTURE=lnx_x86 ;;
        *)       echo "not supported bits ${bits}" ; exit 1 ;;
      esac
    ;;

    Darwin)
      export OS_ARCHITECTURE=drw_x64
    ;;

    *)
     echo "not supported OS ${OS}" ; exit 1
    ;;
esac    

export ADA_ROOT=/usr/local/ada/2017
export ADA_PROJECT_PATH=$ADA_ROOT/aws/lib/gnat:$ADA_PROJECT_PATH
export PATH=$ADA_ROOT/gprbuild/bin:$ADA_ROOT/gnat/bin:$PATH
export BOT_XML_SOURCE=GNAT

export BOT_START=$HOME/svn/botstart
. $BOT_START/bot.bash bnl

USERS=$(ls $BOT_HOME/../)
S=""
for U in $USERS ; do
  S="$S . $BOT_START/bot.bash $U; stop_all_bots ;"
done
S="$S . $BOT_START/bot.bash bnl"
alias stop_bot_system=$S


