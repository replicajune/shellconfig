#!/usr/bin/env bash

alias sctl="sudo systemctl"
alias uctl="systemctl --user"
alias j="sudo journalctl --since '1 day ago'"
alias jf="sudo journalctl -f"
alias jg="sudo journalctl --since '1 day ago' --no-pager | grep"

health() {
  # keeping this as a function in shellconfig for flexibility
  local SCTL
  if [ "${1}" = "u" ]; then
    SCTL="systemctl --user"
  else
    SCTL="sudo systemctl"
  fi
  # return status health for systemd, show failed units if system isn't healthy
  case "$(${SCTL} is-system-running | tr -d '\n')" in
    running
      echo -e '\e[32m●\e[0m system running' # green circle
    ;;
    starting)
      echo -e '\e[32m↑\e[0m System currently booting up' # green up arrow
    ;;
    stopping)
      echo -e '\e[34m↓\e[0m System shuting down' # blue down arrow
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
