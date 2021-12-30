#!/bin/bash

## user ~/.profile.d/ files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

## This file defines aesthetics, like terminal colors, shortcuts, etc.
## comment or uncomment configurations per your setup.

## micro terminal ##
## https://micro-editor.github.io
MICRO_COLORTERMINAL=1

## kitty terminal ##
## https://sw.kovidgoyal.net/kitty/
TERMINFO="${HOME}"/.terminfo

## zoxide autojump ##
## https://github.com/ajeetdsouza/zoxide
## specify full path as PATH is set at the end of ~/.bash_profile
if [[ -s "${HPCLOCAL}"/bin/zoxide ]]; then
	eval "$("${HPCLOCAL}"/bin/zoxide init bash)"
fi

## color terminal ##
## This must be set before reading global initialization such as /etc/bashrc.
SEND_256_COLORS_TO_REMOTE=1
## ToDo: edit TERM options in void/VA02_override.sh AFTER /etc/bashrc is loaded.

export MICRO_COLORTERMINAL TERMINFO SEND_256_COLORS_TO_REMOTE
##################################### END ######################################
