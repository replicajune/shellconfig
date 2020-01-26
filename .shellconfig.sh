#!/bin/bash

# source distrib information; will use 'ID' variable
# shellcheck source=/etc/os-release
if [ -f '/etc/os-release' ]; then
  source '/etc/os-release'
fi

# --- ENVIRONMENTS VARIABLES

# user binary in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.local/bin
fi

# user default python virtual env in ~/.venv/global
if [ -n "${PATH##*/.venv/global/bin*}" ]; then
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.venv/global/bin
fi

# use vim if possible, nano otherwise
if command -v vim &> /dev/null; then
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

if command -v gio &> /dev/null; then
  export ELECTRON_TRASH=gio
  alias tt="gio trash" # to trash : https://unix.stackexchange.com/a/445281
fi

# --- ALIASES

# files managment
alias l='ls -CF'
alias ll='ls -gGFh --group-directories-first'
alias lll='ls -FlhZi --author --group-directories-first'
alias la='ls -FlhA --group-directories-first'
alias lz='ls -ZgGF --group-directories-first'
alias lt='ls -lrt'
alias rm="rm -i"
alias vd="diff --side-by-side --suppress-common-lines"

if [ "x${ID}" != 'xalpine' ]; then
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
fi

# ressources; all systems
alias topd="du -sc .[!.]* * |sort -rn |head -11"
alias df="df -h"
alias lsm='mount | grep -E ^/dev | column -t'
alias dropcaches="echo 3 | sudo tee /proc/sys/vm/drop_caches &> /dev/null"

# network
alias lsn="sudo ss -lpnt |column -t"

# package managment
case $ID in
  ubuntu|debian|raspbian)
    alias upd="sudo apt update && apt list --upgradable"
    alias updnow="sudo apt update && sudo apt upgrade -y"
    alias rpkg="sudo apt purge -y"
    alias gpkg="dpkg -l | grep -i"
    alias spkg="apt-cache search -qq"
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
    ipkg () {
      sudo apt install -y "./${1}"
    }
    ;;

  fedora|centos)
    alias upd="sudo dnf check-update --refresh --assumeno"
    alias updnow="sudo dnf update --assumeyes"
    alias rpkg="sudo dnf remove --assumeyes"
    alias gpkg="rpm -qa | grep -i"
    alias spkg="dnf search"
    cleanpm () {
      echo 'remove orphans'
      sudo dnf autoremove -y
      echo 'clean dnf/rpmdb, remove cached packages'
      sudo dnf clean all
    }
    ipkg () {
      sudo dnf install -y "./${1}"
    }
    ;;

  alpine)
    alias upd="sudo apk update && echo 'UPGRADABLE :' && sudo apk upgrade -s"
    alias updnow="sudo apk update && sudo apk upgrade"
    alias rpkg="sudo apk del"
    alias gpkg="apk list -I | grep -i"
    alias spkg="apk search"
    alias cleanpm="sudo apk -v cache clean"
    ;;

  *)
    echo 'package manager aliases not found, system unsupported ?'
    ;;
esac

# systemd
if [ "$(cat /proc/1/comm)" = 'systemd' ]; then
  alias status="systemctl status"
  alias sctl="sudo systemctl"
  alias j="sudo journalctl --since '7 days ago'"
  alias jf="sudo journalctl -f"
  alias jg="sudo journalctl --since '7 days ago' --no-pager | grep"
fi

health() {
  local systemd_status
  local systemd_live_ver
  local systemd_pkg_ver
  local kernel_live_ver
  local kernel_pkg_ver
  local distribution

  if [ -f '/etc/os-release' ]; then
    distribution="$(
      grep '^ID=.*$' '/etc/os-release' \
      | tr -d '"' \
      | cut -f 2 -d'=')"
  else
    distribution=''
  fi

  # return status health for systemd, show failed units if system isn't healthy
  if [ "$(cat /proc/1/comm)" = 'systemd' ]; then

    systemd_status="$(sudo systemctl is-system-running | tr -d '\n')"
    case "${systemd_status}" in
      running)
        echo -e '\e[32m●\e[0m system running' # green circle
      ;;
      starting)
        # shellcheck disable=SC2039
        echo -e '\e[32m↑\e[0m System currently booting up' # green up arrow
      ;;
      stopping)
        # shellcheck disable=SC2039
        echo -e '\e[34m↓\e[0m µSystem shuting down' # blue down arrow
      ;;
      degraded)
        # shellcheck disable=SC2039
        echo -e '\e[33m⚑\e[0m System in degraded mode:' # orange flag
        # is in failed state
        sudo systemctl --failed
      ;;
      maintenance)
        # shellcheck disable=SC2039
        echo -e '\e[5m\e[31mx\e[0m System currently in maintenance' # blk red
      ;;
      *)
        # shellcheck disable=SC2039
        echo -e '\e[31m⚑\e[0m Unexpected state !' # red flag
      ;;
    esac

  # is the running systemd process uses the last version available ?
    systemd_live_ver="$(systemctl --version | grep '^systemd' | cut -d' ' -f2)"
    case "${distribution}" in
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
  fi

  # querying the current kernel version used and fetch the last available one
  # message the user if a newer version is available
  kernel_live_ver="$(uname -r)"
  case $ID in
    ubuntu)
      local KERNEL_FLAVOR
      if [ "$(uname -r | cut -d'-' -f3)" = 'raspi2' ]; then
        # raspberry pi flavor of ubuntu is not using generic kernel
        KERNEL_FLAVOR=raspi2
      else
        KERNEL_FLAVOR=generic
      fi
      kernel_live_ver="$(uname -r | cut -d'-' -f1-2 | tr '-' '.')"
      kernel_pkg_ver="$(
        dpkg -s linux-${KERNEL_FLAVOR} \
        | grep '^Version\:\s.*$' \
        | cut -d' ' -f2 \
        | cut -d'.' -f-4)"
      ;;
    debian)
      kernel_live_ver="$(uname -r)"
      kernel_pkg_ver="$(\
        dpkg -s linux-image-amd64 \
        | grep '^Depends\:' \
        | cut -d' ' -f2 \
        | sed 's/^[a-zA-Z\-]*//'
        )"
      ;;
    raspbian)
      kernel_pkg_ver="$(
        for VER in /lib/modules/*; do
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

  # message the user
  if [ "${systemd_live_ver}" != "${systemd_pkg_ver}" ]; then
    echo -e '\e[34m♻\e[0m systemd needs to be recycled'
  fi
  if [ "${kernel_live_ver}" != "${kernel_pkg_ver}" ]; then
    echo -e '\e[33m↻\e[0m system needs to be rebooted, a new kernel' \
      'is available'
  fi
}

# pager or mod of aliases using a pager. Using most, color friendly
if command -v most &> /dev/null; then
  alias ltree="tree -a --prune --noreport -h -C -I '*.git' | most"
  alias man='man --pager=most --no-hyphenation --no-justification'
fi

# python
if command -v python &> /dev/null; then
  if command -v ipython &> /dev/null; then
    alias ipy=ipython
  fi
  venv() {
    # spawn a virtual python env with a given name, usualy a package name.
    # usage: venv package
    local PKG
    PKG="${1}"
    if [ "x${VIRTUAL_ENV}" != "x" ]; then
      deactivate
      return
    fi

    # setup a new virtual env if it doesn't exists, and activate it
    if ! [ -d "${HOME}/.venv/${PKG}" ]; then
      python3 -m venv "${HOME}/.venv/${PKG}"
    fi
    . "${HOME}/.venv/${PKG}/bin/activate"
  }
fi

# docker
if command -v docker &> /dev/null; then
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

if command -v docker-compose &> /dev/null; then
  alias dkc="docker-compose"
  alias dkcu="docker-compose up -d"
  alias dkcd="docker-compose down"
fi

# LXC
if command -v lxc &> /dev/null; then
  # go in a container, do some test, leave. stop and destroy it automatically
  lxcspawn() {
    # usage : lxcspawn image_name shell_name
    # shell is opt, default to bash
    local IMAGE
    local SHELL
    local CNT_NAME
    IMAGE="${1}"
    SHELL="${2:-bash}"
    CNT_NAME=$(head /dev/urandom | tr -dc '[:lower:]' | head -c 12 ; echo '')
    if [ "x${IMAGE}" = "x" ]; then # no image given
      lxc image list images: --columns ldu # show list of available ones
      return 0
    fi
    lxc launch "images:${IMAGE}" "$CNT_NAME"
    lxc exec "$CNT_NAME" "${SHELL}"
    lxc stop "$CNT_NAME"
    lxc delete "$CNT_NAME"
  }
fi

# MicroK8s
if command -v microk8s.status &> /dev/null; then
  alias m.enable="microk8s.enable"
  alias m.disable="microk8s.disable"
  alias m.start="microk8s.start"
  alias m.stop="microk8s.stop"
  alias m.status="microk8s.status"

  # common kube shortcuts if original tools doesn't exists already
  if ! command -v kubectl &> /dev/null; then
    alias kubectl="microk8s.kubectl"
    alias k="microk8s.kubectl"
    if microk8s.status &> /dev/null &&\
      (grep "${USER}" /etc/group | grep -q microk8s || [ "${USER}" = "root" ]);
    then
      source <(microk8s.kubectl completion bash)
      source <(microk8s.kubectl completion bash | sed 's/kubectl/k/g')
    fi
  fi
  if ! command -v helm &> /dev/null; then
    alias helm="microk8s.helm"
  fi
fi

# lazygit
if command -v lazygit &> /dev/null; then
  alias lgt=lazygit
fi

# vagrant
if command -v vagrant &> /dev/null; then

  # use libvirt instead of default virtualbox : better perfs, less oracle stuff
  export VAGRANT_DEFAULT_PROVIDER=libvirt

  vagrant_rsync() {
    # replace vagrant-scp, basicly a fancy wrapper around '-e "ssh -F ${CONF}"'
    # usage : use it like rsync
    if [ $# -lt 2 ]; then
      rsync --help
      return 1
    else
      local UUID
      local CONF
      UUID=$(cat /proc/sys/kernel/random/uuid)
      CONF="/tmp/vagrant_ssh-config.${UUID}"
      vagrant ssh-config > "${CONF}" &&\
      rsync -e "ssh -F ${CONF}" "${@}"
      rm -f "${CONF}"
    fi
  }

  vmspawn() {
    # go in a VM, do some test, leave. stop and destroy it automatically
    # usage : vmspan image_name
    # lookup names at https://app.vagrantup.com/boxes/search
    local CWD
    local IMAGE
    local PROVIDER
    local UUID
    local TMP_DIR
    local VENDOR
    local BOX
    local BOX_URL
    local VERSION
    local BOX_FILE_URL
    CWD="${PWD}"
    IMAGE="${1:?'no image name given'}"
    VERSION="${2}"
    PROVIDER="${VAGRANT_DEFAULT_PROVIDER:-virtualbox}"
    UUID=$(cat /proc/sys/kernel/random/uuid)
    TMP_DIR="/tmp/vmspan.${UUID}"

    if ! echo "${IMAGE}" | grep -Eq '^[a-Z0-9]+/[a-Z0-9\.\-\_]+$'; then
      echo 'wrong image name'
      return 1
    fi

    if [ "x${VERISON}" != "x" ] &&\
      ! echo "${VERSION}" | grep -Eq '^[0-9\.]+$'; then
      echo 'wrong version given'
      return 1
    fi

    VENDOR="${IMAGE%/*}"
    BOX="${IMAGE#*/}"
    BOX_URL="https://app.vagrantup.com/${VENDOR}/boxes/${BOX}"

    # check ressource availability
    if ! [ "$(curl --silent --head --location \
        --write-out '%{response_code}' --output /dev/null \
        "${BOX_URL}")" -eq "200" ]; then
      echo "image not found, check connectivity or given box name"
      return 1
    fi

    # fetch latest version of given box
    if [ "x${VERSION}" = "x" ]; then
      VERSION="$(
        curl --location "https://vagrantcloud.com/${IMAGE}" --silent \
        | jq .versions[0].version | tr -d '"'
      )"
    fi
    BOX_FILE_URL="${BOX_URL}/versions/${VERSION}/providers/${PROVIDER}.box"

    # check box availability
    if [ "$(curl --silent --head --location \
        --write-out '%{response_code}' --output /dev/null \
        "${BOX_FILE_URL}")" -ne "200" ]; then
      echo "box exists but provider and/or version not available. "
      return 1
    fi

    # download vagrant image unconditionally if it doesn't exists locally
    if vagrant box list \
        | grep --extended-regexp --silent \
          "^${IMAGE}\\s+\\(${PROVIDER},\\s${VERSION})$"; then
      true
    else
      echo "box not available localy or is out of date, fetching.."
      until vagrant box add "${IMAGE}" \
        --provider ${PROVIDER}\
        --box-version "${VERSION}"; do
        sleep "$(shuf --input-range=20-40 --head-count=1)"
      done
    fi

    # build a temporary folder to serve as working directory
    if mkdir "${TMP_DIR}"; then
      cd "${TMP_DIR}" || return 1
    else
      return 1
    fi

    # build Vagrantfile
    vagrant init --minimal "${IMAGE}" \
    --box-version "${VERSION}" \
    --output "${TMP_DIR}/Vagrantfile"

    # start vagrant
    vagrant up
    vagrant ssh
    vagrant destroy -f
    cd "${CWD}" || cd "${HOME}" || return 1
    rm -rf "${TMP_DIR}"
  }
fi

# download a file using wget and auto resume if failing
download () {
  local DEST
  command -v xdg-user-dir &> /dev/null &&\
    DEST="$(xdg-user-dir DOWNLOAD)"
  DEST="${DEST:=~/}"
  if [ -d "${DEST}" ] &&\
     [ "$(curl -XGET -IsLw '%{response_code}' -o /dev/null "${@}")" -eq '200' ];
  then
    until wget \
      --continue --random-wait --directory-prefix="${DEST}" \
      --progress=bar:scroll --no-verbose --show-progress "${@}"; do
      true;
    done
    sync
  else
    return 1
  fi
}

# protonvpn
if command -v protonvpn &> /dev/null; then
  alias pvpn=protonvpn
fi

# misc
alias h="history | tail -20"
alias gh='history | grep'
alias vless="vim -M"
alias seeconf="grep -Ev '(^$)|(^#.*$)|(^;.*$)'"
alias datei="date --iso-8601=m"
alias wt="curl wttr.in/?format='+%c%20+%t'" # what's the weather like
alias wth="curl wttr.in/?qF1n" # what's the next couple of hours will look like
alias wtth="curl wttr.in/?qF3n" # 3 days forcast
alias bt='bluetoothctl'

d () { # a couple of city I like to know the time of
  local EMPH
  local RST
  for LOC in Asia/Tokyo       \
             Asia/Shanghai    \
             Europe/Bucharest \
             Europe/Paris     \
             UTC              \
             America/Montreal \
             America/Los_Angeles; do
    if { [ -f '/etc/timezone' ] && [ "$(cat /etc/timezone)" = "$LOC" ]; } || \
       { [ -L '/etc/localtime' ] &&\
        [ "$(readlink /etc/localtime | sed 's%../usr/share/zoneinfo/%%')" \
        = "$LOC" ]; }; then
      EMPH='\e[36m'
      RST='\e[0m'
    else
      unset EMPH
      unset RST
    fi
    echo -ne "${LOC##*/}:%" | tr '_' ' ' ;
    echo -ne "${EMPH}";
    TZ=${LOC} date '+%R - %d %B %:::z %Z' | tr -d '\n'; echo -e "${RST}"
  done | column -t -s '%'
}

wof () {
  # write on file ..
  # usage : wof file.iso /dev/usbthing
  sudo dd if="${1}" of="${2}" bs=32M status=progress
  sync
}

# --- PS1

# colors
_CC_dark_grey='\[\e[2;2m\]'
_CC_cyan='\[\e[0;36m\]'
_CC_orange='\[\e[0;33m\]'
_CC_reset='\[\e[0m\]'

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

  # - show various icons for systemd system's status, along with description
  # https://www.freedesktop.org/software/systemd/man/systemctl.html#is-system-running
  # skipped shellcheck rules : usually systems with systemd run with bash
  _SCSDST () {
    systemctl is-system-running &> /dev/null \
    || echo -ne '\e[33m●\e[0m '
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)'
fi

# exit status in red if != 0
_SCES () {
  if [ "${1}" -ne 0 ]; then
    # shellcheck disable=SC2016
    echo -ne '\e[31m'"${1}"'\e[0m'
  else
    echo -ne '\e[2m'"${1}"'\e[0m'
  fi
}
# shellcheck disable=SC2016
_SCESS='$(_SCES $?)'

# show temperature of a physical system
if ! lscpu | grep -q Hypervisor &&\
   [ -f '/sys/class/thermal/thermal_zone0/temp' ]; then
  # shellcheck disable=SC2016
  _SCTMP='$(($(</sys/class/thermal/thermal_zone0/temp)/1000))°'
fi

# load average
_SCLDAVGF () {
  local LDAVG
  local NLOAD
  local NBPROC
  # shellcheck disable=SC2016
  LDAVG="$(echo -n "$(cut -d" " -f1-3 /proc/loadavg)")"
  if ! command -v protonvpn &> /dev/null; then
    FACTOR=0 # no color if I cannot compute load per cores
  else
    NBPROC="$(nproc)"
    NLOAD="$(cut -f1 -d' ' /proc/loadavg | tr -d '.')"
    NLOADNRM="$(sed 's/^0*//' <<< "$NLOAD")"
    if [ -z "${NLOADNRM}" ]; then
      NLOADNRM=0
    fi
    FACTOR="$((NLOADNRM/NBPROC))"
  fi

  if [ "${FACTOR}" -ge 200 ]; then
    echo -ne '\e[31m'"${LDAVG}"
    # return
  elif [[ "${FACTOR}" -ge 100 ]]; then
    echo -ne '\e[33m'"${LDAVG}"
    # return
  elif [[ "${FACTOR}" -ge 50 ]]; then
    echo -ne '\e[32m'"${LDAVG}"
    # return
  else
    echo -n "${LDAVG}"
  fi
}
# shellcheck disable=SC2016
_SCLDAVG='[$(_SCLDAVGF)'$_CC_reset$_CC_dark_grey']'

# use red if root, green otherwise
_CC_user='\[\e[0;'"$([ "${USER}" = "root" ] && echo "31" || echo '32')"'m\]'

# blocks definition for ps1
PS_DATE=$_CC_dark_grey'\t '$_CC_reset
PS_LOCATION=$_CC_user'\u'$_CC_reset'@'$_CC_cyan'\h'$_CC_reset
PS_DIR=$_CC_dark_grey' \W'$_CC_reset
PS_GIT=$_CC_orange$_SCPS1GIT$_CC_reset
PS_ST=$_SCESS
PS_LOAD=$_CC_dark_grey$_SCLDAVG$_CC_reset
PS_SCTMP=$_CC_dark_grey$_SCTMP$_CC_reset
PS_SYSDS=$_CC_dark_grey$_SCSDSTS$_CC_reset

if env | grep -Eq "^SSH_CONNECTION=.*$"; then
  # you're not home, be careful - root may be standard, you're on your own!
  PS_PROMPT=$_CC_orange'\n→  '$_CC_reset
else
  PS_PROMPT='\n→  '
fi

# PS1/2 definition
PS_LOC_BLOCK='['$PS_LOCATION$PS_DIR$PS_GIT'] '
PS_EXTRA_BLOCK=$PS_ST' '$PS_LOAD' '$PS_SCTMP' '
PS_SYSD_BLOCK=$PS_SYSDS

# only tested with bash and ash ATM
if [ -z "${0##*bash}" ] || [ -z "${0##*ash}" ] ; then
  PS1=$PS_DATE$PS_LOC_BLOCK$PS_EXTRA_BLOCK$PS_SYSD_BLOCK$PS_PROMPT
  PS2='…  '
fi

# --- include extra config files :
# - ~/.offline.sh: for local configs (machine dependent)
# - ~/.online.sh:  cross-system sharing configs (bluetooth, lan dependend, etc)
for INCLUDE in ~/.local.sh ~/.offline.sh; do
  if [ -f "${INCLUDE}" ]; then
    # shellcheck source=/dev/null
    . "${INCLUDE}"
  fi
done

# --- TMUX : disable this using "export TMUX=disable" before loading shellconfig
if command -v tmux &> /dev/null &&\
   [ -z "$TMUX" ] &&\
   [ -z "$SUDO_USER" ]; then
  tmux attach -t default 2> /dev/null || tmux new -s default
  exit
fi
