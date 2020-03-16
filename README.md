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

- Overall, this repo is super opinionated, and stuff changes from time to time, be aware of that :)
- rendering of emojis in terminal might require `fonts-noto-color-emoji` package on debian systems (or the equivalent package in a non-debian distribution)
- Any feedbacks, recomendations always welcomed ! :)
