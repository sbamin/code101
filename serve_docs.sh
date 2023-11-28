#!/bin/bash

DOCDIR="$HOME"/sync/dbsa/acad/scripts/github/webpages/live/code101

if [[ ! -d "$DOCDIR" || ! -x "$DOCDIR" ]]; then
	echo -e "\nERROR: DOCDIR does not exists or not accesible at $DOCDIR\n" >&2
	exit 1
fi

#### Activate CONDA in subshell ####
## Read https://github.com/conda/conda/issues/7980
CONDA_BASE=$(conda info --base) && \
source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
conda activate ruby
#### END CONDA SETUP ####

## strict check
set -euo pipefail

cd "${DOCDIR}"/web && echo -e "\nWorkdir is $(pwd)\n"

## en0 is wifi address - double check that
# hostip="$(ipconfig getifaddr en0)"
# mkdocs serve --livereload -a "${hostip}":8000
mkdocs serve
## END ##
