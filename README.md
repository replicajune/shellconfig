# Yet another shell configuration repository

[![Actions Status](https://github.com/replicajune/shellconfig/workflows/Shellcheck/badge.svg)](https://github.com/replicajune/shellconfig/actions)

## Install

- clone the repo and source `.shellconfig.sh` in your home shell config file (`~/.bashrc`). use the following block of code in both your user & root bashrc to have the same configs for both:

``` sh
if [ -f "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh" ]; then
  . "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh"
fi
```

## Notes

- Any feedbacks, recomendations always welcomed ! :)
