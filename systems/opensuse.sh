#!/usr/bin/env bash

alias upd="sudo zypper refresh; sudo zypper list-updates"
alias updl="sudo zypper list-updates"
alias rpkg="sudo zypper remove --clean-deps --no-confirm"
alias gpkg="zypper search -i"
alias spkg="zypper search"

updnow () {
  if command -v snap > /dev/null 2>&1; then
    sudo snap refresh
  fi
  if command -v flatpak > /dev/null 2>&1; then
    flatpak update -y
  fi
  sudo zypper refresh; sudo zypper dup --no-confirm
}

ipkg () { sudo zypper install -y "./${1}"; }
