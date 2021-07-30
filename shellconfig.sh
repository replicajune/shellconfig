#!/bin/sh

# --- SHELL CONFIG

# avoid sourcing if non interactive
case $- in
 *i*) ;;
 *) return;;
esac

# I have to assume the location of this directory as ${_HOME}/.shellconfig to
# help with needed modularity of files
_HOME="$(getent passwd "${SUDO_USER-$USER}" | cut -d: -f6)"
REPO_PATH="${_HOME}/.shellconfig"

case $(readlink /proc/${$}/exe) in
  *bash)
    . "${REPO_PATH}/shells/bash.sh"
    . "${REPO_PATH}/shells/extras.sh"
  ;;
  *busybox)
    . "${REPO_PATH}/shells/ash.sh"
  ;;
  *zsh)
    . "${REPO_PATH}/shells/zsh.sh"
    . "${REPO_PATH}/shells/extras.sh"
  ;;
  *)
    true
  ;;
esac

if command -v uname > /dev/null 2>&1; then
  case $(uname -s) in
    Linux)
    . "${REPO_PATH}/systems/linux.sh"
    ;;
  esac
fi

# umask: others should not have default read and execute options
umask 027

# source profile.d items
if ls /etc/profile.d/*.sh > /dev/null 2>&1; then
  for SRC_PROFILE in /etc/profile.d/*.sh; do
    # shellcheck source=/dev/null
    . "${SRC_PROFILE}"
  done
fi

# from rustup, since I also manage .profile, .bashrc in different repos
if [ -f "${_HOME}/.cargo/env" ]; then
  . "${_HOME}/.cargo/env"
fi

# --- ENVIRONMENTS VARIABLES

# user binaries in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH="${PATH}:/home/${SUDO_USER-$USER}/.local/bin"
fi

# "global" binaries in /opt/bin
if [ -n "${PATH##*/opt/bin*}" ]; then
  export PATH="${PATH}:/opt/bin"
fi

# brew is pushing a lot of stuff in /usr/local/bin so i have to find another
# location for my usr-local-bin repo (k3s also makes a bit of a mess)
if [ -n "${PATH##*/opt/local-bin*}" ]; then
  export PATH="${PATH}:/opt/local-bin"
fi

# use vim if possible, nano otherwise
if command -v vim > /dev/null 2>&1; then
  export VISUAL='vim'
  export EDITOR='vim'
  alias vless='vim -M'
else
  export VISUAL='nano'
  export EDITOR='nano'
  alias vless='nano --nohelp --view'
fi

# history with date, no size limit
history -a # parallel history
export HISTCONTROL=ignoreboth
export HISTSIZE='INF'
export HISTFILESIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

# automaric multithreading for xz (implicit for tar)
export XZ_DEFAULTS="-T 0"

# --- ALIASES & FUNCTIONS

# standard aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# rust alternative to cp, can do // and show progress bar by default
if command -v xcp > /dev/null 2>&1; then
  alias xcp="xcp -w 0"
  alias cpr="xcp -r"
fi

# rust alternative to cat, colors by default
if command -v bat > /dev/null 2>&1; then
  alias rcat="bat --theme Nord --pager=never --style=numbers"
fi

alias send="rsync --archive --info=progress2 --human-readable --compress"
alias hl="grep -izF" # highlight
alias hlr="grep -iFR" # recursive highlight (not full but ref/numbers avail.)
alias tmpcd='cd "$(mktemp -d)"'

# shellcheck disable=SC2139
alias e="${EDITOR}"
alias co="codium -a ."

# open, using desktop stuff
if command -v xdg-open > /dev/null 2>&1; then
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

alias df="df -h"

# replace top for htop
if command -v htop > /dev/null 2>&1; then
  alias top='htop'
fi

if command -v gio > /dev/null 2>&1; then
  export ELECTRON_TRASH=gio # https://github.com/atom/atom/issues/17452
  alias tt="gio trash" # to trash : https://unix.stackexchange.com/a/445281
  alias et="gio trash --empty" # empty trash
fi

# pager or mod of aliases using a pager. Using most if possible, color friendly
if command -v most > /dev/null 2>&1; then
  alias ltree="tree -a --prune --noreport -h -C -I '*.git' | most"
  alias man='man --pager=most --no-hyphenation --no-justification'
fi

# python
if command -v python > /dev/null 2>&1 || command -v python3 > /dev/null 2>&1; then
  venv() {
    # spawn a virtual python env with a given name, usualy a package name.
    # usage: venv package
    venv_PKG
    venv_PKG="${1}"
    if [ "x${VIRTUAL_ENV}" != "x" ]; then
      deactivate
      return
    fi

    # setup a new virtual env if it doesn't exists, and activate it
    if ! [ -d "${HOME}/.venv/${venv_PKG}" ]; then
      python3 -m venv "${HOME}/.venv/${venv_PKG}"
    fi
    . "${HOME}/.venv/${venv_PKG}/bin/activate"
  }
fi

if command -v openstack > /dev/null 2>&1; then
  alias oc=openstack
fi

if command -v terraform > /dev/null 2>&1; then
  alias tf=terraform
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
        unalias k > /dev/null 2>&1 || true
        unalias kubectl > /dev/null 2>&1 || true
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
    if command -v kubectl > /dev/null 2>&1; then
      echo "set kubectl completion for kubectl, k"
      source <(kubectl completion bash)
      source <(kubectl completion bash | sed 's/kubectl/k/g')
      echo "set k alias"
      alias k='kubectl'
    fi
    if command -v helm > /dev/null 2>&1; then
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
if [ -f "${_HOME}/.git-prompt.sh" ]; then
  # shellcheck source=/dev/null
  . "${_HOME}/.git-prompt.sh"
fi

# lazygit
if command -v lazygit > /dev/null 2>&1; then
  alias lgt=lazygit
  alias gc="git global-status commit" # see https://gitlab.com/replicajune/usr-local-bin/-/blob/main/git-global-status
fi

# vagrant
if command -v vagrant > /dev/null 2>&1; then

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
if command -v tmux > /dev/null 2>&1 \
&& [ -S "$(echo "${TMUX}" | cut -f1 -d',')" ]; then
  alias recycle='tmux new-window; tmux last-window; tmux kill-window'
  alias tk='tmux kill-session' # terminal kill
  alias wk='tmux kill-window' # window kill
  alias irc="tmux neww irssi"
  alias sst="tmux neww ssh"
  command -v lazygit > /dev/null 2>&1 && alias lgt="tmux neww lazygit"
  if command -v ytop > /dev/null 2>&1; then
    if [ -d "/sys/class/power_supply/BAT0" ]; then
      alias ttop="tmux neww ytop -b"
    else
      alias ttop="tmux neww ytop"
    fi
  elif command -v htop > /dev/null 2>&1; then
    alias ttop="tmux neww htop"
  else
    alias ttop="tmux neww top"
  fi
  if command -v most > /dev/null 2>&1; then
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
if [ -r "${_HOME}/.dir_colors" ] \
&& command -v dircolors > /dev/null 2>&1; then
  eval "$(dircolors "${_HOME}/.dir_colors")"
fi

# --- TMUX
# disable this last bit:
# - include "export TMUX=disable" before loading shellconfig
# - uninstall tmux
if command -v tmux > /dev/null 2>&1 &&\
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