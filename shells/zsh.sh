#!/usr/bin/env zsh

setopt autocd
setopt noclobber # don't override existing files
setopt histverify
setopt promptsubst

bindkey -e # user emacs bindings in readline

# moar autocompletion
autoload -U compinit
compinit

# avoid end of lines addition when lines wne without newlines
PROMPT_EOL_MARK=''

PROMPT='%* [%n@%m %c] %? $(load) '$'${(r:$((COLUMNS-42))::\u2500:)}'$'\n''> '
# horizontal line : https://superuser.com/a/846133
