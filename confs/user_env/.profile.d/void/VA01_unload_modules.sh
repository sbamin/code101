#!/bin/bash

## user ~/.profile.d/void/ files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

#################################### NOTES #####################################
## load user configs that can override /etc/bashrc settings.

## Be careful here to not override variables and PATHs that are critical for
## working in the HPC env. Talk to HPC Staff for more before overriding
## system defaults.

##### Unload HPC default modules #####
## be careful unloading default modules as some modules, e.g,
## slurm and CUDA libraries (on GPU cluster), etc. are required for working with
## HPC.
module unload gcc
module unload dot

## Add extra TERM options, if any
## Comment out if not applicable
## related to https://sw.kovidgoyal.net/kitty
case "$TERM" in
	'xterm') TERM=xterm-256color;;
	'screen') TERM=screen-256color;;
	'Eterm') TERM=Eterm-256color;;
	'xterm-kitty') TERM=xterm-kitty;;
esac

export TERM

## END ##
