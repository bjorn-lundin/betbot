

#bnl start

case ${OS_ARCHITECTURE} in
  lnx*) alias mc='. /usr/lib/mc/mc-wrapper.sh'
  ;;
  drw*) alias mc='. /opt/local/libexec/mc/mc-wrapper.sh'
  ;;
  *) echo "no mc found for ${OS_ARCHITECTURE}" >&2
  ;;
esac


alias mcedit='mcedit -c'

alias stop_bet_checker='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit'
alias stop_markets_fetcher='$BOT_TARGET/bin/bot_send --receiver=markets_fetcher --message=exit'
alias stop_bot_ws='$BOT_TARGET/bin/bot_send --receiver=bot_ws --message=exit'

alias stop_poll='$BOT_TARGET/bin/bot_send --receiver=poll_01 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_02 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_03 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_04 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_05 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_06 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_07 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_08 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_09 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_10 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_11 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_12 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_13 --message=exit && \
                 $BOT_TARGET/bin/bot_send --receiver=poll_14 --message=exit'

#alias stop_all_dogs='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=gh_mark_fetcher --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=gh_poll_1 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=gh_poll_2 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=gh_poll_3 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=play_market_1 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=play_market_2 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=play_market_3 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=poll_market_1 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=poll_market_2 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=poll_market_3 --message=exit && \
#                     $BOT_TARGET/bin/bot_send --receiver=w_fetch_json --message=exit'

#alias stop_live_feed='$BOT_TARGET/bin/bot_send --receiver=live_feed --message=exit'

alias stop_bet_placer_001='$BOT_TARGET/bin/bot_send --receiver=bet_placer_001 --message=exit'
alias stop_bet_placer_002='$BOT_TARGET/bin/bot_send --receiver=bet_placer_002 --message=exit'
alias stop_bet_placer_003='$BOT_TARGET/bin/bot_send --receiver=bet_placer_003 --message=exit'
alias stop_bet_placer_004='$BOT_TARGET/bin/bot_send --receiver=bet_placer_004 --message=exit'
alias stop_bet_placer_005='$BOT_TARGET/bin/bot_send --receiver=bet_placer_005 --message=exit'
alias stop_bet_placer_006='$BOT_TARGET/bin/bot_send --receiver=bet_placer_006 --message=exit'
alias stop_bet_placer_007='$BOT_TARGET/bin/bot_send --receiver=bet_placer_007 --message=exit'
alias stop_bet_placer_008='$BOT_TARGET/bin/bot_send --receiver=bet_placer_008 --message=exit'
alias stop_bet_placer_009='$BOT_TARGET/bin/bot_send --receiver=bet_placer_009 --message=exit'
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_010 --message=exit'

alias stop_w_fetch_json='$BOT_TARGET/bin/bot_send --receiver=w_fetch_json --message=exit'
                     
alias stop_all_dogs='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=gh_mark_fetcher --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=gh_poll_1 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=gh_poll_2 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=gh_poll_3 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=play_market_1 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=play_market_2 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=play_market_3 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_1 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_2 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_3 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=w_fetch_json --message=exit'                    

alias crp='$BOT_SCRIPT/bash/crp.bash'

alias chguser='. $BOT_START/bot.bash $1'

alias awspsql='psql --host=lundin.duckdns.org --dbname=bnl'


alias stop_all_collectors='$BOT_TARGET/bin/bot_send --receiver=poll_market_1 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_2 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_3 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_4 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_5 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_6 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_7 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_8 --message=exit'


                           
                           
#function stop_bots  {
#  while read line
#  do
#    if [ ! -z $line ] ; then 
#      echo "$line"
#    fi
#  done 
#}  < crp | awk '{print $9}'

                     
                           
