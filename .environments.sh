#!/bin/sh

[ -n "${PATH##*/.local/bin*}" ] &&\
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.local/bin || true

export VISUAL="vim"
export EDITOR="vim"

export HISTCONTROL=ignoredups
export HISTSIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "

export GIT_PS1_SHOWUPSTREAM='verbose name git'
export GIT_PS1_SHOWUNTRACKEDFILES=y

# https://github.com/atom/atom/issues/17452
export ELECTRON_TRASH=gio
