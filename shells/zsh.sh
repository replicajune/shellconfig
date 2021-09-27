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

# horizontal line : https://superuser.com/a/846133
if [ "${TERM_PROGRAM}" = "vscode" ]; then
  PROMPT='> '
else
  PROMPT='%(?.$CC_DARK_GREY.$CC_RED)${(r:$COLUMNS::·:)}$CC_RESET_COLOR$CC_DARK_GREY%*$CC_RESET_COLOR [%(!.$CC_ORANGE.$CC_GREEN)%n$CC_RESET_COLOR@$CC_CYAN%m $CC_RESET_COLOR$CC_DARK_GREY%c$CC_RESET_COLOR$(prompt_git)] %(?.$CC_DARK_GREY.$CC_RED)%?$CC_RESET_COLOR [$(prompt_load)] '$'\n''> '
fi

