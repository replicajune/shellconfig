# Yet another shell configuration repository

## Install

you can grab stuff here and there. If you want to grab everything and be able to update this repo once in a while, you can soft link the files you want in your homedir :

-    `.shellconfig.sh`
-    `.aliases`
-    `.environments`
-    `.aliases.private`

Then, source `.shellconfig.sh` in your home shell config file. Optionally, do the same source for the root shell config and link `.shellconfig.sh` there too :

``` sh
if [ -f /home/${SUDO_USER-$USER}/.shellconfig.sh ]; then
    source ~/.shellconfig.sh
fi

```

## Notes

As all other repos of this kind, it'll always be a work in progress. So, Any feedbacks, recomendations or anything else are always welcomed !

## Comming up

-   Aliases for `yum`
-   Aliases for `apk`
-   Your suggestions here !
