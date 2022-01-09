#!/bin/bash

## user ~/.profile.d/void Winter GPU specific files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

#################################### NOTES #####################################
## Load bash env for Winter GPU HPC

## To load GPU-compatible env, we need to first initialize conda env, and hence,
## we have kept this file under void/ directory and not under ~/.profile.d/
## because we activate conda env after sourcing ~/.profile.d/*.sh files but
## before sourcing ~/.profile.d/void/*.sh file(s).

## ToDo: Setup Winter GPU startup
if [[ "$(hostname)" == *"winter"* ]]; then
	### START CONDA SETUP ###
    CONDA_BASE=$(conda info --base) && \
    source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
    conda activate rey
	#### END CONDA SETUP ####

    ## Load additional CUDA drivers, toolkit, etc.
    ## if applicable.
    # module load cuda11.1/toolkit/11.1.1
fi

## END ##