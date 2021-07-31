#!/usr/bin/env bash

if [ -f "/home/${SUDO_USER-$USER}/.shellconfig/shellconfig.sh" ]; then
  # shellcheck source=/dev/null
  . "/home/${SUDO_USER-$USER}/.shellconfig/shellconfig.sh"
fi
