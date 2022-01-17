#!/usr/bin/env bash

# warn while activating Winter (GPU) env on Sumner (CPU) HPC.
# load at the very beginning of activate.d/ scripts, e.g.,
# a01_warn_nongpu.sh

if [[ "$(hostname)" != *"winter"* ]]; then
	echo -e "\n############### WARN: INVALID HPC ################
\nhostname string, $(hostname) does not match winter.\nconda env, ${CONDA_DEFAULT_ENV} works only on the Winter GPU HPC." >& 2
fi
