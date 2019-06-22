#!/bin/sh

# FILES MANAGMENT
alias l='ls -CF'
alias ll="ls -Flh"
alias la="ls -Flha"
alias lz="ls -FlhZ"

alias rm="rm -i"
alias rmr="rm -ri"

if [ "${_BBX}" != 'true' ]; then
  alias lsd="dirs -v" # list stack directory
  alias pdir="pushd ./ > /dev/null; dirs -v"
  alias cdp="pushd" # not doing the cd="pushd", but having the option is nice
fi

# RESSOURCES
alias df="df -h"
alias lsm="findmnt"
if [ "${_BBX}" != 'true' ]; then
  alias topd="du -sch .[!.]* * |sort -rh |head -11"
  alias psf="ps --ppid 2 -p 2 --deselect --format user,pid,ppid,pcpu,pmem,time,stat,cmd --forest"
  alias topm="ps -A --format user,pid,ppid,pcpu,pmem,time,stat,comm --sort -pmem |head -11"
  alias topt="ps -A --format user,pid,ppid,pcpu,pmem,time,stat,comm --sort -time |head -11"
  alias topc="ps -A --format user,pid,ppid,pcpu,pmem,time,stat,comm --sort -pcpu |head -11"
else
  alias topd="du -sc .[!.]* * |sort -rn |head -11"
fi

# NETWORK
alias lsn="sudo ss -lpnt |column -t"

# PACKAGE MANAGMENT
case $_PKG_MGR in
  apt)
    alias upd="sudo apt update && apt list --upgradable"
    alias updnow="sudo apt update && sudo apt upgrade -y"
    alias rmp="sudo apt purge -y"
    alias cleanpm="sudo apt autoremove -y && sudo apt autoclean"
    alias lsp="apt list -i"
    alias lspl="dpkg -l |column"
    ;;
  yum)
    alias upd="sudo yum update --assumeno"
    alias updnow="sudo yum update -y"
    alias rmp="sudo yum remove"
    alias cleanpm="sudo yum clean all"
    alias lsp="rpm -qa"
    ;;
  apk)
    alias upd="sudo apk update && echo 'UPGRADABLE :' && sudo apk upgrade -s"
    alias updnow="sudo apk update && sudo apk upgrade"
    alias rmp="sudo apk del"
    alias cleanpm="sudo apk -v cache clean"
    alias lsp="apk list -I"
    ;;
  *)
    ;;
esac

if [ -x "$(whereis docker |cut -d' ' -f2)" ]; then
  alias dk="docker"
  alias dkr="docker run -it"
  alias dklc="docker ps -a"
  alias dkli="docker image ls"
  alias dkln="docker network ls"
  alias dklv="docker volume ls"
  alias dkpc="docker container prune -f"
  alias dkpi="docker image prune -f"
  alias dkpn="docker network prune -f"
  alias dkpv="docker volume prune -f"
  alias dkpurge="docker system prune -af"
  alias dkpurgeall="docker system prune -af; docker volume prune -f"
  alias dkdf="docker system df"
  alias dki="docker system info"
fi

if [ -x "$(whereis docker-compose |cut -d' ' -f2)" ]; then
  alias dkc="docker-compose"
  alias dkcb="docker-compose build"
  alias dkcu="docker-compose up -d"
  alias dkcbu="docker-compose up -d --build"
  alias dkcd="docker-compose down"
  alias dkcr="docker-compose restart"
fi

if [ -x "$(whereis git |cut -d' ' -f2)" ]; then
  alias gs="git status"
  alias ga="git add ."
  alias gc="git commit -m"
  alias gph="git push --all"
  alias gpl="git pull --all"
  alias gl="git log --graph --oneline"
  alias gs="git status --show-stash"
fi

# MISC
alias h="history |tail -20"
alias vless="vim -M"
alias datei="date --iso-8601=s"
alias weather="curl wttr.in"

# OPTIONALS
if [ -x "$(whereis lazygit |cut -d' ' -f2)" ]; then
  alias lz=lazygit
fi

# FOR PERSONNAL OR PRIVATE ALIASES (THINGS WITH CONTEXTS AND STUFF)
fi [ -f '~/.aliases.private' ]; then
 source ~/.aliases.private
fi
