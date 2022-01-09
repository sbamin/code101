#!/bin/bash

## user cronjob config
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

####################### experimental and optional setup ########################

## Following file will not be sourced during bash startup and rather used for
## cron-like non-interactive jobs which typically do not source bash startup sequence.

## In rare case, when I like to run cron-like jobs via slurm workload manager,
## I can source this file first to load minimal user env before running follow up
## commands. In essence, this file aggregates all of commands in order I source
## using bash startup sequence, i.e., configurations from ~/.bash_profile,
## ~/.profile.d/, ... etc.

## set PS1 prompt to emulate cron job as an interactive job.
PS1="[\u@\h \W]\\$ "
export PS1

## VERSION ##
HPCENV_VERSION="2.0"

############## Debug Mode ##############
## uncomment to debug bash startup
# set -x
# echo "Debug ON via ~/.bash_profile"
# sleep 2
############ End Debug Mode ############

############################# set default user env #############################
## Typically an output of PATH after you have successfully setup bash startup
## sequence using ~/.profile.d/ setup and logged again into HPC.
PATH="/home/amins/bin:/projects/verhaak-lab/amins/hpcenv/mambaforge/bin:/projects/verhaak-lab/amins/hpcenv/mambaforge/condabin:/projects/verhaak-lab/amins/hpcenv/opt/bin:/home/amins/.local/bin:/projects/verhaak-lab/amins/hpcenv/opt/local/bin:/cm/local/apps/singularity/current/bin:/projects/verhaak-lab/amins/hpcenv/opt/modules/apps/julia/1.6.4/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin"

## avoid setting slurm related env vars because slurm profile
## is different across CPU and GPU HPCs.
## So, load slurm profile per HPC using modules (below)
# LD_LIBRARY_PATH="/cm/shared/apps/slurm/18.08.8/lib64/slurm:/cm/shared/apps/slurm/18.08.8/lib64"

export PATH
# export LD_LIBRARY_PATH

###################### load minimal bash startup sequence ######################
## copying some of essential setup commands that we wrote in ~/.profile.d/ files.
## Commands are in the order as if they will be executed during an interactive
## login to HPC.

umask 0022

#### default env path ####
HPCENV="/projects/verhaak-lab/amins/hpcenv"
HPCCONDA="${HPCENV}"/mambaforge
HPCOPT="${HPCENV}"/opt
HPCLOCAL="${HPCOPT}/local"
HPCMODULES="${HPCOPT}/modules/def"
HPCAPPS="${HPCOPT}/modules/apps"

## screen or tmux socket directory ##
SCREENDIR="${HOME}"/.screen
TMUX_TMPDIR="${HOME}"/logs/tmux/sumner

## Set TZ ##
TZ='America/New_York'

export HPCENV HPCCONDA HPCOPT HPCLOCAL HPCMODULES HPCAPPS SCREENDIR TMUX_TMPDIR TZ

#### runtime stats ####
## max allowed jobs in active mode on HPC
RUNNING_JOBS=500

## Ping Diskstats ##
## Default options for cron-like job
T1CAP="${T1CAP:-99}"
T2CAP="${T2CAP:-99}"
FASTSTORECAP="${FASTSTORECAP:-99}"
## RVDISKSTAT is being updated via cron job q 30 min or so
RVDISKSTAT="$(cat "${RVSETENV}"/logs/diskstats/rvdiskstats.txt)"
## DANGER ##
## buffer dir: This will be wiped recursively via cron job if
## fastscratch reaches above FASTSTORECAP
# BUFFERDIR="/fastscratch/amins/staged/buffer"

## max jobs on JAX HPC
MAXQ_BATCH=700
MAXQ_DEV=60
MAXQ_LONG=10

export RUNNING_JOBS RVDISKSTAT T1CAP T2CAP FASTSTORECAP RVDISKSTAT MAXQ_BATCH MAXQ_DEV MAXQ_LONG

#### Modules and Apps ####
## Not all app configurations need to be defined here.

## default user modules ##
module use --apend "${HPCMODULES}"

## PS: we can't use mypathmunge here as we did not define it upstream!
## Instead, we hardcoded paths for julia, singularity, and other apps in PATH
## and LD_LIBRARY_PATH (if applicable) above.

JULIA_DEPOT_PATH="${HPCOPT}"/julia/pkgs/1.6:"${HPCAPPS}"/julia/1.6.4/local/share/julia:"${HPCAPPS}"/julia/1.6.4/share/julia
JULIA_NUM_THREADS=4

PERL5LIB="${HPCOPT}"/perl/pkgs/perl5/5.32:"${HPCOPT}"/perl/pkgs/perl5/site_perl/5.32:"${HPCOPT}"/perl/pkgs/perl5/site_perl

## PS: singularity is not available on HPC login nodes.
MANPATH="${HPCLOCAL}"/share/man:/cm/local/apps/singularity/current/share/man"${MANPATH:+:$MANPATH}"
## cache, read https://sylabs.io/guides/3.0/user-guide/build_env.html
SINGULARITY_CACHEDIR="/projects/verhaak-lab/amins/containers/cache/singularity"
## path were built SIF images are stored
SINGULARITY_SIF="/projects/verhaak-lab/amins/containers/sifbin"

export JULIA_DEPOT_PATH JULIA_NUM_THREADS JULIA_EDITOR PERL5LIB MANPATH SINGULARITY_CACHEDIR SINGULARITY_SIF

## load additional modules when needed.

## PS : Unlike bash startup sequence where we reset and reconfigure PATH at the
## end of ~/.bash_profile, this cron job file will not able to do such magic!
## So, any module load command or manual change in PATH or other variables you
## do here will take precedence over specified PATH at the very top of this file.

#### API Tokens ####
## only add if required for cron job
GITHUB_PAT="blahblahblah..."
## GLOBUS endpoint
GLOBUSEP="blahblahblah..."

export GITHUB_PAT GLOBUSEP

## Make sure to export missing bash variable(s), if any.
export HPCENV_VERSION

## END ##
