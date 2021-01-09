#!/bin/bash

# source distrib information; will use 'ID' variable
# shellcheck source=/etc/os-release
if [ -f '/etc/os-release' ]; then
  source '/etc/os-release'
fi

# --- ENVIRONMENTS VARIABLES

# user binaries in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.local/bin
fi

# "global" binaries in /opt/bin
if [ -n "${PATH##*/opt/bin*}" ]; then
  export PATH=$PATH:/opt/bin
fi

# user default python virtual env in ~/.venv/global
if [ -n "${PATH##*/.venv/global/bin*}" ]; then
  export PATH=$PATH:/home/${SUDO_USER-$USER}/.venv/global/bin
fi

# use vim if possible, nano otherwise
if command -v vim &> /dev/null; then
  export VISUAL='vim'
  export EDITOR='vim'
  alias vless='vim -M'
else
  export VISUAL='nano'
  export EDITOR='nano'
  alias vless='nano --nohelp --view'
fi

# history with date, no size limit
export HISTCONTROL=ignoreboth
export HISTSIZE='INF'
export HISTFILESIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

# automaric multithreading for xz (implicit for tar)
export XZ_DEFAULTS="-T 0"

# --- ALIASES & FUNCTIONS

# files managment
if command -v exa &> /dev/null; then
  alias ls='exa'
  alias l='exa --classify --group-directories-first'
  alias ll='exa -l --classify --group-directories-first --git'
  alias la='exa -l --classify --group-directories-first --all --git'
  alias lll='exa -l --classify --group-directories-first --git --links --inode --blocks --extended'
  alias lla='exa -l --classify --group-directories-first --git --links --inode --blocks --extended --all'
  alias lt='exa -l --git --links --inode --blocks --extended --all --sort date'
else
  alias l='ls -C --classify --group-directories-first'
  alias ll='ls -l --classify --group-directories-first --human-readable'
  alias la='ls -l --classify --group-directories-first --human-readable --all'
  alias lll='ls -l --classify --group-directories-first --human-readable --context  --author'
  alias lla='ls -l --classify --group-directories-first --human-readable --context  --author --all'
  alias lt='ls -gt --classify --reverse --human-readable --all --no-group'
fi

alias lz='command ls -g --classify --group-directories-first --context --no-group --all'

alias vd="diff --side-by-side --suppress-common-lines"
alias send="rsync --archive --info=progress2 --human-readable --compress"
alias hl="grep -izF" # highlight
alias hlr="grep -iFR" # recursive highlight (not full but ref/numbers avail.)
# shellcheck disable=SC2139
alias e="${EDITOR}"

# safe rm
if [ -z "${XDG_CURRENT_DESKTOP##*GNOME*}" ]; then
  alias rm='gio trash'
else
  alias rm="rm -i"
fi

# compress, decompress
alias cpx="tar -capfv" # cpx archname.tar.xz dir
alias dpx="tar -xpfv" # dpx archname.tar.xz

if [ "x${ID}" != 'xalpine' ]; then
  # directory stack
  alias lsd="dirs -v" # list stack directory
  alias pdir="pushd ./ > /dev/null; dirs -v"

  # ressources; regular systems
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
alias topd='sudo sh -c "du -shc .[!.]* * |sort -rh |head -11" 2> /dev/null'
alias df="df -h"
alias lsm='mount | grep -E ^/dev | column -t'
alias dropcaches="echo 3 | sudo tee /proc/sys/vm/drop_caches &> /dev/null"

# replace top for htop
if command -v htop &> /dev/null; then
  alias top='htop'
fi

if command -v gio &> /dev/null; then
  export ELECTRON_TRASH=gio # https://github.com/atom/atom/issues/17452
  alias tt="gio trash" # to trash : https://unix.stackexchange.com/a/445281
fi

# network
lsn () {
  case "${1}" in
    4)
      sudo ss -lpntu4 |column -t
    ;;
    6)
      sudo ss -lpntu6 |column -t
    ;;
    t)
      sudo ss -lpnt |column -t
    ;;
    t4)
      sudo ss -lpnt4 |column -t
    ;;
    t6)
      sudo ss -lpnt6 |column -t
    ;;
    u)
      sudo ss -lpnu |column -t
    ;;
    u4)
      sudo ss -lpnu4 |column -t
    ;;
    u6)
      sudo ss -lpnu6 |column -t
    ;;
    *)
      sudo ss -lpntu |column -t
    ;;
  esac
}

# protonvpn
if command -v protonvpn &> /dev/null; then
  # protonvpn required to be run as root most of the time but is installed
  # in a user homefolder (through a global venv). calling an non PATHed bin
  # fails so I need another strategy.
  PVPN="$(whereis -b protonvpn | head -1 | cut -f2 -d" ")"
  if [ -x "${PVPN}" ]; then
    # shellcheck disable=SC2139
    alias protonvpn="sudo ${PVPN}"
    # shellcheck disable=SC2139
    alias pvpn="sudo ${PVPN}"
  fi
fi


# virt type of host
vtype () {
  # will give yout the type of node you're on
  _vtype=$(lscpu | grep "^Hypervisor vendor" |cut -d':' -f2 | sed "s/\s*//")
  [ -z "${_vtype}" ] && echo "none" || echo "${_vtype}"
}

# package managment
case "${ID}" in
  ubuntu|debian|raspbian)
    alias upd="sudo apt update && apt list --upgradable"
    alias updl="apt list --upgradable"
    alias rpkg="sudo apt purge -y"
    alias gpkg="dpkg -l | grep -i"
    alias spkg="apt-cache search -qq"
    updnow () {
      sudo apt update &&\
      sudo apt upgrade -y
      if command -v snap &> /dev/null; then
        sudo snap refresh
      fi
    }
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
    if command -v dnf &> /dev/null; then
      alias upd="sudo dnf check-update --refresh --assumeno"
      alias updl="dnf list --cacheonly --upgrades --assumeno"
      alias rpkg="sudo dnf remove --assumeyes"
      alias spkg="dnf search"
      updnow () {
        sudo dnf update --refresh --assumeyes
        if command -v snap &> /dev/null; then
          sudo snap refresh
        fi
      }
      cleanpm () {
        echo 'remove orphans'
        sudo dnf remove -y &> /dev/null
        echo 'remove older kernel packages'
        sudo dnf remove -y \
          "$(dnf repoquery --installonly --latest-limit=-2 -q)" &> /dev/null
        echo 'clean dnf/rpmdb, remove cached packages'
        sudo dnf clean all &> /dev/null
      }
      ipkg () {
        sudo dnf install -y "./${1}"
      }
    fi
    alias gpkg="rpm -qa | grep -i"
    ;;

  alpine)
    alias upd="sudo apk update && echo 'UPGRADABLE :' && sudo apk upgrade -s"
    alias updl="sudo apk upgrade -s"
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
  alias ctl="systemctl --user"
  alias j="sudo journalctl --since '7 days ago'"
  alias jf="sudo journalctl -f"
  alias jg="sudo journalctl --since '7 days ago' --no-pager | grep"
  health() {
    local SCTL
    if [ "${1}" = "u" ]; then
      SCTL="systemctl --user"
    else
      SCTL="sudo systemctl"
    fi
    # return status health for systemd, show failed units if system isn't healthy
    case "$(${SCTL} is-system-running | tr -d '\n')" in
      running)
        echo -e '\e[32m●\e[0m system running' # green circle
      ;;
      starting)
        echo -e '\e[32m↑\e[0m System currently booting up' # green up arrow
      ;;
      stopping)
        echo -e '\e[34m↓\e[0m µSystem shuting down' # blue down arrow
      ;;
      degraded)
        echo -e '\e[33m⚑\e[0m System in degraded mode:' # orange flag
        # is in failed state
        ${SCTL} --failed
      ;;
      maintenance)
        echo -e '\e[5m\e[31mx\e[0m System currently in maintenance' # blk red
      ;;
      *)
        echo -e '\e[31m⚑\e[0m Unexpected state !' # red flag
      ;;
    esac
  }
fi

# pager or mod of aliases using a pager. Using most if possible, color friendly
if command -v most &> /dev/null; then
  alias ltree="tree -a --prune --noreport -h -C -I '*.git' | most"
  alias man='man --pager=most --no-hyphenation --no-justification'
fi

# python
if command -v python &> /dev/null || command -v python3 &> /dev/null; then
  if command -v python3 &> /dev/null; then
    alias python='python3'
    alias pip='pip3'
  fi
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

if command -v openstack &> /dev/null; then
  alias oc=openstack
fi

if command -v terraform &> /dev/null; then
  alias tf=terraform
fi

# docker
if command -v podman &> /dev/null; then
  alias docker='podman'
fi

if (command -v docker &> /dev/null || command -v podman &> /dev/null); then
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

  # other aliases involving docker images
  alias mlt='docker run --rm -i -v "${PWD}:/srv:ro" -v "/etc:/etc:ro" registry.gitlab.com/replicajune/markdown-link-tester:latest'
  alias kaniko='docker run --rm --workdir "/workspace" -v "${PWD}:/workspace:ro" --entrypoint "" gcr.io/kaniko-project/executor:debug /kaniko/executor --no-push --force'
  if ! command -v shellcheck &> /dev/null; then
    alias shellcheck='docker run --rm -i -v "${PWD}:/mnt:ro" -v "/etc:/etc:ro" koalaman/shellcheck -x'
  fi
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

# kubectl, helm
kset () {
  # usage :
  # - kset : set completions and aliases for kubectl and helm
  # - kset $ARG : set kubeconfig value
  local _CLUSTER
  local _K_BASE_ARG
  _CLUSTER="${1}"
  _K_BASE_ARG="--kubeconfig ~/.kubeconfig.${_CLUSTER}.yml"

  if [ -z "${_CLUSTER}" ]; then
    if command -v kubectl &> /dev/null; then
      source <(kubectl completion bash)
      source <(kubectl completion bash | sed 's/kubectl/k/g')
      alias k='kubectl'
    fi
    if command -v helm &> /dev/null; then
      source <(helm completion bash)
    fi
  else
    #shellcheck disable=SC2139
    alias kubectl="kubectl ${_K_BASE_ARG}"
  fi
}

if command -v k3s &> /dev/null; then
  k3s.recycle () {
    # reset or install k3s
    [ "$(id -u)" != '0' ] || exit 1 # don't execute stuff as root
    { command -v k3s &> /dev/null && k3s-uninstall.sh; } || true # clean up
    curl -sfL https://get.k3s.io | sh - # re-install
    # backup an already existing config, in case..
    [ -f "${HOME}/.kube/config" ] && {
      mv "${HOME}/.kube/config" "${HOME}/.kube/config.$(date +%Y%m%d%H%M%S).backup"; }
    # import root config to user home - will override an existing config !!
    [ -f /etc/rancher/k3s/k3s.yaml ] && {
      sudo cp -f "/etc/rancher/k3s/k3s.yaml" "${HOME}/.kube/config";
      sudo chown "${USER}" "${HOME}/.kube/config"
    }
  }
fi

# git
alias g=git

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
      UUID="$(cat /proc/sys/kernel/random/uuid)"
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
    command rm -rf "${TMP_DIR}"
  }
fi

# download a file using wget and auto resume if failing
download () {
  local DEST
  command -v xdg-user-dir &> /dev/null &&\
    DEST="$(xdg-user-dir DOWNLOAD)"
  DEST="${DEST:=~/}"
  if [ "x${*}" != 'x' ] && [ -d "${DEST}" ] &&\
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

wof () {
  # write on file ..
  # usage : wof file.iso /dev/usbthing
  sudo dd if="${1}" of="${2}" bs=32M status=progress
  sync
}

udsk () {
  # unmount all filesystemes part of a block device (Unmount DiSK)
  local BLOCK_DEV
  BLOCK_DEV="${1?:'missing argument, please specify a block device'}"
  [ -b "${BLOCK_DEV}" ] || { echo 'argument is not a block device'; return 1; }
  echo 'unmount all filesystems mounted on specified block device'
  while IFS= read -r -d '' MOUNTED_FS; do
    sudo umount "${MOUNTED_FS}" || \
      { echo "error while unmounting ${MOUNTED_FS}"; return 1; }
  done  < <(lsblk "${BLOCK_DEV}" --output MOUNTPOINT \
            | grep -Eo '^/.*$' \
            | tr '\n' '\0')
}

terminate () {
  # cycle on pkill to make sure all process related to a command end.
  if [ "x$(pidof "${1}")" != "x" ]; then
    until ! pkill "${1}"; do
      sleep 2
    done
  else
    echo 'process given is not currently running'
  fi
}

# misc
alias h="history | tail -20"
alias gh='history | grep'
alias see="grep -Ev '(^$)|(^#\s.*$)|(^#$)|(^;.*$)|(^\s+#\s.*$)'"
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
             America/New_York \
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

# --- PS1

# colors
_CC_dark_grey='\[\e[2;2m\]'
_CC_cyan='\[\e[0;36m\]'
_CC_orange='\[\e[0;33m\]'
_CC_reset='\[\e[0m\]'

# is git installed ?
# type works on both bash and ash
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
  _SCSDSTU () {
    [ "${USER}" = "root" ] && return 0
    systemctl --user is-system-running &> /dev/null \
    || echo -ne '\e[35m●\e[0m '
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)$(_SCSDSTU)'
fi

# exit status in red if != 0
_SCCLR () {
  if [ "${1}" -ne 0 ]; then
    # shellcheck disable=SC2016
    echo -ne '\e[31m'
  fi
}
_SCES () {
  echo "$(_SCCLR "${1}")${1}"
}
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
  if ! command -v nproc &> /dev/null; then
    FACTOR=0 # no color if I cannot compute load per cores
  else
    NBPROC="$(nproc)"
    NLOAD="$(cut -f1 -d' ' /proc/loadavg | tr -d '.')"
    # complex regex required
    # shellcheck disable=SC2001
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
  # you're not home, be careful - root may be standard, you're on your own!
  PS_PROMPT=$_CC_orange'\n→  '$_CC_reset
else
  PS_PROMPT='\n→ '
fi

# PS1/2 definition
PS_LOC_BLOCK='['$PS_LOCATION$PS_DIR$PS_GIT'] '
PS_EXTRA_BLOCK=$PS_ST' '$PS_LOAD' '$PS_SCTMP
PS_SYSD_BLOCK=$PS_SYSDS

# only tested with bash and ash ATM
if [ -z "${0##*bash}" ] || [ -z "${0##*ash}" ] ; then
  PS1=$PS_DATE$PS_LOC_BLOCK$PS_EXTRA_BLOCK$PS_SYSD_BLOCK$PS_PROMPT
  PS2='…  '
fi

# --- EXTRA SOURCES

# Include extra config files :
# - ~/.online.sh:  cross-system sharing configs (bluetooth, lan dependend, etc)
# - ~/.offline.sh: for machine dependent configs or secrets (pass, tokens)
# - ~/.local.sh: for local configs worth an external sync
for INCLUDE in ~/.local.sh ~/.offline.sh ~/.online.sh; do
  if [ -f "${INCLUDE}" ]; then
    # shellcheck source=/dev/null
    . "${INCLUDE}"
  fi
done

# current imported .dircolors from https://www.nordtheme.com/docs/ports/dircolors/installation
if [ -r "${HOME}/.dir_colors" ] \
&& command -v dircolors &> /dev/null; then
  eval "$(dircolors "${HOME}/.dir_colors")"
fi

# --- TMUX

# disable:
# - include  "export TMUX=disable" before loading shellconfig
# uninstall tmux
if command -v tmux &> /dev/null &&\
   [ -z "$TMUX" ] &&\
   [ -z "$SUDO_USER" ] &&\
   [ "x${TERM_PROGRAM}" != "xvscode" ]; then
  tmux attach -t default 2> /dev/null || tmux new -s default
  exit
fi

# ---
# Shellcheck deactivations :
# - SC2139 / https://github.com/koalaman/shellcheck/wiki/SC2139
#   A variable need to be expended at sourcing. this check propose variables
#   to be escaped when it's not the expected behavior
# - SC2016 / https://github.com/koalaman/shellcheck/wiki/SC2016
#   I explicitly want to define a variable and use it as is to be processed
#   later and on in this shell config
# - SC2001 / https://github.com/koalaman/shellcheck/wiki/SC2001
#   Used pattern is not transposable in the form of ${variable//search/replace}
