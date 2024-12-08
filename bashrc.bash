



export HOSTNAME=$(hostname)

OS=$(uname)

bits=none

case "${OS}" in
    Linux)
      bits=$(uname -m)
      case ${bits} in
        i686)    export OS_ARCHITECTURE=lnx_x86 ;;
        x86_64)  export OS_ARCHITECTURE=lnx_x64 ;;
        armv7l)  export OS_ARCHITECTURE=lnx_a32 ;;
        aarch64) export OS_ARCHITECTURE=lnx_a64 ;;
        *)       echo "not supported bits ${bits}" ; exit 0 ;;
      esac
    ;;

    Darwin)
      export OS_ARCHITECTURE=drw_x64
    ;;

    *)
     echo "not supported OS ${OS}" ; exit 1
    ;;
esac

if [ $bits == "armv7l" ] ; then
  export ADA_ROOT=/usr/local/ada
  export ADA_PROJECT_PATH=$ADA_ROOT/aws/fsf-aws2018-gpl/share/gpr:/usr/local/ada/xmlada/21.0.0/share/gpr
else
# set in /etc/environment  export BOT_ROOT=/usr2/betbot
# set in /etc/environment  export BOT_TOOLS=/usr2/tools
  export ADA_PROJECT_PATH=$BOT_TOOLS/aws-2024-12-06/25.0/share/gpr
  export PATH=$BOT_TOOLS/gnat/25.0/bin:$PATH
fi

. $BOT_ROOT/bot.bash bnl

. $BOT_ROOT/bash_aliases.bash

