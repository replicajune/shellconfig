#!/usr/bin/env sh

if command -v dnf > /dev/null 2>&1; then
  alias upd="sudo dnf check-update --refresh --assumeno"
  alias updl="dnf list --cacheonly --upgrades --assumeno"
  alias rpkg="sudo dnf remove --assumeyes"
  alias spkg="dnf search"
  updnow () {
    if command -v snap > /dev/null 2>&1; then
      sudo snap refresh
    fi
    if command -v flatpak > /dev/null 2>&1; then
      flatpak update -y
    fi
    sudo dnf update --refresh --assumeyes
  }
  ipkg () { sudo dnf install -y "./${1}"; }
fi
alias gpkg="rpm -qa | grep -i"
