#!/usr/bin/env sh

# standard aliases
alias ls='ls -G'
alias l='ls -F'
alias ll='ls -F -l -h'
alias la='ls -F -l -h -A'
alias lll='ls -l -h -O'
alias lla='ls -l -h -a'
alias lt='ls -l -a -h -tr'

# user binaries in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH="${PATH}:/Users/${SUDO_USER-$USER}/.local/bin"
fi

# file managment
alias hl="grep -izF" # highlight
hlr () { grep -iFR "${@}" . } # recursive highlight (not full but ref/numbers avail.)
# history
alias h="history -20"
alias gh='history 1 | grep'
# shellcheck disable=SC2142
alias ha="history | awk '{ print substr(\$0, index(\$0,\$4)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"

load () {
  local LDAVG
  local NLOAD
  local NBPROC
  local FACTOR
  local NLOADNRM
  # shellcheck disable=SC2016
  LDAVG="$(sysctl -n vm.loadavg | tr -d '{' | tr -d '}' | cut -d ' ' -f2-4)"
  NBPROC="$(sysctl -n hw.physicalcpu)"
  NLOAD="$(echo "${LDAVG}" | cut -f1 -d' ' | tr -d '.')"
  # complex regex required
  # shellcheck disable=SC2001
  NLOADNRM="$(echo -n "$NLOAD" | sed 's/^0*//')"
  if [ -z "${NLOADNRM}" ]; then
    NLOADNRM=0
  fi
  FACTOR="$((NLOADNRM/NBPROC))"

  if [ "${FACTOR}" -ge 200 ]; then
    echo -ne '\e[31m'"${LDAVG}"'\e[0m'
  elif [ "${FACTOR}" -ge 100 ]; then
    echo -ne '\e[33m'"${LDAVG}"'\e[0m'
  elif [ "${FACTOR}" -ge 50 ]; then
    echo -ne '\e[32m'"${LDAVG}"'\e[0m'
  else
    echo -n "${LDAVG}"
  fi
}
