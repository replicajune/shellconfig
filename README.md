# Yet another shell configuration repository

[![Actions Status](https://github.com/replicajune/shellconfig/workflows/Shellcheck/badge.svg)](https://github.com/replicajune/shellconfig/actions)

## Install

You can either replace your `.bashrc` file with the `.shellconfig.sh` file provided in this repo, or source it in your usual `.bashrc` file. I suggest the later.

You can clone this repo in your user's home folder:

``` sh
git clone https://github.com/replicajune/shellconfig.git ~/.shellconfig
```

And add this in your `.bashrc` :

``` sh
if [ -f "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh" ]; then
  . "/home/${SUDO_USER-$USER}/.shellconfig/.shellconfig.sh"
fi
```

> You can add the same bit in your root's bashrc to benefit from the same setup when using `sudo -i` / `sudo -s`.

## Notes

- Overall, this repo is super opinionated, and stuff changes from time to time, be aware of that.
- Rendering of emojis in a terminal might require `fonts-noto-color-emoji` package on debian systems (or the equivalent package in a non-debian distribution). this is needed for the weathers functions
- Any feedbacks, recomendations always welcomed ! :)
