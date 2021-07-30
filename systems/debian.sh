#!/usr/bin/env bash

alias upd="sudo apt update && apt list --upgradable"
alias updl="apt list --upgradable"
alias rpkg="sudo apt purge -y"
alias gpkg="dpkg -l | grep -i"
alias spkg="apt-cache search -qq"
updnow () {
  if command -v snap > /dev/null 2>&1; then
    sudo snap refresh
  fi
  if command -v flatpak > /dev/null 2>&1; then
    flatpak update -y
  fi
  sudo apt update &&\
  sudo apt upgrade -y

}
ipkg () { sudo apt install -y "./${1}"; }
