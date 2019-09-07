#!/bin/sh

# --- ENVIRONMENTS VARIABLES

# user binary in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.local/bin
fi

# use vim when possible
export VISUAL="vim"
export EDITOR="vim"

# history with date, no size limit
export HISTCONTROL=ignoredups
export HISTSIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "

# show more git stuff in ps1
export GIT_PS1_SHOWUPSTREAM='verbose'
export GIT_PS1_SHOWUNTRACKEDFILES=y

# https://github.com/atom/atom/issues/17452
export ELECTRON_TRASH=gio

# better perfs, less oracle stuff
export VAGRANT_DEFAULT_PROVIDER=libvirt

# --- DETECTIONS

# Package managment definition (used for aliases and functions)
if [ -x "$(whereis apt |cut -d' ' -f2)" ]; then
  _PKG_MGR='apt'
elif [ -x "$(whereis dnf |cut -d' ' -f2)" ]; then
  _PKG_MGR='dnf'
elif [ -x "$(whereis yum |cut -d' ' -f2)" ]; then
  _PKG_MGR='yum'
elif [ -x "$(whereis apk |cut -d' ' -f2)" ]; then
  _PKG_MGR='apk'
else
  true
fi

# # Busybox based system ?
if  [\
  "$(strings "$(whereis ps |cut -d' ' -f2)" | grep busybox | head -1)"\
   = 'busybox' \
  ]; then
    _BBX=true
fi

# --- ALIASES

# files managment
alias l='ls -CF'
alias ll="ls -Flh"
alias la="ls -Flha"
alias lz="ls -FlhZ"
alias lt='du -sh * | sort -h'

alias rm="rm -i"
alias rmr="rm -ri"

alias vd="diff --side-by-side --suppress-common-lines"
alias ltree="tree -a --prune --noreport -h -C -I '*.git' | less"

if [ "${_BBX}" != 'true' ]; then
  alias lsd="dirs -v" # list stack directory
  alias pdir="pushd ./ > /dev/null; dirs -v"
  alias cdp="pushd" # not doing the cd="pushd", but having the option is nice
fi

# ressources
alias df="df -h"
alias lsm="findmnt"
if [ "${_BBX}" != 'true' ]; then
  alias topd="du -sch .[!.]* * |sort -rh |head -11"
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
else
  alias topd="du -sc .[!.]* * |sort -rn |head -11"
fi

# network
alias lsn="sudo ss -lpnt |column -t"

# package managment
case $_PKG_MGR in
  apt)
    alias upd="sudo apt update && apt list --upgradable"
    alias updnow="sudo apt update && sudo apt upgrade -y"
    alias ipkg="sudo apt install -y"
    alias rpkg="sudo apt purge -y"
    alias gpkg="dpkg -l | grep -i"
    alias cleanpm="sudo apt autoremove -y && sudo apt autoclean"
    pkg_inst () {
      sudo apt install -y "./${1}"
    }
    ;;

  dnf)
    alias upd="sudo dnf check-update --refresh --assumeno"
    alias updnow="sudo dnf update --assumeyes"
    alias ipkg="sudo dnf install -y"
    alias rpkg="sudo dnf remove --assumeyes"
    alias gpkg="rpm -qa | grep -i"
    alias cleanpm="sudo dnf clean all"
    pkg_inst () {
      sudo dnf install -y "./${1}"
    }
    ;;

  yum)
    alias upd="sudo yum update --assumeno"
    alias updnow="sudo yum update -y"
    alias ipkg="sudo yum install -y"
    alias rpkg="sudo yum remove"
    alias gpkg="rpm -qa | grep -i"
    alias cleanpm="sudo yum clean all"
    pkg_inst () {
      sudo yum install -y "./${1}"
    }
    ;;

  apk)
    alias upd="sudo apk update && echo 'UPGRADABLE :' && sudo apk upgrade -s"
    alias updnow="sudo apk update && sudo apk upgrade"
    alias rpkg="sudo apk del"
    alias gpkg="apk list -I | grep -i"
    alias cleanpm="sudo apk -v cache clean"
    ;;

  *)
    ;;
esac

# pager or mod of aliases using a pager
if [ -x "$(whereis most |cut -d' ' -f2)" ]; then
  # most is color friendly
  alias ltree="tree -a --prune --noreport -h -C -I '*.git' | most"
  alias man='PAGER=most man'
fi

# docker
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

# lazygit
if [ -x "$(whereis lazygit |cut -d' ' -f2)" ]; then
  alias lgt=lazygit
fi

# vagrant
if [ -x "$(whereis vagrant |cut -d' ' -f2)" ]; then
  vagrant_rsync() {
    # replace vagrant-scp
    # usage : use it like rsync
    if [ $# -lt 2 ]; then
      rsync --help
      return 1
    else
      UUID=$(cat /proc/sys/kernel/random/uuid)
      CONF="/tmp/vagrant_ssh-config.${UUID}"
      vagrant ssh-config > "${CONF}"
      rsync -e "ssh -F ${CONF}" "${@}"
      rm -f "${CONF}"
    fi
  }
fi

# misc
alias h="history |tail -20"
alias gh='history|grep'
alias vless="vim -M"
alias datei="date --iso-8601=m"
alias weather="curl wttr.in/?0"
alias rambotify="until spotify &> /dev/null; do echo try again; done &"
alias mnt='mount | grep -E ^/dev | column -t'

# --- PS1

# is it a bash shell ?
if echo "${0}" | grep -q bash; then
  # show history number
  _SCPS1HISTNB='|\!\[\e[2;2m\]'
fi

# is git installed ?
# type works on both bash and ash
# shellcheck disable=SC2039
if type __git_ps1 2> /dev/null | grep -q '()'; then
  # includes git info
  # shellcheck disable=SC2016
  _SCPS1GIT='$(__git_ps1 " (%s)")'
fi

# is it running with systemd ?
if [ "$(cat /proc/1/comm)" = 'systemd' ]; then
  # show a critical red dot if systemd isn't healthy
  _SCSDST () {
    systemctl is-system-running > /dev/null 2> /dev/null && return 0
    # backslash escapes and non new line required
    # shellcheck disable=SC2039
    echo -ne '\e[31m●\e[0m'
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)'
fi

# load average
# shellcheck disable=SC2016
_SCLDAVG='[$(echo -n $(cat /proc/loadavg | cut -d" " -f1-3 ))]'

# color & special codes
_CC_dark_grey='\[\e[2;2m\]'
_CC_cyan='\[\e[0;36m\]'
_CC_orange='\[\e[0;33m\]'
_CC_reset='\[\e[0m\]'
_CC_user='\[\e[0;'"$([ "${USER}" = "root" ] && echo "31" || echo '32')"'m\]'

# blocks definition for ps1
PS_DATE=$_CC_dark_grey'\t '$_CC_reset
PS_LOCATION=$_CC_user'\u'$_CC_reset'@'$_CC_cyan'\h'$_CC_reset
PS_DIR=$_CC_dark_grey' \W'$_CC_reset
PS_GIT=$_CC_orange$_SCPS1GIT$_CC_reset
PS_ST_HIST=$_CC_dark_grey'$?'$_SCPS1HISTNB$_CC_reset
PS_LOAD=$_CC_dark_grey$_SCLDAVG$_CC_reset
PS_SYSD=$_CC_dark_grey$_SCSDSTS$_CC_reset
PS_PROMPT='\n→  '

# PS1/2 definition
PS_LOC_BLOCK='['$PS_LOCATION$PS_DIR$PS_GIT'] '
PS_EXTRA_BLOCK=$PS_ST_HIST' '$PS_LOAD' '$PS_SYSD
PS1=$PS_DATE$PS_LOC_BLOCK$PS_EXTRA_BLOCK$PS_PROMPT
PS2='…  '

# --- for personnal or private aliases (things with contexts and stuff)
if [ -f "${HOME}/.private.sh" ]; then
  # shellcheck source=/dev/null
  . ~/.private.sh
fi

# --- TMUX : disable this using "export TMUX=disable" before loading shellconfig
if command -v tmux > /dev/null 2> /dev/null &&\
   [ -z "$TMUX" ] &&\
   [ -z "$SUDO_USER" ]; then
  tmux attach -t default 2> /dev/null || tmux new -s default
  exit
fi
