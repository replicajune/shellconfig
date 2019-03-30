#!/bin/sh

# PS1

# color codes
_CC_dark_grey='\[\e[2;2m\]'
_CC_cyan='\[\e[0;36m\]'
_CC_orange='\[\e[0;93m\]'
# special codes
_CC_reset='\[\e[0m\]'
_CC_user='\[\e[0;'$([ $USER = "root" ] && echo "31" || echo '32')'m\]'

# is it a bash shell ?
echo $0 | grep 'bash' &> /dev/null && _SCPS1HISTNB='|\!\[\e[2;2m\]'
# is git installed ?
type __git_ps1 2> /dev/null | grep '()' &> /dev/null && _SCPS1GIT='$(__git_ps1 " (%s)")'
# is it running with systemd ?
if [[ $(cat /proc/1/comm) = 'systemd' ]]; then
  _SCSDST () {
    _SCSDST=$(systemctl is-system-running) && return 0
    echo -ne '\e[31m●\e[0m'
  }
  _SCSDSTS='$(_SCSDST)'
fi
# load average, running proc/sleeps & latest assign pid number
_SCLDAVG='[$(echo -n $(cat /proc/loadavg))]'
# actual PS1 definition
PS1=$_CC_dark_grey'\t '$_CC_reset'[ '$_CC_user'\u'$_CC_reset'@'$_CC_cyan'\h'$_CC_dark_grey' \W'$_CC_orange$_SCPS1GIT$_CC_reset' ] '$_CC_dark_grey'$?'$_SCPS1HISTNB' '$_SCLDAVG' '$_SCSDSTS'\n→  '$_CC_reset
PS2='…  '
unset _SCPS1GIT _SCPS1HISTNB _SCSDSTS _SCLDAVG _CC_dark_grey _CC_cyan _CC_orange _CC_reset _CC_user

# tmux : disable this using "export TMUX=disable" before loading shellconfig
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "$SUDO_USER" ]; then
  tmux attach -t default 2> /dev/null || tmux new -s default
fi

# PACKAGE MANAGMENT
if [ -x $(whereis apt |cut -d' ' -f2) ]; then
  _PKG_MGR='apt'
elif [ -x $(whereis yum |cut -d' ' -f2) ]; then
  _PKG_MGR='yum'
elif [ -x $(whereis apk |cut -d' ' -f2) ]; then
  _PKG_MGR='apk'
else
  continue
fi

[ "$(strings $(whereis ps |cut -d' ' -f2) |grep busybox |head -1)" = 'busybox' ] && _BBX=true || true

[ -h /home/${SUDO_USER-$USER}/.environments ] && source /home/${SUDO_USER-$USER}/.environments
[ -h /home/${SUDO_USER-$USER}/.aliases ] && source /home/${SUDO_USER-$USER}/.aliases
[ -e /home/${SUDO_USER-$USER}/.aliases.private ] && source /home/${SUDO_USER-$USER}/.aliases.private || true
