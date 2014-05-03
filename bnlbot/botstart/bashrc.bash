# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


# . betbot_env/bin/activate


#export BOT_START=/home/bnl/bnlbot/botstart

#. $BOT_START/project_settings.bash
#alias menu='. $BOT_START/project_settings.bash'

#cd $BOT_START/user/$BOT_USER

TZ='Europe/Stockholm'
export TZ

export MC_ROOT=/usr
#alias mc='LANG=C . $MC_ROOT/share/mc/bin/mc-wrapper.sh -c'
#alias mcedit='LANG=C $MC_ROOT/bin/mcedit -c'


alias mc='$MC_ROOT/share/mc/bin/mc-wrapper.sh'
alias mcedit='$MC_ROOT/bin/mcedit -c'

export HOSTNAME=$(hostname)

export OS_ARCHITECTURE=lnx_x86 
#export ADA_PROJECT_PATH=/usr/local/ada/aws/2.11.0/lib/gnat
#export ADA_PROJECT_PATH=/usr/local/ada/aws/3.1.0/lib/gnat
export ADA_PROJECT_PATH=/usr/local/ada/aws/3.1.0w/lib/gnat
#LOCAL or GNAT
export BOT_XML_SOURCE=LOCAL 

export BOT_MODE=PROD

#cant be as long as python bots are running
export BOT_START=$HOME/bnlbot/botstart 
. $BOT_START/bot.bash bnl 

alias make_table_package='tclsh $BOT_SCRIPT/tcl/make_table_package.tcl' 
alias make_view='tclsh $BOT_SCRIPT/tcl/make_view.tcl' 

alias stop_bet_checker='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit' 
alias stop_saldo_fetcher='$BOT_TARGET/bin/bot_send --receiver=saldo_fetcher --message=exit'
alias stop_bot='$BOT_TARGET/bin/bot_send --receiver=bot --message=exit' 
alias stop_market_fetcher='$BOT_TARGET/bin/bot_send --receiver=markets_fetcher --message=exit' 
alias stop_poll='$BOT_TARGET/bin/bot_send --receiver=poll --message=exit' 
alias stop_poll_and_log='$BOT_TARGET/bin/bot_send --receiver=poll_and_log --message=exit' 
alias stop_bet_placer_1='$BOT_TARGET/bin/bot_send --receiver=bet_placer_1 --message=exit' 
alias stop_bet_placer_2='$BOT_TARGET/bin/bot_send --receiver=bet_placer_2 --message=exit' 
alias stop_bet_placer_3='$BOT_TARGET/bin/bot_send --receiver=bet_placer_3 --message=exit' 
alias stop_bet_placer_4='$BOT_TARGET/bin/bot_send --receiver=bet_placer_4 --message=exit' 
alias stop_bet_placer_5='$BOT_TARGET/bin/bot_send --receiver=bet_placer_5 --message=exit' 
alias stop_bet_placer_6='$BOT_TARGET/bin/bot_send --receiver=bet_placer_6 --message=exit' 
alias stop_bet_placer_7='$BOT_TARGET/bin/bot_send --receiver=bet_placer_7 --message=exit' 
alias stop_bet_placer_8='$BOT_TARGET/bin/bot_send --receiver=bet_placer_8 --message=exit' 
alias stop_bet_placer_9='$BOT_TARGET/bin/bot_send --receiver=bet_placer_9 --message=exit' 
alias stop_bet_placer_10='$BOT_TARGET/bin/bot_send --receiver=bet_placer_10 --message=exit' 
alias stop_bet_placer_20='$BOT_TARGET/bin/bot_send --receiver=bet_placer_20 --message=exit' 
alias stop_bet_placer_21='$BOT_TARGET/bin/bot_send --receiver=bet_placer_21 --message=exit' 
alias stop_bet_placer_30='$BOT_TARGET/bin/bot_send --receiver=bet_placer_30 --message=exit' 
alias stop_football_better='$BOT_TARGET/bin/bot_send --receiver=football_better --message=exit' 

alias stop_w_fetch_json='$BOT_TARGET/bin/bot_send --receiver=w_fetch_json --message=exit'

alias stop_all_bet_placers='$BOT_TARGET/bin/bot_send --receiver=bet_placer_1 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_2 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_3 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_4 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_5 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_6 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_7 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_8 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_9 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_10 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_20 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_21 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_30 --message=exit'


alias stop_all_bots='$BOT_TARGET/bin/bot_send --receiver=bet_checker --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bot --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=poll_and_log --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=football_better --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=w_fetch_json --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_1 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_2 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_3 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_4 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_5 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_6 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_7 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_8 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_9 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_10 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_20 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_21 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=bet_placer_30 --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=saldo_fetcher --message=exit && \
                     $BOT_TARGET/bin/bot_send --receiver=markets_fetcher --message=exit'

#USERS=$(ls $BOT_HOME/../)
USERS="bnl jmb"
S=""
for U in $USERS ; do
  S="$S . $BOT_START/bot.bash $U; stop_all_bots ;"
done

alias stop_bot_system=$S
                     
#function crp {           
#  echo " PID  STIME TIME      CMD"
#  for U in $USERS ; do
#    echo "---- $U --------------------------------------------------------"
#    ps -eo pid,stime,time,cmd | grep bot | grep user=$U | grep -v grep
#  done
#  echo "----------------------------------------------------------------"
#  date
#}

alias crp='$BOT_SCRIPT/bash/crp.bash'

alias chguser='. $BOT_START/bot.bash $1'

alias awspsql='psql --host=db.nonodev.com --dbname=bnl'
