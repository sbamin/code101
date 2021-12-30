#!/bin/bash

## make backup directory
TSTAMP=$(date +%d%b%y_%H%M%S%Z)
mkdir -p "${HOME}"/conda_env_bkup/sumner
## get current conda env name
CURRENT_CONDA_ENV=${CONDA_DEFAULT_ENV:-"root"}

BKUP_LOC="${HOME}/conda_env_bkup/sumner/${CURRENT_CONDA_ENV}/${TSTAMP}"
mkdir -p "${BKUP_LOC}"


## make output file names
BKUP_ENV=$(printf "%s_environment_%s.yml" "${CURRENT_CONDA_ENV}" "$TSTAMP")

BKUP_ENV_VERSIONED=$(printf "%s_environment_versioned_%s.txt" "${CURRENT_CONDA_ENV}" "$TSTAMP")

BKUP_ENV_LIST=$(printf "%s_environment_list_%s.txt" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_ENV_LIST_JSON=$(printf "%s_environment_list_%s.json" "${CURRENT_CONDA_ENV}" "$TSTAMP")

echo -e "\n#####\nStarting backup for conda env: ${CURRENT_CONDA_ENV} at ${BKUP_LOC}\n#####\n"

echo -e "\nExporting conda env: ${CURRENT_CONDA_ENV}\n"
conda env export --name "${CURRENT_CONDA_ENV}"  > "${BKUP_LOC}"/"${BKUP_ENV}"

echo -e "\nExporting conda list with package version for env: ${CURRENT_CONDA_ENV}\n"
conda list --explicit > "${BKUP_LOC}"/"${BKUP_ENV_VERSIONED}"

echo -e "\nExporting conda list for env: ${CURRENT_CONDA_ENV}\n"
conda list --export > "${BKUP_LOC}"/"${BKUP_ENV_LIST}"
conda list --export --json > "${BKUP_LOC}"/"${BKUP_ENV_LIST_JSON}"

## md5sums and list exported files
echo -e "\nExporting md5sums\n"
md5sum "${BKUP_LOC}"/*environment* > "${BKUP_LOC}"/md5sums_"${CURRENT_CONDA_ENV}"_"$TSTAMP".txt
ls -alh "${BKUP_LOC}"

echo -e "\n#####\nConda environment ${CURRENT_CONDA_ENV} backuped on ${TSTAMP} at ${BKUP_LOC}\n#####\n"

## END ##
