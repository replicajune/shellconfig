#!/bin/sh

# source distrib information; will use 'ID' variable
# shellcheck source=/etc/os-release
. '/etc/os-release'

# --- ENVIRONMENTS VARIABLES

# user binary in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.local/bin
fi

# use vim if possible, nano otherwise
if [ -x "$(whereis vim |cut -d' ' -f2)" ]; then
  export VISUAL="vim"
  export EDITOR="vim"
else
  export VISUAL="nano"
  export EDITOR="nano"

fi

# history with date, no size limit
export HISTCONTROL=ignoredups
export HISTSIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "

# https://github.com/atom/atom/issues/17452
export ELECTRON_TRASH=gio

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

if [ "${ID}" != 'alpine' ]; then
  # directory stack
  alias lsd="dirs -v" # list stack directory
  alias pdir="pushd ./ > /dev/null; dirs -v"
  alias cdp="pushd" # not doing the cd="pushd", but having the option is nice

  # ressources; regular systems
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
  # ressources ; busybox based system(s) (only alpine atm)
  alias topd="du -sc .[!.]* * |sort -rn |head -11"
fi

# ressources; all systems
alias df="df -h"
alias lsm='mount | grep -E ^/dev | column -t'

# network
alias lsn="sudo ss -lpnt |column -t"

# package managment
case $ID in
  ubuntu|debian|raspbian)
    alias upd="sudo apt update && apt list --upgradable"
    alias updnow="sudo apt update && sudo apt upgrade -y"
    alias ipkg="sudo apt install -y"
    alias rpkg="sudo apt purge -y"
    alias gpkg="dpkg -l | grep -i"
    cleanpm () {
      echo "remove orphans"
      sudo apt-get autoremove -y > /dev/null;
      echo "cleaning apt"
      sudo apt-get autoclean > /dev/null;
      echo "delete old/removed package configs"
      for PKG in $(dpkg -l | grep -E '(^rc\s+.*$)' | cut -d' ' -f3); do
        sudo dpkg -P "${PKG}" > /dev/null
      done
    }
    ilpkg () {
      sudo apt install -y "./${1}"
    }
    ;;

  fedora)
    alias upd="sudo dnf check-update --refresh --assumeno"
    alias updnow="sudo dnf update --assumeyes"
    alias ipkg="sudo dnf install -y"
    alias rpkg="sudo dnf remove --assumeyes"
    alias gpkg="rpm -qa | grep -i"
    alias cleanpm="sudo dnf clean all"
    ilpkg () {
      sudo dnf install -y "./${1}"
    }
    ;;

  centos)
    alias upd="sudo yum update --assumeno"
    alias updnow="sudo yum update -y"
    alias ipkg="sudo yum install -y"
    alias rpkg="sudo yum remove"
    alias gpkg="rpm -qa | grep -i"
    alias cleanpm="sudo yum clean all"
    ilpkg () {
      sudo yum install -y "./${1}"
    }
    ;;

  alpine)
    alias upd="sudo apk update && echo 'UPGRADABLE :' && sudo apk upgrade -s"
    alias updnow="sudo apk update && sudo apk upgrade"
    alias rpkg="sudo apk del"
    alias gpkg="apk list -I | grep -i"
    alias cleanpm="sudo apk -v cache clean"
    ;;

  *)
    ;;
esac

# pager or mod of aliases using a pager. Using most, color friendly
if [ -x "$(whereis most |cut -d' ' -f2)" ]; then
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
fi

# LXC
if [ -x "$(whereis lxc |cut -d' ' -f2)" ]; then
  # go in a container, do some test, leave. stop and destroy it automatically
  lxcspawn() {
    # usage : lxcspawn image_name shell_name
    # shell is opt, default to bash
    IMAGE="${1}"
    SHELL="${2:-bash}"
    CNT_NAME=$(head /dev/urandom | tr -dc '[:lower:]' | head -c 12 ; echo '')
    lxc launch "images:${IMAGE}" "$CNT_NAME"
    lxc exec "$CNT_NAME" "${SHELL}"
    lxc stop "$CNT_NAME"
    lxc delete "$CNT_NAME"
  }
fi

# lazygit
if [ -x "$(whereis lazygit |cut -d' ' -f2)" ]; then
  alias lgt=lazygit
fi

# vagrant
if [ -x "$(whereis vagrant |cut -d' ' -f2)" ]; then

  # use libvirt instead of default virtualbox : better perfs, less oracle stuff
  export VAGRANT_DEFAULT_PROVIDER=libvirt

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

  # - show a red flag if systemd isn't healthy
  # skipped shellcheck rules : usually systems with systemd run with bash
  _SCSDST () {
    systemctl is-system-running > /dev/null 2> /dev/null && return 0
    # shellcheck disable=SC2039
    echo -ne '\e[31m⚑\e[0m '
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)'

  # - show a blue dot if systemd needs to be restarted
  _SCSDRT () {
    # shellcheck disable=SC2039
    local systemd_live_ver
    # shellcheck disable=SC2039
    local systemd_pkg_ver

    systemd_live_ver="$(systemctl --version | grep '^systemd' | cut -d' ' -f2)"
    case $ID in
      ubuntu|debian|raspbian)
        systemd_pkg_ver="$(
          dpkg -s systemd \
          | grep '^Version\:\s.*$' \
          | cut -d' ' -f2 \
          | cut -d'-' -f1)"
        ;;
      centos|fedora)
        # shellcheck disable=SC1117
        systemd_pkg_ver="$(
          rpm -qi systemd \
          | grep -E "^Version\s+\:\s[0-9]+$" \
          | cut -d':' -f2 \
          | tr -d ' ')"
        ;;
      *)
        return 0 # non supported system
        ;;
    esac

    if [ "${systemd_live_ver}" != "${systemd_pkg_ver}" ]; then
      # shellcheck disable=SC2039
      echo -ne '\e[34m♻\e[0m '
    fi
  }
  # shellcheck disable=SC2016
  _SCSDRTS='$(_SCSDRT)'
fi

# am I using the last kernel available on my system ?
_SCKRT () {
  kernel_live_ver="$(uname -r)"
  case $ID in
    ubuntu)
      kernel_live_ver="$(uname -r | cut -d'-' -f1-2 | tr '-' '.')"
      kernel_pkg_ver="$(
        dpkg -s linux-generic \
        | grep '^Version\:\s.*$' \
        | cut -d' ' -f2 \
        | cut -d'.' -f-4)"
      ;;
    debian)
      kernel_live_ver="$(uname -r | sed 's/\-[a-zA-Z]*[0-9]*[a-zA-Z]*$//')"
      kernel_pkg_ver="$(\
        dpkg -s "$( \
          dpkg -s linux-image-amd64 \
          | grep '^Depends\:' \
          | cut -d' ' -f2)" \
        | grep '^Version\:' \
        | cut -d' ' -f2 \
        | cut -d'+' -f1)"
      ;;
    raspbian)
      kernel_pkg_ver="$(
        for VER in /lib/modules/*; do
          # shellcheck disable=SC2039
          local VERNUM
          VERNUM="${VER##*/}"
          if [ "${kernel_live_ver}" = "${VERNUM}" ]; then
            echo "${VERNUM}"
            break
          fi
        done
        )"
      ;;
    centos|fedora)
      kernel_pkg_ver="$(rpm -q kernel | sort -Vr | head -1 | cut -d'-' -f2-)"
      ;;
    *)
      return 0 # non supported system
      ;;
  esac

  if [ "${kernel_live_ver}" != "${kernel_pkg_ver}" ]; then
    # shellcheck disable=SC2039
    echo -ne '\e[33m↻\e[0m'
  fi
}
# shellcheck disable=SC2016
_SCKRTS='$(_SCKRT)'

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
PS_SYSDS=$_CC_dark_grey$_SCSDSTS$_CC_reset
PS_SYSDR=$_CC_dark_grey$_SCSDRTS$_CC_reset
PS_SYSKR=$_CC_dark_grey$_SCKRTS$_CC_reset
PS_PROMPT='\n→  '

# PS1/2 definition
PS_LOC_BLOCK='['$PS_LOCATION$PS_DIR$PS_GIT'] '
PS_EXTRA_BLOCK=$PS_ST_HIST' '$PS_LOAD' '$PS_SYSDS$PS_SYSDR$PS_SYSKR
PS1=$PS_DATE$PS_LOC_BLOCK$PS_EXTRA_BLOCK$PS_PROMPT
PS2='…  '

# --- for personnal or private aliases (things with contexts and stuff)
if [ -f ~/.private.sh ]; then
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
