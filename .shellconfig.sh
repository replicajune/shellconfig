#!/bin/sh

# PS1
if [ $USER = "root" ]; then
  PS1="\t [\[\e[0;31m\]\u\[\e[0m\]@\[\e[0;36m\]\h \[\e[0;34m\]\w\[\e[0m\]]# "
else
  PS1="\t [\[\e[0;32m\]\u\[\e[0m\]@\[\e[0;36m\]\h \[\e[0;34m\]\w\[\e[0m\]]$ "
fi

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
