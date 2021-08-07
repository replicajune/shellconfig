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

bindkey -e
