# Yet another shell configuration repository

[![Actions Status](https://github.com/replicajune/shellconfig/workflows/shelcheck/badge.svg)](https://github.com/replicajune/shellconfig/actions)

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

> Using `${SUDO_USER-$USER}` allow to source that same file while you're root through sudo. Root will show as user in red in your PS1

## Notes

- Any feedbacks, recomendations always welcomed ! :)
