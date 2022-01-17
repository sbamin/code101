#!/bin/bash

## Wrapper over codna_bkup.sh to backup conda configs for all conda env
## @sbamin

## export one-time conda env list, conda_env_hpc_jax.list
## using command:
## mamba env list | sed -e '/#/d' -e '/^$/d' | awk '{print $1}'

## remove the last empty row as we are doing while loop below or
## enable strict bash check in ~/bin/conda_bkup.sh
CONDA_ENV_FILE="${HOME}"/configs/conda_env_hpc_jax.list

if [[ ! -f "${CONDA_ENV_FILE}" ]]; then
  echo "Can not find ${CONDA_ENV_FILE}" >&2
  exit 1
fi

## export timestamp: Used by "${HOME}"/bin/conda_bkup.sh script
TSTAMP="$(date +%d%b%y_%H%M%S%Z)"
export TSTAMP

while read -r _conda_env; do
  echo "Activating conda env: ${_conda_env}"

  #### Activate CONDA in subshell ####
  ## Read https://github.com/conda/conda/issues/7980
  CONDA_BASE=$(conda info --base) && \
  source "${CONDA_BASE}"/etc/profile.d/conda.sh && \
  conda activate "${_conda_env}"
  #### END CONDA SETUP ####

  _current_conda_env="$(basename "$CONDA_PREFIX")"

  if [[ "${_current_conda_env}" == "${_conda_env}" ]] || [[ "${_current_conda_env}" == "mambaforge" ]]; then
    echo -e "Start bkup for ${_conda_env} with conda prefix: ${_current_conda_env}\n"
    sleep 2
    "${HOME}"/bin/conda_bkup.sh
  else
    echo -e "\nWARN: Skipping backup\nMismatch between conda env: ${_conda_env} and loaded conda env: ${_current_conda_env}\n" >&2
  fi
done < "${CONDA_ENV_FILE}"

## END ##
