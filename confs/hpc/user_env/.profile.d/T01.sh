#!/bin/bash

## user ~/.profile.d/ files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

#################################### NOTES #####################################
## Placeholder for API tokens and other credentials
## Ensure this file to be read-only by user as it contains login and API tokens.

## Follow best practices for using API tokens: keep scope limited, set expiry date.

## Ideally, avoid exporting naked tokens like following to bash env and instead
## source tokens as and when needed by a job or a script, preferably using
## gpg decrypt command.

## IMPORTANT ##
## If you are using github to save your bash env config, make sure to ignore
## any file with tokens, passwords else it will get committed and archived
## in git history.

## e.g., github API token
GITHUB_PAT="blahblahblah..."
## default GPG signing key
GPGKEY=XYZ123ABC
## GLOBUS endpoint
## If using globus API, ask HPC staff to setup a valid endpoint
GLOBUSEP="blahblahblah..."

export GITHUB_PAT GPGKEY GLOBUSEP
##################################### END ######################################
