#!/bin/bash

# --- SHELL CONFIG

# avoid sourcing if non interactive
case $- in
 *i*) ;;
 *) return;;
esac

# shell options
shopt -s histappend # parallel history
history -a # parallel history
shopt -s checkwinsize # resize window
shopt -s autocd # go in a directory without cd
shopt -s histverify # put a caled historized command in readline

# umask: others should not have default read and execute options
umask 027

# source profile.d items
if ls /etc/profile.d/*.sh > /dev/null 2>&1; then
  for SRC_PROFILE in /etc/profile.d/*.sh; do
    # shellcheck source=/dev/null
    . "${SRC_PROFILE}"
  done
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

# source distrib information; will use 'ID' variable
# shellcheck source=/etc/os-release
if [ -f '/etc/os-release' ]; then
  source '/etc/os-release'
fi

# standard aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# files managment
if command -v exa &> /dev/null; then
  alias ls='exa'
  alias l='exa --classify --group-directories-first'
  alias ll='exa -l --classify --group-directories-first --git'
  alias la='exa -l --classify --group-directories-first --all --git'
  alias lll='exa -l --classify --group-directories-first --git --links --inode --blocks --extended'
  alias lla='exa -l --classify --group-directories-first --git --links --inode --blocks --extended --all'
  alias lt='exa -l --git --links --inode --blocks --extended --all --sort date'
elif ! [ -L "/bin/ls" ]; then
  alias lz='command ls -g --classify --group-directories-first --context --no-group --all'
  alias l='ls -C --classify --group-directories-first'
  alias ll='ls -l --classify --group-directories-first --human-readable'
  alias la='ls -l --classify --group-directories-first --human-readable --all'
  alias lll='ls -l --classify --group-directories-first --human-readable --context  --author'
  alias lla='ls -l --classify --group-directories-first --human-readable --context  --author --all'
  alias lt='ls -gt --classify --reverse --human-readable --all --no-group'
else # if ls is a link, it's probably busybox
  alias l='ls -C --group-directories-first'
  alias ll='ls -l --group-directories-first -h'
  alias la='ls -l --group-directories-first -h -a'
  alias lt='ls -gt -r -h -a'
fi

alias vd="diff --side-by-side --suppress-common-lines"
alias send="rsync --archive --info=progress2 --human-readable --compress"
alias hl="grep -izF" # highlight
alias hlr="grep -iFR" # recursive highlight (not full but ref/numbers avail.)

# shellcheck disable=SC2139
alias e="${EDITOR}"
alias co="codium -ra ."

# open, using desktop stuff
if command -v xdg-open &> /dev/null; then
  alias open="xdg-open"
else
  alias open=vless
fi

# safe rm
alias rm="rm -i"

# compress, decompress
alias cpx="tar -capvf" # cpx archname.tar.xz dir
alias dpx="tar -xpvf" # dpx archname.tar.xz

# directory stack
if [ -z "${0##*bash}" ]; then
  alias lsd="dirs -v | grep -Ev '^ 0 .*$'" # list stack directory
  alias pdir="pushd ./ > /dev/null; lsd"
fi

if ! [ -L "$(command -v ps)" ]; then
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

# replace top for htop
if command -v htop &> /dev/null; then
  alias top='htop'
fi

if command -v gio &> /dev/null; then
  export ELECTRON_TRASH=gio # https://github.com/atom/atom/issues/17452
  alias tt="gio trash" # to trash : https://unix.stackexchange.com/a/445281
  alias et="gio trash --empty" # empty trash
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
      if command -v snap &> /dev/null; then
        sudo snap refresh
      fi
      if command -v flatpak &> /dev/null; then
        flatpak update -y
      fi
      sudo apt update &&\
      sudo apt upgrade -y

    }
    ipkg () { sudo apt install -y "./${1}"; }
    ;;

  fedora|centos|rocky)
    if command -v dnf &> /dev/null; then
      alias upd="sudo dnf check-update --refresh --assumeno"
      alias updl="dnf list --cacheonly --upgrades --assumeno"
      alias rpkg="sudo dnf remove --assumeyes"
      alias spkg="dnf search"
      updnow () {
        if command -v snap &> /dev/null; then
          sudo snap refresh
        fi
        if command -v flatpak &> /dev/null; then
          flatpak update -y
        fi
        sudo dnf update --refresh --assumeyes
      }
      ipkg () { sudo dnf install -y "./${1}"; }
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
    # keeping this for flexibility
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

  # other aliases involving docker images
  alias mlt='docker run --rm -i -v "${PWD}:/srv:ro" -v "/etc:/etc:ro" registry.gitlab.com/replicajune/markdown-link-tester:latest'
  # build a container in a container and not exposing stuff
  alias kaniko='docker run --rm --workdir "/workspace" -v "${PWD}:/workspace:ro" --entrypoint "" gcr.io/kaniko-project/executor:debug /kaniko/executor --no-push --force'
  # auditor
  alias cinc-auditor='docker run --workdir "/srv" -v "${PWD}:/srv" --entrypoint "/opt/cinc-auditor/bin/cinc-auditor" cincproject/auditor:latest'
  alias auditor=cinc-auditor
  alias aud=auditor
  # doggo
  alias doggo='docker run --net=host -t ghcr.io/mr-karan/doggo:latest --color=true'
  alias dnc='doggo'
  # kamoulox..
  alias kamoulox='docker run jeanlaurent/kamoulox'
fi

if command -v docker-compose &> /dev/null; then
  alias dkc="docker-compose"
  alias dkcu="docker-compose up -d"
  alias dkcd="docker-compose down"
fi

# Kubernetes

kset (){
  # set completions and aliases for kubectl and helm "on demand"
  # Need to stay as a function as it's sourcing stuff and creating aliases
  # I bet kubectlx/kubens is much better but eh..

  local USAGE
  local KEY
  local VALUE
  local NAMESPACE
  local CLUSTER
  local COMPLETION
  local ARGUMENTS

  USAGE='
  usage : kset [OPTIONS]
    -c --cluster CLUSTER     : will source ~/.kubeconfig.CLUSTER.yml
    -n --namespace NAMESPACE : set given namespace option to kubectl
    -r --reset               : remove aliases
    -x --completion          : if other arguements are given, will also set auto
                              completion. If no other option are set, this
                              option is implied
  '

  while [ ${#} -gt 0 ]; do
    KEY="${1}"
    VALUE="${2}"
    case $KEY in
      -n|--namespace)
        NAMESPACE="${VALUE}"
        shift # past argument
      ;;
      -c|--cluster)
        CLUSTER="${VALUE}"
        shift # past argument
      ;;
      -x|--completion)
        COMPLETION='TRUE'
      ;;
      -r|--reset)
        echo "removing aliases"
        unalias k &> /dev/null || true
        unalias kubectl &> /dev/null || true
        return 0
      ;;
      -h|--help)
        echo "${USAGE}" | grep -Ev '^$' | sed 's/^  //'
        return 0
      ;;
      *)
        echo "${USAGE}" | grep -Ev '^$' | sed 's/^  //'
        return 0
      ;;
    esac
    shift
  done

  if [ -n "${CLUSTER}" ]; then
    ARGUMENTS="${ARGUMENTS} --kubeconfig ~/.kubeconfig.${CLUSTER}.yml"
  fi

  if [ -n "${NAMESPACE}" ]; then
    ARGUMENTS="${ARGUMENTS} --namespace ${NAMESPACE}"
  fi

  if { [ -z "${CLUSTER}" ] && [ -z "${CLUSTER}" ]; } \
  || [ "${COMPLETION}" = "TRUE" ]; then
    if command -v kubectl &> /dev/null; then
      echo "set kubectl completion for kubectl, k"
      source <(kubectl completion bash)
      source <(kubectl completion bash | sed 's/kubectl/k/g')
      echo "set k alias"
      alias k='kubectl'
    fi
    if command -v helm &> /dev/null; then
      echo "set helm completion"
      source <(helm completion bash)
    fi
  else
    if [ -n "${ARGUMENTS}" ]; then
      echo "define following arguments through kubectl alias:${ARGUMENTS}"
      # shellcheck disable=SC2139
      alias kubectl="kubectl ${ARGUMENTS}"
    fi
  fi
}

# git
if [ -f "/home/${SUDO_USER-$USER}/.git-prompt.sh" ]; then
  # shellcheck source=/dev/null
  . "/home/${SUDO_USER-$USER}/.git-prompt.sh"
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
      UUID="$(cat /proc/sys/kernel/random/uuid)"
      CONF="/tmp/vagrant_ssh-config.${UUID}"
      vagrant ssh-config > "${CONF}" &&\
      rsync -e "ssh -F ${CONF}" "${@}"
      rm -f "${CONF}"
    fi
  }
fi

# write on file .. usage : wof file.iso /dev/usbthing
wof () { sudo dd if="${1}" of="${2}" bs=32M status=progress; sync; }

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

# tmux
if command -v tmux &> /dev/null \
&& [ -S "$(echo "${TMUX}" | cut -f1 -d',')" ]; then
  alias recycle='tmux new-window; tmux last-window; tmux kill-window'
  alias tk='tmux kill-session'
  alias irc="tmux neww irssi"
  alias sst="tmux neww ssh"
  command -v lazygit &> /dev/null && alias lgt="tmux neww lazygit"
  if command -v htop &> /dev/null; then
    alias ttop="tmux neww htop"
  else
    alias ttop="tmux neww top"
  fi
  if command -v most &> /dev/null; then
    alias man='tmux neww man --pager=most --no-hyphenation --no-justification'
  else
    alias man='tmux neww man --no-hyphenation --no-justification'
  fi
fi

# misc
alias down="command wget --progress=bar:scroll --no-verbose --show-progress"
alias h="history | tail -20"
alias gh='history | grep'
# shellcheck disable=SC2142
alias ha="history | awk '{ print substr(\$0, index(\$0,\$4)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"
alias datei="date --iso-8601=m"
alias epoch="date +%s"
alias wt="curl wttr.in/?format='+%c%20+%f'; echo" # what's the weather like
alias wth="curl wttr.in/?qF1n" # what's the next couple of hours will look like
alias wtth="curl v2.wttr.in/" # 3 days forcast
alias bt='bluetoothctl'
alias nt="TMUX=disable gnome-terminal" # new terminal / no tmux
alias reload-bash=". ~/.bashrc"

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
    [ -z "${DBUS_SESSION_BUS_ADDRESS}" ] && return 0
    systemctl --user is-system-running &> /dev/null \
    || echo -ne '\e[35m●\e[0m '
  }
  # shellcheck disable=SC2016
  _SCSDSTS='$(_SCSDST)$(_SCSDSTU)'
fi

# exit status in red if != 0
# shellcheck disable=SC2016
_SCCLR () { if [ "${1}" -ne 0 ]; then echo -ne '\e[31m'; fi; }
_SCES () { echo "$(_SCCLR "${1}")${1}"; }

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
  PS_PROMPT=$_CC_orange'\n> '$_CC_reset
else
  PS_PROMPT='\n> '
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
# disable this last bit:
# - include "export TMUX=disable" before loading shellconfig
# - uninstall tmux
if command -v tmux &> /dev/null &&\
   [ -z "$TMUX" ] &&\
   [ -z "$SUDO_USER" ] &&\
   [ "x${TERM_PROGRAM}" != "xvscode" ] &&\
   [ "x${XDG_SESSION_TYPE}" != "xtty" ]; then
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
