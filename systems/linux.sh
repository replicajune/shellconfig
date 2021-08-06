#!/usr/bin/env sh

# source profile.d items
if ls /etc/profile.d/*.sh > /dev/null 2>&1; then
  for SRC_PROFILE in /etc/profile.d/*.sh; do
    # shellcheck source=/dev/null
    . "${SRC_PROFILE}"
  done
fi

# history with date, no size limit
history -a # parallel history
export HISTCONTROL=ignoreboth
export HISTSIZE='INF'
export HISTFILESIZE='INF'
export HISTTIMEFORMAT="[%d/%m/%y %T] "
export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

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
alias ls='ls --color=auto'
alias l='ls -C --classify --group-directories-first'
alias ll='ls -l --classify --group-directories-first --human-readable'
alias la='ls -l --classify --group-directories-first --human-readable --all'
alias lll='ls -l --inode --classify --group-directories-first --human-readable  --author'
alias lla='ls -l --inode --classify --group-directories-first --human-readable  --author --all'
alias lt='ls -gt --classify --reverse --human-readable --all --no-group'

# file managment
alias hl="grep -izF" # highlight

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

  # other aliases involving docker images
  alias mlt='docker run --rm -i -v "${PWD}:/srv:ro" -v "/etc:/etc:ro" registry.gitlab.com/replicajune/markdown-link-tester:latest'
  # build a container in a container and not exposing stuff
  alias kaniko='docker run --rm --workdir "/workspace" -v "${PWD}:/workspace:ro" --entrypoint "" gcr.io/kaniko-project/executor:debug /kaniko/executor --no-push --force'
  # auditor
  alias cinc-auditor='docker run --workdir "/srv" -v "${PWD}:/srv" -v "${_HOME}/.ssh:/root/.ssh" --entrypoint "/opt/cinc-auditor/bin/cinc-auditor" docker.io/cincproject/auditor:latest'
  alias auditor=cinc-auditor
  alias aud=auditor
  # doggo
  alias doggo='docker run --net=host -t ghcr.io/mr-karan/doggo:latest --color=true'
  alias dnc='doggo'
fi

if command -v docker-compose > /dev/null 2>&1; then
  alias dkc="docker-compose"
  alias dkcu="docker-compose up -d"
  alias dkcd="docker-compose down"
fi

alias bt='bluetoothctl'
alias nt="TMUX=disable gnome-terminal" # new terminal / no tmux

