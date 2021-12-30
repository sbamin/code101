#!/bin/bash

## user ~/.bashrc
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

## If not running interactively, skip sourcing ~/.bashrc contents
[ -z "$PS1" ] && return

##################### source system config or /etc/bashrc ######################
## Source global definitions only if not loaded before.

## This is to avoid redundant paths in PATH, LD_LIBRARY_PATH, etc. variables
## when working in pseudo terminals like screen or tmux sessions.

## You may ned to edit grep find patterns per specific path(s) that your HPC
## may be loading from /etc/bashrc (including /etc/profile.d/ files)
SYSBASH=$(echo "$PATH" | grep -Ec "local|slurm")

if [ -f /etc/bashrc ] && [ "${SYSBASH}" = 0 ]; then
	. /etc/bashrc
	unset SYSBASH
fi

########################### source user bash aliases ###########################
if [ -f ~/.bash_aliases ]; then
        . "${HOME}"/.bash_aliases
fi

######################### configure user bash history ##########################
## following will backup your bash command history in ~/.history/ directory.
## you can query it using command deephs, e.g., "deephs samtools" from terminal
## PS: deephs is a bash alias sourced from ~/.bash_aliases

HISTFILE="${HOME}"/.history/"$(date +%Y-%W)".hist

if [[ ! -e "${HISTFILE}" ]]; then
    mkdir -p ~/.history
    ## Run onetime: chmod 700 "${HOME}"/.history
    touch "${HISTFILE}"
    LASTHIST=~/.history/"$(ls -tr ${HOME}/.history/ | tail -1)"
    if [[ -e "${LASTHIST}" ]]; then
        tail -5000 "${LASTHIST}" > "${HISTFILE}"
        # Write a divider to identify where the prior day's session history ends
        echo "##########################################################" >> "${HISTFILE}"
    fi
fi

HISTSIZE=100000
HISTFILESIZE=1000000
## don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth
## append to the history file, don't overwrite it
shopt -s histappend
shopt -s histverify

######################### aesthetics and bash options ##########################
## enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

set -o noclobber # prevent overwriting files with cat
set -o ignoreeof # stops ctrl+d from logging me out
shopt -s checkwinsize
shopt -s direxpand

## export newly created or updated bash variables
export HISTFILE HISTSIZE HISTFILESIZE HISTCONTROL
##################################### END ######################################
