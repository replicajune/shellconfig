#!/usr/bin/env bash

# OPTIONS
shopt -s histappend # parallel history
shopt -s checkwinsize # resize window
shopt -s autocd # go in a directory without cd
shopt -s histverify # put a caled historized command in readline

# PROMPT

# colors
_CC_dark_grey='\[\e[2;2m\]'
_CC_cyan='\[\e[0;36m\]'
_CC_orange='\[\e[0;33m\]'
_CC_reset='\[\e[0m\]'

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
_SCESS=$_CC_dark_grey'$(_SCES $?)\e[0m'

# show temperature
if [ -f '/sys/class/thermal/thermal_zone0/temp' ]; then
  # shellcheck disable=SC2016
  _SCTMP='$(($(</sys/class/thermal/thermal_zone0/temp)/1000))° '
  PS_SCTMP=$_CC_dark_grey$_SCTMP$_CC_reset
fi

# load average
_SCLDAVGF () {
  local LDAVG
  local NLOAD
  local NBPROC
  local FACTOR
  local NLOADNRM

  # shellcheck disable=SC2016
  LDAVG="$(echo -n "$(cut -d" " -f1-3 /proc/loadavg)")"
  if ! command -v nproc > /dev/null 2>&1; then
    FACTOR=0 # no color if I cannot compute load per cores
  else
    NBPROC="$(nproc)"
    NLOAD="$(cut -f1 -d' ' /proc/loadavg | tr -d '.')"
    # complex regex required
    # shellcheck disable=SC2001
    NLOADNRM="$(echo -n "$NLOAD" | sed 's/^0*//')"
    if [ -z "${NLOADNRM}" ]; then
      NLOADNRM=0
    fi
    FACTOR="$((NLOADNRM/NBPROC))"
  fi

  if [ "${FACTOR}" -ge 200 ]; then
    echo -ne '\e[31m'"${LDAVG}"
  elif [ "${FACTOR}" -ge 100 ]; then
    echo -ne '\e[33m'"${LDAVG}"
  elif [ "${FACTOR}" -ge 50 ]; then
    echo -ne '\e[32m'"${LDAVG}"
  else
    echo -n "${LDAVG}"
  fi
}

# shellcheck disable=SC2016
_SCLDAVG='[$(_SCLDAVGF)'$_CC_reset$_CC_dark_grey']'

# use red if root, green otherwise
_CC_user='\[\e[0;'"$([ "${USER}" = "root" ] && echo "33" || echo '32')"'m\]'

# blocks definition for ps1
PS_DATE=$_CC_dark_grey'\t '$_CC_reset
PS_LOCATION=$_CC_user'\u'$_CC_reset'@'$_CC_cyan'\h'$_CC_reset
PS_DIR=$_CC_dark_grey' \W'$_CC_reset
PS_GIT=$_CC_orange$_SCPS1GIT$_CC_reset
PS_ST=$_SCESS
PS_LOAD=$_CC_dark_grey$_SCLDAVG$_CC_reset
PS_SYSDS=$_CC_dark_grey$_SCSDSTS$_CC_reset

if env | grep -Eq "^SSH_CONNECTION=.*$"; then
  # you're not home, be careful
  PS_PROMPT=$_CC_orange'\n> '$_CC_reset
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
