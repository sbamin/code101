#!/bin/bash

## Commit and publish to website
## @sbamin

## commit message as the first argument
REPO="code101"
WEBURL="https://code.sbamin.com"
WEB_BRANCH="www"

DOCDIR="$HOME"/dbsa/acad/scripts/github/webpages/live/"${REPO}"
WEBDIR="/tmp/${REPO}"
mkdir -p "${WEBDIR}"

#### DANGER ####
## MAKE SURE TO HAVE VALID PATH HERE AS SCRIPT WILL NOT CHECK FOR PATH
## rsync may overwrite or worse, delete files on remote node.

if [[ ! -d "$DOCDIR" || ! -x "$DOCDIR" || ! -x "$WEBDIR" ]]; then
	echo -e "\nERROR: DOCDIR does not exists or not accesible at $DOCDIR OR\nWEBDIR does not exists or not accesible at $WEBDIR\n" >&2
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

## build www ##
cd "${DOCDIR}"/web && \
echo "Start building ${REPO}..."

## build docs
rm -rf "${WEBDIR}" && \
mkdir -p "${WEBDIR}" && \
mkdocs build --clean --site-dir "${WEBDIR}" && echo -e "\nINFO: Built updated docs for ${REPO}\n" && \
mkdocs gh-deploy --remote-branch "${WEB_BRANCH}" --clean --site-dir "${WEBDIR}" -m "published commit: {sha} and mkdocs {version}" && \
echo "Successfully updated ${WEBURL} to ${REPO}:${WEB_BRANCH}"

## END ##
