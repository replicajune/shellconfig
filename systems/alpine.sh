#!/usr/bin/env sh

# package managment
alias upd="sudo apk update && echo 'UPGRADABLE :' && sudo apk upgrade -s"
alias updl="sudo apk upgrade -s"
alias updnow="sudo apk update && sudo apk upgrade"
alias rpkg="sudo apk del"
alias gpkg="apk list -I | grep -i"
alias spkg="apk search"
alias clnp="sudo apk -v cache clean"
