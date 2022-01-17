#!/usr/bin/env sh

# name this script such that it loads after
# conda activates r-base using activate-r-base.sh

## override ~/.Renviron which point to R from yoda env
R_HOME="$CONDA_PREFIX/lib/R"
R_ENVIRON_USER="/projects/verhaak-lab/amins/hpcenv/opt/R/confs/rey/Renviron"

export R_HOME R_ENVIRON_USER
