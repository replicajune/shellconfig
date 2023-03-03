#!/usr/bin/env sh

# source profile.d items
if ls /etc/profile.d/*.sh > /dev/null 2>&1; then
  for SRC_PROFILE in /etc/profile.d/*.sh; do
    # shellcheck source=/dev/null
    . "${SRC_PROFILE}"
  done
fi

# user binaries in ~/.local/bin
if [ -n "${PATH##*/.local/bin*}" ]; then
  export PATH="${PATH}:/home/${SUDO_USER-$USER}/.local/bin"
fi

# history with date, no size limit
history -a # parallel history
export HISTCONTROL=ignoreboth
export HISTSIZE='INF'
export HISTFILESIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "
export PROMPT_COMMAND="history -a; history -c; history -r;"
alias h="history | tail -20"
alias gh='history | grep'
# shellcheck disable=SC2142
alias ha="history | awk '{ print substr(\$0, index(\$0,\$4)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"

# source distrib information
# shellcheck source=/etc/os-release
if [ -f '/etc/os-release' ]; then
  . '/etc/os-release'
  case "${ID_LIKE}" in
    *rhel*)
      . "${REPO_PATH}/systems/rhel.sh"
    ;;
    *debian*)
      . "${REPO_PATH}/systems/debian.sh"
    ;;
    *)
      true
    ;;
  esac

  case "${ID}" in
    ubuntu)
      . "${REPO_PATH}/systems/ubuntu.sh"
    ;;
    fedora)
      . "${REPO_PATH}/systems/rhel.sh"
    ;;
    opensuse-tumbleweed)
      . "${REPO_PATH}/systems/opensuse.sh"
    ;;
    alpine)
      . "${REPO_PATH}/systems/alpine.sh"
    ;;
    *)
      true
    ;;
  esac
fi

# systemd
if [ "$(cat /proc/1/comm)" = 'systemd' ]; then
  . "${REPO_PATH}/inits/systemd.sh"
fi

# standard aliases
if readlink -f /bin/ls | grep -q 'busybox'; then
  alias l='ls -C --group-directories-first'
  alias ll='ls -l --group-directories-first -h'
  alias la='ls -l --group-directories-first -h -a'
  alias lt='ls -gt -r -h -a'
else
  alias ls='ls --color=auto'
  alias l='ls -C --classify --group-directories-first'
  alias ll='ls -l --classify --group-directories-first --human-readable'
  alias la='ls -l --classify --group-directories-first --human-readable --all'
  alias lll='ls -l --inode --classify --group-directories-first --human-readable  --author'
  alias lla='ls -l --inode --classify --group-directories-first --human-readable  --author --all'
  alias lt='ls -gt --classify --reverse --human-readable --all --no-group'
fi

# file managment
alias hl="grep -izF" # highlight
alias hlr="grep -iFR" # recursive highlight (not full but ref/numbers avail.)

# write on file .. usage : wof file.iso /dev/usbthing
wof () { sudo dd if="${1}" of="${2}" bs=32M status=progress; sync; }

# misc
alias datei="date --iso-8601=m"


# extra utils
if command -v most > /dev/null 2>&1; then
  alias man='man --pager=most'
fi


# desktop stuff
export ELECTRON_TRASH=gio # https://github.com/atom/atom/issues/17452
alias tt="gio trash" # to trash : https://unix.stackexchange.com/a/445281
alias et="gio trash --empty" # empty trash

if command -v xdg-open > /dev/null 2>&1; then
  alias open="xdg-open"
else
  alias open=vless
fi

if command -v tmux > /dev/null 2>&1 \
&& [ -S "$(echo "${TMUX}" | cut -f1 -d',')" ]; then
  if command -v most > /dev/null 2>&1; then
    alias man='tmux neww man --pager=most --no-hyphenation --no-justification'
  else
    alias man='tmux neww man --no-hyphenation --no-justification'
  fi
fi

# virt type of host
vtype () {
  # will give yout the type of node you're on
  _vtype=$(lscpu | grep "^Hypervisor vendor" |cut -d':' -f2 | sed "s/\s*//")
  [ -z "${_vtype}" ] && echo "none" || echo "${_vtype}"
}

# DOCKER
# docker on other systems may work differently
if command -v podman > /dev/null 2>&1; then
  alias docker='podman'
fi

if (command -v docker > /dev/null 2>&1 || command -v podman > /dev/null 2>&1); then
  alias dk="docker"
  alias dkr="docker run -it"
  alias dklc="docker ps -a"
  alias dkli="docker image ls"
  alias dkln="docker network ls"
  alias dklv="docker volume ls"

  # tools involving docker images
  alias mlt='docker run --rm -i -v "${PWD}:/srv:ro" -v "/etc:/etc:ro" registry.gitlab.com/replicajune/markdown-link-tester:latest'
  alias kaniko='docker run --rm --workdir "/workspace" -v "${PWD}:/workspace:ro" --entrypoint "" gcr.io/kaniko-project/executor:debug /kaniko/executor --no-push --force'
  alias auditor=cinc-auditor
  alias aud=auditor
  alias doggo='docker run --net=host -t ghcr.io/mr-karan/doggo:latest --color=true'
  # rootless and :Z,U volume opts are causing my local folder to change its
  # permissions from a host standpoint which isn't was I want. relying on
  # sudo / root and exposing the volume as :ro for now
  markdownlint (){
    sudo podman run --network none --user root -v "${1-$PWD}:/src" \
      --workdir '/src' ghcr.io/tmknom/dockerfiles/markdownlint -- .;
    }
fi

if command -v docker-compose > /dev/null 2>&1; then
  alias dkc="docker-compose"
  alias dkcu="docker-compose up -d"
  alias dkcd="docker-compose down"
fi

# desktop
alias bt='bluetoothctl'
alias nt="TMUX=disable gnome-terminal" # new terminal / no tmux

if command -v ddcutil > /dev/null 2>&1; then
  light () { until sudo ddcutil setvcp 10 ${1} &> /dev/null; do sleep 1; done; }
  alias b='light'
fi

