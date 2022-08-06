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
hlr () { grep -iFR "${@}" .; } # recursive highlight (not full but ref/numbers avail.)

# history
alias h="history -20"
alias gh='history 1 | grep'
# shellcheck disable=SC2142
alias ha="history 1 | awk '{ print substr(\$0, index(\$0,\$2)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"

if command -v limactl > /dev/null 2>&1; then
  alias lm=limactl
fi


# write on file .. usage : wof file.iso /dev/usbthing
wof () { sudo dd if="${1}" of="${2}" bs=32m; sync; }

if command -v tmux > /dev/null 2>&1 \
&& [ -S "$(echo "${TMUX}" | cut -f1 -d',')" ]; then
  if command -v most > /dev/null 2>&1; then
    alias man='tmux neww man -P most'
  else
    alias man='tmux neww man'
  fi
fi
