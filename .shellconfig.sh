#!/bin/sh

# --- PS1

# color & special codes
_CC_dark_grey='\[\e[2;2m\]'
_CC_cyan='\[\e[0;36m\]'
_CC_orange='\[\e[0;93m\]'
_CC_reset='\[\e[0m\]'
_CC_user='\[\e[0;'"$([ "${USER}" = "root" ] && echo "31" || echo '32')"'m\]'

# is it a bash shell ?
if echo "${0}" | grep -q bash; then
  _SCPS1HISTNB='|\!\[\e[2;2m\]'
fi

# is git installed ?
# type works on both bash and ash
# shellcheck disable=SC2039
if type __git_ps1 2> /dev/null | grep -q '()'; then
  # shellcheck disable=SC2016
  _SCPS1GIT='$(__git_ps1 " (%s)")'
fi

# is it running with systemd ?
if [ "$(cat /proc/1/comm)" = 'systemd' ]; then
  _SCSDST () {
    systemctl is-system-running > /dev/null 2> /dev/null && return 0
    # backslash escapes and non new lines required
    # shellcheck disable=SC2039
    echo -ne '\e[31m●\e[0m'
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)'
fi

# load average, running proc/sleeps & latest assign pid number
# shellcheck disable=SC2016
_SCLDAVG='[$(echo -n $(cat /proc/loadavg | cut -d" " -f1-3 ))]'

# PS1/2 definition
PS1=$_CC_dark_grey'\t '$_CC_reset'[ '$_CC_user'\u'$_CC_reset'@'$_CC_cyan'\h'$_CC_dark_grey' \W'$_CC_orange$_SCPS1GIT$_CC_reset' ] '$_CC_dark_grey'$?'$_SCPS1HISTNB' '$_SCLDAVG' '$_SCSDSTS'\n→  '$_CC_reset
PS2='…  '
unset _SCPS1GIT _SCPS1HISTNB _SCSDSTS _SCLDAVG _CC_dark_grey _CC_cyan _CC_orange _CC_reset _CC_user

# tmux : disable this using "export TMUX=disable" before loading shellconfig
if command -v tmux > /dev/null 2> /dev/null &&\
   [ -z "$TMUX" ] &&\
   [ -z "$SUDO_USER" ]; then
  tmux attach -t default 2> /dev/null || tmux new -s default
fi

# PACKAGE MANAGMENT DEFINITION (used for aliases and functions)
if [ -x "$(whereis apt |cut -d' ' -f2)" ]; then
  # variable used in another script
  # shellcheck disable=SC2034
  _PKG_MGR='apt'
elif [ -x "$(whereis yum |cut -d' ' -f2)" ]; then
  # variable used in another script
  # shellcheck disable=SC2034
  _PKG_MGR='yum'
elif [ -x "$(whereis apk |cut -d' ' -f2)" ]; then
  # variable used in another script
  # shellcheck disable=SC2034
  _PKG_MGR='apk'
else
  true
fi

# # Busybox based system ?
if [ "$(strings "$(whereis ps |cut -d' ' -f2)" |grep busybox |head -1)" = 'busybox' ]; then
  # variable used in another script
  # shellcheck disable=SC2034
  _BBX=true
fi

for item in environments functions aliases aliases.private; do
  if [ -h "/home/${SUDO_USER-$USER}/.${item}" ]; then
    # shellcheck source=/dev/null
    . "/home/${SUDO_USER-$USER}/.${item}"
  fi
done
