#!/usr/bin/env bash
# common settings for non busybox shells

# files managment
if ! [ -L "/bin/ls" ]; then
  alias lz='command ls -g --classify --group-directories-first --context --no-group --all'
  alias l='ls -C --classify --group-directories-first'
  alias ll='ls -l --classify --group-directories-first --human-readable'
  alias la='ls -l --classify --group-directories-first --human-readable --all'
  alias lll='ls -l --classify --group-directories-first --human-readable --context  --author'
  alias lla='ls -l --classify --group-directories-first --human-readable --context  --author --all'
  alias lt='ls -gt --classify --reverse --human-readable --all --no-group'
fi

# override some aliases if exa is available
if command -v exa > /dev/null 2>&1; then
  alias ls='exa'
  alias l='exa --classify --group-directories-first'
  alias ll='exa -l --classify --group-directories-first --git'
  alias la='exa -l --classify --group-directories-first --all --git'
  alias lll='exa -l --classify --group-directories-first --git --links --inode --blocks --extended'
  alias lla='exa -l --classify --group-directories-first --git --links --inode --blocks --extended --all'
  alias lt='exa -l --git --links --inode --blocks --extended --all --sort date'
fi

alias vd="diff --side-by-side --suppress-common-lines"

alias psf="
  ps --ppid 2 -p 2 --deselect \
  --format user,pid,ppid,pcpu,pmem,time,stat,cmd --forest"
alias topm="
  ps -A --format user,pid,ppid,pcpu,pmem,time,stat,comm --sort -pmem \
  | head -11"
alias topt="
  ps -A --format user,pid,ppid,pcpu,pmem,time,stat,comm --sort -time \
  | head -11"
alias topc="
  ps -A --format user,pid,ppid,pcpu,pmem,time,stat,comm --sort -pcpu \
  | head -11"

# ressources
alias topd='sudo sh -c "du -shc .[!.]* * |sort -rh |head -11" 2> /dev/null'
alias lsm="mount | grep -E '^(/dev|//)' | column -t"

# shellcheck disable=SC2142
alias ha="history | awk '{ print substr(\$0, index(\$0,\$4)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"
