#!/usr/bin/env bash

## switch gpu env to meet conda specific env needs
## load at the last in deactivate directory

if [[ "$(hostname)" == *"winter"* ]]; then
	module unload gpu/11.1.1_ben || true
fi
