#!/usr/bin/env bash

# shell options
shopt -s histappend # parallel history
shopt -s checkwinsize # resize window
shopt -s autocd # go in a directory without cd
shopt -s histverify # put a caled historized command in readline

alias reload-bash=". ~/.bashrc"

. "${REPO_PATH}/shells/_prompts.sh"

PS1=$PS_DATE$PS_LOC_BLOCK$PS_EXTRA_BLOCK$PS_SYSD_BLOCK$PS_PROMPT
PS2='…  '
