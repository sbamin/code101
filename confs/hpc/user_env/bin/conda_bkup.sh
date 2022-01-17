#!/bin/bash

## Backup conda config
## @sbamin

## Details at https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html

## enable strict mode
set -euo pipefail
IFS=$'\n\t'

## make backup directory
MKSTAMP=$(date +%d%b%y_%H%M%S%Z)
TSTAMP="${TSTAMP:-$MKSTAMP}"

## get current conda env name
CURRENT_CONDA_ENV=${CONDA_DEFAULT_ENV:-"base"}

BKUP_LOC="${HOME}/conda_env_bkup/hpc_jax/${CURRENT_CONDA_ENV}/${TSTAMP}"
mkdir -p "${BKUP_LOC}" && \
cd "${BKUP_LOC}" && \
echo "Workdir is $(pwd)"

################################## Export Env ##################################
## make output file names
BKUP_ENV=$(printf "%s_env_%s.yml" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_ENV_JSON=$(printf "%s_env_%s.json" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_ENV_HISTORY=$(printf "%s_env_history_%s.yml" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_ENV_HISTORY_JSON=$(printf "%s_env_history_%s.json" "${CURRENT_CONDA_ENV}" "$TSTAMP")

echo "INFO: export env"
mamba env export --name "${CURRENT_CONDA_ENV}" > "${BKUP_ENV}"
mamba env export --name "${CURRENT_CONDA_ENV}" --json > "${BKUP_ENV_JSON}"
echo "INFO: export env from-history"
mamba env export --name "${CURRENT_CONDA_ENV}" --from-history > "${BKUP_ENV_HISTORY}"
mamba env export --name "${CURRENT_CONDA_ENV}" --from-history --json > "${BKUP_ENV_HISTORY_JSON}"

################################### List Env ###################################
## make output file names
BKUP_LIST_PKGS=$(printf "%s_env_list_pkgs_%s.txt" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_LIST_PKGS_JSON=$(printf "%s_env_list_pkgs_%s.json" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_LIST_NOPIP_PKGS=$(printf "%s_env_list_pkgs_nopip_%s.txt" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_LIST_NOPIP_PKGS_JSON=$(printf "%s_env_list_pkgs_nopip_%s.json" "${CURRENT_CONDA_ENV}" "$TSTAMP")
BKUP_LIST_CENTOS7=$(printf "%s_env_list_pkgs_centos7_%s.txt" "${CURRENT_CONDA_ENV}" "$TSTAMP")

echo "INFO: export list"
mamba list --export --name "${CURRENT_CONDA_ENV}" > "${BKUP_LIST_PKGS}"
mamba list --export --name "${CURRENT_CONDA_ENV}" --json > "${BKUP_LIST_PKGS_JSON}"
echo "INFO: export list without pip packages"
mamba list --export --name "${CURRENT_CONDA_ENV}" --no-pip > "${BKUP_LIST_NOPIP_PKGS}"
mamba list --export --name "${CURRENT_CONDA_ENV}" --no-pip --json > "${BKUP_LIST_NOPIP_PKGS_JSON}"
echo "INFO: export list specific to OS"
mamba list --explicit --md5 --name "${CURRENT_CONDA_ENV}" > "${BKUP_LIST_CENTOS7}"

echo -e "\nConda env ${CURRENT_CONDA_ENV} backuped on ${TSTAMP} at ${BKUP_LOC}\n"

## END ##
