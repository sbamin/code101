#!/bin/bash

## user ~/.bash_profile
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

## VERSION ##
HPCENV_VERSION="2.0"
export HPCENV_VERSION

############## Debug Mode ##############
## uncomment to debug bash startup
# set -x
# echo "Debug ON via ~/.bash_profile"
# sleep 2
############ End Debug Mode ############

############################## START USER CONFIG ###############################
#### Source ~/.profile.d/*.sh files ####
## function to load user configs from ~/.profile.d/

## PS: Use function name different than default: pathmunge as /etc/profile
## may unset pathmunge and it may not be available to source ~/.profile.d/void
## contents below.
mypathmunge () {
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH="${PATH}":"$1"
            else
                PATH="$1":"${PATH}"
            fi
    esac
}

## Source files in alphanumeric order A01.sh, A02.sh,...,Z99.sh
if [ -d "${HOME}"/.profile.d ]; then
  for i in "${HOME}"/.profile.d/*.sh; do
    if [ -r "$i" ]; then
      	if [ "${-#*i}" != "$-" ]; then
            . "$i" >/dev/null 2>&1
        else
            . "$i" >/dev/null 2>&1
        fi
    fi
  done
  unset i
fi
############################### END USER CONFIG ################################

## Avoid adding more configs below this line instead use ~/.profile.d/*.sh files
## to load additional user configs.

####### user and system bashrc ########
## User .bashrc will be sourced only in an interactive shell OR when PS1 variable
## is set.

## User .bashrc will also source user ~/.bash_aliases if present AND system
## bashrc from /etc/bashrc
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

############################### START CONDA ENV ################################
## Typically conda env is set via conda (or mamba) init command to ~/.bashrc
## and NOT in the ~/.bash_profile. Here, I am doing the opposite with rationale
## explained in the documentation website: see bash startup section.

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/projects/verhaak-lab/amins/hpcenv/mambaforge/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/projects/verhaak-lab/amins/hpcenv/mambaforge/etc/profile.d/conda.sh" ]; then
        . "/projects/verhaak-lab/amins/hpcenv/mambaforge/etc/profile.d/conda.sh"
    else
        export PATH="/projects/verhaak-lab/amins/hpcenv/mambaforge/bin:$PATH"
    fi
fi
unset __conda_setup

## enable mamba activate/deactivate functions
if [ -f "/projects/verhaak-lab/amins/hpcenv/mambaforge/etc/profile.d/mamba.sh" ]; then
    . "/projects/verhaak-lab/amins/hpcenv/mambaforge/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<
################################ END CONDA ENV #################################

############################### OVERRIDE CONFIGS ###############################
## Now we can define final set of shell scripts that can...
## 1. optionally, override some of bash env configs that were set by /etc/bashrc
## 2. tweak our bash startup to load GPU-compatible env for Winter GPU HPC.

############ SYSTEM CONFIGS ############
## Be careful here to not override variables and PATHs that are critical for
## working in the HPC env. Talk to HPC Staff for more before overriding
## system defaults.
## See ~/.profile.d/void/VA01_unload_modules.sh for details.

######### GPU-SPECIFIC CONFIG ##########
## We will also tweak bash startup such that it can load GPU-compatible env
## during ssh to Winter GPU HPC.
## See file(s) starting with VW in ~/.profile.d/void/ for details. 

## Source files in alphanumeric order VA01.sh, VA02.sh,...,VZ99.sh
if [ -d "${HOME}"/.profile.d/void ]; then
  for i in "${HOME}"/.profile.d/void/*.sh; do
    if [ -r "$i" ]; then
      	if [ "${-#*i}" != "$-" ]; then
            . "$i" >/dev/null 2>&1
        else
            . "$i" >/dev/null 2>&1
        fi
    fi
  done
  unset i
fi

unset -f mypathmunge

################################### SET PATH ###################################
## Rewriting PATH ##

## WARNING: Following setup (SET PATH block) is optional and you can remove it
## unless you are comfortable resetting PATH variable from scratch. Faulty
## configuration in PATH may lock you out from login to HPC.

## We want user and conda env paths to precede system paths, specifically:
## <CONDA_ENV>/bin must precede /usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin
## so as to compile and load packages with valid gcc and other devtools.

## Ensure to append PATH variable in the case when sysadmin adds more tools in 
## /etc/bashrc. This will duplicate most of path but it doesn't matter as we
## set precedence for the user configs in PATH string and include all of PATH
## locations.

## Also note ${PATH:+:$PATH} is kept before system paths. This will force system
## paths to be appended at the end but module paths - that we may load using
## ~/.profile.d/ configs - to precede system paths.

## store current PATH variable that we are going to reset now.
deprecPATH="${PATH}"

## Set PATH based on HPC type ##

## most of env variables are already sourced from one or more ~/.profile.d/*.sh
## files.

if [[ "$(hostname)" == *"sumner"* ]]; then
	## default or CPU-compatible PATH
	PATH="${HOME}/bin:${HPCCONDA}/bin:${HPCCONDA}/condabin:${HPCOPT}/bin:${HOME}/.local/bin:${HPCOPT}/bin:${HPCLOCAL}/bin${PATH:+:$PATH}:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
	MYENV="SUMNER7"
elif [[ "$(hostname)" == *"winter"* ]]; then
	## You may change PATH below to source GPU-compatible conda env, e.g.,
	## Replace ${HPCCONDA}/bin with ${HPCCONDA}/envs/rey/bin and
	## optionally add paths to CUDA and other GPU-specific library bins
	PATH="${HOME}/bin:${HPCCONDA}/bin:${HPCCONDA}/condabin:${HPCOPT}/bin:${HOME}/.local/bin:${HPCOPT}/bin:${HPCLOCAL}/bin${PATH:+:$PATH}:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
	MYENV="WINTER7"
else
	## same as default or CPU-compatible PATH
	PATH="${HOME}/bin:${HPCCONDA}/bin:${HPCCONDA}/condabin:${HPCOPT}/bin:${HOME}/.local/bin:${HPCOPT}/bin:${HPCLOCAL}/bin${PATH:+:$PATH}:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"
	MYENV="UNKNOWN"
fi

#### remove duplicate PATH entries BUT preserve order of entries ###
## prefer bash solution
## bash: https://unix.stackexchange.com/a/40973/28675
## perl: https://unix.stackexchange.com/a/50169/28675

if [ -n "$PATH" ]; then
	## THIS UNSETS PATH - CAREFUL ON CHOICE OF COMMANDS YOU HAVE NOW!
	  old_PATH="${PATH}":; PATH=
	  while [ -n "$old_PATH" ]; do
	    x=${old_PATH%%:*}       # the first remaining entry
	    case "${PATH}": in
	      *:"$x":*) ;;          # already there
	      *) PATH="${PATH}":"$x";;    # not there yet
	    esac
	    old_PATH=${old_PATH#*:}
	  done
	  PATH=${PATH#:}
	  unset old_PATH x
fi

export deprecPATH PATH MYENV
################################# END SET PATH #################################

######### Customize PS1 prompt #########
## Reset PS1 and never keep it unset else sub-shells may not source user and
## system bashrc configurations.

## By resetting PS1, base conda env will not get any prefix like (base) but
## mamba activate will prepend respective conda env name to PS1 prompt.

bldred='\e[1;31m' # Red
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
blduid='\e[1;32m' # yellow
txtrst='\e[0m'    # Text Reset - Useful for avoiding color bleed

PROMPT_COMMAND="printf '\n'"
PS1="\[$blduid\]\u\[$txtrst\]@\[$bldwht\]\h\[$txtrst\]:\[$bldcyn\]\w\[$txtrst\]$ "
export PS1
##################################### END ######################################
