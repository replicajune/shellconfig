#!/usr/bin/env bash

# OPTIONS
shopt -s histappend # parallel history
shopt -s checkwinsize # resize window
shopt -s autocd # go in a directory without cd
shopt -s histverify # put a caled historized command in readline

# ALIASES
alias lsd="dirs -v | grep -Ev '^ 0 .*$'" # list stack directory

# PROMPT

# is git installed ? (type works on both bash and ash)
if type __git_ps1 2> /dev/null | grep -q '()'; then

  # show more git stuff
  export GIT_PS1_SHOWUPSTREAM='verbose'
  export GIT_PS1_SHOWUNTRACKEDFILES=y

  # includes git info
  # shellcheck disable=SC2016
  _SCPS1GIT='$(__git_ps1 " (%s)")'
fi

# is it running with systemd ? then, show when it's in a bad state or need
# a restart
if [ "$(cat /proc/1/comm)" = 'systemd' ]; then

  # - show various icons for systemd system's status, along with description
  # https://www.freedesktop.org/software/systemd/man/systemctl.html#is-system-running
  # skipped shellcheck rules : usually systems with systemd run with bash
  _SCSDST () {
    systemctl is-system-running > /dev/null 2>&1 \
    || echo -ne '\e[33m●\e[0m '
  }
  _SCSDSTU () {
    [ "${USER}" = "root" ] && return 0
    [ -z "${DBUS_SESSION_BUS_ADDRESS}" ] && return 0
    systemctl --user is-system-running > /dev/null 2>&1 \
    || echo -ne '\e[35m●\e[0m '
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)$(_SCSDSTU)'
fi

# exit status in red if != 0
_SCCLR () { if [ "${1}" -ne 0 ]; then echo -ne '\e[31m'; fi; }
_SCES () { echo "$(_SCCLR "${1}")${1}"; }

# shellcheck disable=SC2016
_SCESS=$CC_DARK_GREY'$(_SCES $?)\e[0m'

# show temperature
if [ -f '/sys/class/thermal/thermal_zone0/temp' ]; then
  # shellcheck disable=SC2016
  _SCTMP='$(($(</sys/class/thermal/thermal_zone0/temp)/1000))° '
  PS_SCTMP=$CC_DARK_GREY$_SCTMP$CC_RESET_COLOR
fi

# use red if root, green otherwise
_CC_user=$'\e[0;'"$([ "${USER}" = "root" ] && echo '33' || echo '32')"'m'

# blocks definition for ps1
PS_DATE=$CC_DARK_GREY'\t '$CC_RESET_COLOR
PS_LOCATION=$_CC_user'\u'$CC_RESET_COLOR'@'$CC_CYAN'\h'$CC_RESET_COLOR
PS_DIR=$CC_DARK_GREY' \W'$CC_RESET_COLOR
PS_GIT=$CC_ORANGE$_SCPS1GIT$CC_RESET_COLOR
PS_ST=$_SCESS
# shellcheck disable=SC2016
PS_LOAD='[$(prompt_load)]'
PS_SYSDS=$CC_DARK_GREY$_SCSDSTS$CC_RESET_COLOR

if env | grep -Eq "^SSH_CONNECTION=.*$"; then
  # you're not home, be careful
  PS_PROMPT=$CC_ORANGE'\n> '$CC_RESET_COLOR
else
  PS_PROMPT='\n> '
fi

# PS1/2 definition
PS_LOC_BLOCK='['$PS_LOCATION$PS_DIR$PS_GIT'] '
PS_EXTRA_BLOCK=$PS_ST' '$PS_LOAD' '$PS_SCTMP
PS_SYSD_BLOCK=$PS_SYSDS

if [ "${TERM_PROGRAM}" = "vscode" ]; then
  PS1='> '
else
  PS1=$PS_DATE$PS_LOC_BLOCK$PS_EXTRA_BLOCK$PS_SYSD_BLOCK$PS_PROMPT
fi

PS2='…  '
