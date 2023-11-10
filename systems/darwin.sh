#!/usr/bin/env sh

# standard aliases
if command -v eza > /dev/null 2>&1; then
  alias ls='eza -G'
  alias lll='ls -l -h'
  alias lt='ls -l -a -h -t=modified'
else
  alias ls='ls -G'
  alias lll='ls -l -h -O'
  alias lt='ls -l -a -h -tr'
fi
alias l='ls -F'
alias ll='ls -F -l -h'
alias la='ls -F -l -h -A'
alias lla='ls -l -h -a'

# user binaries in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH="${PATH}:/Users/${SUDO_USER-$USER}/.local/bin"
fi

# file managment
alias hl="grep -izF" # highlight
hlr () { grep -iFR "${@}" .; } # recursive highlight (not full but ref/numbers avail.)

# package manager
alias upd='brew update --quiet; brew outdated'
alias updnow='brew update --quiet; brew upgrade'

# history
[ -d "/${HOME}/.var/log" ] || mkdir -p "/${HOME}/.var/log"
HISTFILE="/${HOME}/.var/log/$(date +%Y-%m-%d).zsh_history.log"; export HISTFILE
export HISTSIZE='INF'
alias h="history -20"
gh () { grep -FRi "${1}" ~/.var/log/*.zsh_history.log | cut -f2- -d':'; }
# # shellcheck disable=SC2142
# alias ha="history 1 | awk '{ print substr(\$0, index(\$0,\$2)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"

# write on file .. usage : wof file.iso /dev/usbthing
wof () { sudo dd if="${1}" of="${2}" bs=32m; sync; }

# specifics
if command -v limactl > /dev/null 2>&1; then
  alias lm=limactl
fi

# integrate tmux as I don't fall back to the linux flow otherwise
if command -v tmux > /dev/null 2>&1 \
&& [ -S "$(echo "${TMUX}" | cut -f1 -d',')" ]; then
  if command -v most > /dev/null 2>&1; then
    alias man='tmux neww man -P most'
  else
    alias man='tmux neww man'
  fi
fi
