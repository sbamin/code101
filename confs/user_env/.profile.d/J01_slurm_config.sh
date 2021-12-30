#!/bin/bash

## user ~/.profile.d/ files
## HPC at JAX
## v2.0 | 12/2021
## @sbamin

## Placeholder for managing slurm workload manager.
## This is optional

## I define these set of variables related to slurm - workload
## manager for our HPC. I have set of runtime (at-start and at-end) scripts
## that can use and update these variables based on HPC usage at any given day.
## e.g., If I am running snakemake workflow with 10000 jobs, I can throttle 
## workflow if disk capacity is near full either because of running jobs from
## my or others' workflows.

## max allowed jobs in active mode on HPC
RUNNING_JOBS=500

## Ping Diskstats ##
## Default options for cron-like job
T1CAP="${T1CAP:-99}"
T2CAP="${T2CAP:-99}"
FASTSTORECAP="${FASTSTORECAP:-99}"
## RVDISKSTAT is being updated via cron job q 30 min or so
RVDISKSTAT="$(cat "${RVSETENV}"/logs/diskstats/rvdiskstats.txt)"
## DANGER ##
## buffer dir: This will be wiped recursively via cron job if
## fastscratch reaches above FASTSTORECAP
# BUFFERDIR="/fastscratch/amins/staged/buffer"

## max jobs on JAX HPC
MAXQ_BATCH=700
MAXQ_DEV=60
MAXQ_LONG=10

export RUNNING_JOBS RVDISKSTAT T1CAP T2CAP FASTSTORECAP RVDISKSTAT MAXQ_BATCH MAXQ_DEV MAXQ_LONG
##################################### END ######################################
