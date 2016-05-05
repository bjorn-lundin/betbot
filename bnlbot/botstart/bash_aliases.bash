

#bnl start

alias mc='. /usr/lib/mc/mc-wrapper.sh'
alias mcedit='mcedit -c'

alias stop_bet_checker='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit'
alias stop_bot='$BOT_TARGET/bin/bot_send --receiver=bot --message=exit'
alias stop_markets_fetcher='$BOT_TARGET/bin/bot_send --receiver=markets_fetcher --message=exit'
alias stop_poll='$BOT_TARGET/bin/bot_send --receiver=poll --message=exit'

alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_010 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_031 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_032 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_033 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_034 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_110 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_111 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_112 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_123 --message=exit' 
alias stop_bet_placer_010='$BOT_TARGET/bin/bot_send --receiver=bet_placer_126 --message=exit' 

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


alias stop_all_bots='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bot --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=w_fetch_json --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_010 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_031 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_032 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_033 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_034 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_110 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_111 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_112 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_123 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_126 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_1 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_2 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_3 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_4 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_5 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_6 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_7 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_market_8 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=markets_fetcher --message=exit'
                     

                     

alias crp='$BOT_SCRIPT/bash/crp.bash'

alias chguser='. $BOT_START/bot.bash $1'

alias awspsql='psql --host=db.nonodev.com --dbname=bnl'



alias stop_all_collectors='$BOT_TARGET/bin/bot_send --receiver=poll_market_1 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_2 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_3 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_4 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_5 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_6 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_7 --message=exit && \
                           $BOT_TARGET/bin/bot_send --receiver=poll_market_8 --message=exit'

