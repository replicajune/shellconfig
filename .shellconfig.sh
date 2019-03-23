#!/bin/sh

# PS1
if [ $USER = "root" ]; then
  PS1="\t [\[\e[0;31m\]\u\[\e[0m\]@\[\e[0;36m\]\h \[\e[0;34m\]\w\[\e[0m\]]# "
else
  PS1="\t [\[\e[0;32m\]\u\[\e[0m\]@\[\e[0;36m\]\h \[\e[0;34m\]\w\[\e[0m\]]$ "
fi

# tmux
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "$SUDO_USER" ]; then
  tmux attach -t default 2> /dev/null || tmux new -s default
fi

[ -h ~/.environments ] && source .environments
[ -h ~/.aliases ] && source .aliases
[ -e ~/.aliases.private ] && source .aliases.private || true
