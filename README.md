# Yet another shell configuration repository

[![Build Status](https://travis-ci.org/replicajune/shellconfig.svg?branch=master)](https://travis-ci.org/replicajune/shellconfig)

## Install

- clone the repo :

``` sh
git clone https://github.com/replicajune/shellconfig.git ~/.shellconfig
```

source `.shellconfig.sh` in your home shell config file (`~/.bashrc`) :

``` sh
if [ -f "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh" ]; then
  . "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh"
fi
```

## Notes

- Any feedbacks, recomendations always welcomed ! :)
