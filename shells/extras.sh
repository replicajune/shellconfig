#!/usr/bin/env bash
# common settings for non busybox shells

alias lz='command ls -g --classify --group-directories-first --context --no-group --all'
alias vd="diff --side-by-side --suppress-common-lines"

alias psf="ps --ppid 2 -p 2 --deselect \
  --format user,pid,ppid,pcpu,pmem,time,stat,cmd --forest"
alias topm="ps -A -o user,pid,ppid,pcpu,pmem,time,stat,comm \
  | (sed -u 1q; sort -r -k5) | head -11"
alias topt="ps -A -o user,pid,ppid,pcpu,pmem,time,stat,comm \
  | (sed -u 1q; sort -r -k6) | head -11"
alias topc="ps -A -o user,pid,ppid,pcpu,pmem,time,stat,comm \
  | (sed -u 1q; sort -r -k4) | head -11"

alias lsd="dirs -v | grep -Ev '^0\s+.*$'" # list stack directory
alias pdir="pushd ./ > /dev/null; lsd"

# ressources
alias topd='sudo sh -c "du -shc .[!.]* * |sort -rh |head -11" 2> /dev/null'
alias lsm="mount | grep -E '^(/dev|//)' | column -t"

# shellcheck disable=SC2142
alias ha="history | awk '{ print substr(\$0, index(\$0,\$4)) }' | sort | uniq -c | sort -h | grep -E '^[[:space:]]+[[:digit:]]+[[:space:]].{9,}$'"

# Kubernetes
  kset () {
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
        . <(kubectl completion bash)
        . <(kubectl completion bash | sed 's/kubectl/k/g')
        echo "set k alias"
        alias k='kubectl'
      fi
      if command -v helm > /dev/null 2>&1; then
        echo "set helm completion"
        . <(helm completion bash)
      fi
    else
      if [ -n "${ARGUMENTS}" ]; then
        echo "define following arguments through kubectl alias:${ARGUMENTS}"
        # shellcheck disable=SC2139
        alias kubectl="kubectl ${ARGUMENTS}"
      fi
    fi
  }
