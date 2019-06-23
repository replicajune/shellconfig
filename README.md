# Yet another shell configuration repository

## Install

- clone the repo :

``` sh
git clone https://github.com/replicajune/shellconfig.git ~/.shellconfig
```

source `.shellconfig.sh` in your home shell config file (`~/.bashrc`) :

``` sh
if [ -f "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh" ]; then
    . "/home/${SUDO_USER-$USER}/.shellconfig.sh"
fi
```

> Optionally, link `.shellconfig.sh` in your home and source the original one

## Notes

- aliases for `apk` are not perfect but they do the job.
- Any feedbacks, recomendations always welcomed ! :)
