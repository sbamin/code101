#!/bin/bash

## user ~/.profile.d/ files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

## This file will define several bash variables and base configuration items
## that are being used throughout of remaining bash startup sequence and also
## while working interactively on the command line.

#################################### umask #####################################
## allows you to set default read-write-execute permission for 
## files and directories you create in the future.
## https://en.wikipedia.org/wiki/Umask

## This can be overwritten by system bashrc later.
## If so, check with HPC admin if your umask is compatible with HPC.

## Run umask -S to see human-readable umask permissions

## umask 0027 will allow read-execute for user's primary group but
## will disallow read-execute for others.

## umask 0022 (usually a default) allows read-execute for user's primary group
## as well as for others on the HPC env.

## PS: If you are sharing apps and data with users from other lab/groups,
## prefer setting umask to 0022. However, ensure that all of your passwords,
## API tokens, ssh private keys, etc. are protected using chmod 600 (for files)
## and chmod 700 (for directories).
umask 0022

############################## default locations ###############################
## base dir, preferably on tier 1 or location with a large user quota
## where you will install all of configurations, including conda and apps.
HPCENV="/projects/verhaak-lab/amins/hpcenv"
HPCCONDA="${HPCENV}"/mambaforge
HPCOPT="${HPCENV}"/opt
HPCLOCAL="${HPCOPT}/local"
HPCMODULES="${HPCOPT}/modules/def"
HPCAPPS="${HPCOPT}/modules/apps"

## screen or tmux socket directory ##
SCREENDIR="${HOME}"/.screen
TMUX_TMPDIR="${HOME}"/logs/tmux/sumner

## EDITOR ##
## your preferred text editor
## I use https://micro-editor.github.io
EDITOR=micro

## Set TZ ##
TZ='America/New_York'

## Make sure to export all bash variables ##
## So that rest of bash startup sequence files can recognize these variables
export HPCENV HPCCONDA HPCOPT HPCLOCAL HPCMODULES HPCAPPS SCREENDIR TMUX_TMPDIR EDITOR TZ
##################################### END ######################################
