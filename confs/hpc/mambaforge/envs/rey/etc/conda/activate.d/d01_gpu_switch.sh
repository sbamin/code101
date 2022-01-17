#!/usr/bin/env bash

# name this script such that it loads after
# conda activates cuda related configs, e.g.,
# cupy_activate.sh

## switch gpu env to meet conda specific env needs
## only on Winter GPU HPC

if [[ "$(hostname)" == *"winter"* ]]; then
	# avoid exiting with non-zero exit status
	# during bash startup but manually
	# fix any errors, if any loading/unloading
	# these modules

	## deactivate non-default gpu env, if any.
	module unload gpu/11.1.1_ben || true

	## activate default gpu env
	module load gpu/11.1.1 || true
fi
