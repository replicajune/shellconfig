#!/usr/bin/env bash
# common settings for non busybox shells

alias lz='command ls -g --classify --group-directories-first --context --no-group --all'
alias vd="diff --side-by-side --suppress-common-lines"

alias psf="ps --ppid 2 -p 2 --deselect \
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

alias lsd="dirs -v | grep -Ev '^0\s+.*$'" # list stack directory
alias pdir="pushd ./ > /dev/null; lsd"


# ressources
alias topd='sudo sh -c "du -shc .[!.]* * |sort -rh |head -11" 2> /dev/null'
alias lsm="mount | grep -E '^(/dev|//)' | column -t"

# shellcheck disable=SC2142
alias ha="history | awk '{ print substr(\$0, index(\$0,\$4)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"
