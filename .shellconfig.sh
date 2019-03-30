#!/bin/sh

# PS1

# is it a bash shell ?
echo $0 | grep 'bash' &> /dev/null && _SCPS1HISTNB='|\!\[\e[2;2m\]'

# is git installed ?
type __git_ps1 2> /dev/null | grep '()' &> /dev/null && _SCPS1GIT='$(__git_ps1 "(%s) ")'

# is it running with systemd ?
if [[ $(cat /proc/1/comm) = 'systemd' ]]; then
  _SCSDST () {
    _SCSDST=$(systemctl is-system-running) && return 0
    echo -ne ' \e[31m●\e[0m'
  }
  _SCSDSTS='$(_SCSDST)'
fi

PS1='\[\e[2;2m\]\t \[\e[0m\][\[\e[0;'$([ $USER = "root" ] && echo "31" || echo '32')'m\]\u\[\e[0m\]@\[\e[0;36m\]\h\[\e[0m\] \[\e[2;2m\]\w\[\e[0m\] \[\e[0;93m\]'$_SCPS1GIT'\[\e[0m\]] \[\e[2;2m\]$?'$_SCPS1HISTNB$_SCSDSTS'\n> \[\e[0m\]'
unset _SCPS1GIT _SCPS1HISTNB _SCSDSTS

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
