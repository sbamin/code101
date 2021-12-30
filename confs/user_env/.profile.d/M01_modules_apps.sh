#!/bin/bash

## user ~/.profile.d/ files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

## Configurations for user compiled modules and libraries.

#################################### NOTES #####################################
## Loading modules using module load will alter bash PATH and other variables
## Such changes may not be compatible all the time with an existing conda env.

## Avoid loading modules using module load here unless you are certain that
## doing so will not interfere with conda-related env setup.

## Instead prefer checking for what module is loading using module show and
## alter PATH and other variables accordingly here.

################################ unload modules ################################
## Use ~/.profile.d/void/VA01_unload_modules.sh to unload system-installed modules

################################# User Modules #################################
## default user modules ##
## Note that we are using output from an "exported" bash variable, HPCMODULES
## that we defined earlier in A01_set_base_env.sh file.
module use --apend "${HPCMODULES}"
## you can append additional module paths, e.g., created by other users and 
## readable by you
# module use --append /path/to/other/modules

############################ spack package manager #############################
## https://spack.io
## ToDo: Update spack
# SPACK_ROOT="${OS6APPS}/spack"
# mypathmunge "${SPACK_ROOT}"/bin

## Earrlier during setup, we defined julia, perl5, etc. related configs in
## ~/.bash_profile. Now let's move those to here.

#################################### julia #####################################
## mypathmunge is a bash function that we defined earlier in ~/.bash_profile
## it allows us to either prefix to PATH (default like follows) or
## append to PATH if we add after following a new path, e.g.,
## mypathmunge "${HPCAPPS}"/julia/1.6.4/bin after
mypathmunge "${HPCAPPS}"/julia/1.6.4/bin

JULIA_DEPOT_PATH="${HPCOPT}"/julia/pkgs/1.6:"${HPCAPPS}"/julia/1.6.4/local/share/julia:"${HPCAPPS}"/julia/1.6.4/share/julia
JULIA_NUM_THREADS=4
JULIA_EDITOR=micro

#################################### perl5 #####################################
## ToDo: Load PERL5LIB only if running a specific conda env, i.e., set or unset
## PERL5LIB via conda activate.d/deactivate.d configuration. This way, we can
## safeguard building and loading version-specific perl packages.
PERL5LIB="${HPCOPT}"/perl/pkgs/perl5/5.32:"${HPCOPT}"/perl/pkgs/perl5/site_perl/5.32:"${HPCOPT}"/perl/pkgs/perl5/site_perl

################################# singularity ##################################
## PS: singularity is not available on HPC login nodes.
# module load singularity

## alternate to loading module using module load,
## you can also manually set env paths by first looking into
## what the module load will do, e.g., module show singularity
## and then setting respective bash variables as follows:

## prepend singularity bin path to PATH
## We will reconfigure PATH at the end of ~/.bash_profile to ensure
## we always get priority to conda and other user env related paths in PATH
mypathmunge /cm/local/apps/singularity/current/bin

## add manpath to MANPATH
MANPATH="${HPCLOCAL}"/share/man:/cm/local/apps/singularity/current/share/man"${MANPATH:+:$MANPATH}"
## and so on...

## PS: I usually avoid loading modules in bash startup, especially if module will
## reconfigure PATH, LD_LIBRRARY_PATH, LIBPATH, and other devtools paths.
## Doing so will unnecessarily change these essential bash variables and may
## end up compiling or loading packages in R, python, julia, etc. with
## incorrect - those not from the respective conda env - dynamically linked libraries.

## cache, read https://sylabs.io/guides/3.0/user-guide/build_env.html
SINGULARITY_CACHEDIR="/projects/verhaak-lab/amins/containers/cache/singularity"
## path were built SIF images are stored
SINGULARITY_SIF="/projects/verhaak-lab/amins/containers/sifbin"

##################################### rust #####################################
## ToDo: Update Rust
# CARGO_HOME=/projects/verhaak-lab/amins/sumnerenv_os7/opt/apps/rust/default/cargo
# RUSTUP_HOME=/projects/verhaak-lab/amins/sumnerenv_os7/opt/apps/rust/default/rust

##################################### nim ######################################
## ToDo: Update nim
# NIMBLE_DIR=/projects/verhaak-lab/amins/sumnerenv_os7/opt/apps/nim/default/nimble

###################################### GO ######################################
## ToDo: Update GO
# GOROOT=/projects/verhaak-lab/amins/sumnerenv_os7/opt/apps/go/go_1.14.2
# GOPATH=/projects/verhaak-lab/amins/sumnerenv_os7/opt/apps/go/gopkgs/v1.14.2

############################### reconfigure PATH ###############################
## PS: We will reconfigure PATH at the very end of bash startup sequence using
## tail end of ~/.bash_profile. However, it's better to reconfigure PATH here 
## so as to preserve order of series of modules and apps we have configured in
## this file.

## ToDo: Add module and apps to PATH
# mypathmunge "/cm/local/apps/singularity/current/bin:${GOROOT}/bin:${GOPATH}/bin:${SUM7APPS}/julia/julia-1.4.0/bin:${CARGO_HOME}/bin:${NIMBLE_DIR}/bin:${HOME}/.aspera/cli/bin:${HOME}/.aspera/connect/bin"

## Make sure to export all variables ##
export JULIA_DEPOT_PATH JULIA_NUM_THREADS JULIA_EDITOR PERL5LIB MANPATH SINGULARITY_CACHEDIR SINGULARITY_SIF
##################################### END ######################################
