#!/usr/bin/env bash

# warn while activating Sumner (CPU) env on Winter (GPU) HPC.
# load at the very beginning of activate.d/ scripts, e.g.,
# a01_warn_noncpu.sh

## PS: It's ok to use CPU env on GPU HPC as long as both HPCs
## share identical base OS (CentOS7 in our case) and shared
## system paths, e.g., /etc/, /usr/, /opt/, etc.

if [[ "$(hostname)" != *"sumner"* ]]; then
	echo -e "\n######### WARN: CAREFUL MANAGING CPU ENV #########
\nhostname string, $(hostname) does not match sumner.\nconda env, ${CONDA_DEFAULT_ENV} should be managed using Sumner CPU HPC.\nAvoid installing or updating packages outside Sumner HPC env." >& 2
fi
