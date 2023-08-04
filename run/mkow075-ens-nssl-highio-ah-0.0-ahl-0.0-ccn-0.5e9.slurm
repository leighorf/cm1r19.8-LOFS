#!/bin/bash
#SBATCH -A ATM20006
#SBATCH -J mkow075-ens-nssl-highio-ah-0.0-ahl-0.0-ccn-0.5e9-30km-b
#SBATCH -N 128
#SBATCH -n 1024
#SBATCH -p normal
#SBATCH --mail-type=all
#SBATCH --mail-user=leigh.orf@gmail.com
#SBATCH -o mkow075-ens-nssl-highio-ah-0.0-ahl-0.0-ccn-0.5e9-30km-b.o
#SBATCH -e mkow075-ens-nssl-highio-ah-0.0-ahl-0.0-ccn-0.5e9-30km-b.e
#SBATCH -t 30:00:00
#------------------------------------------------------

pwd
date

unset HDF5_PLUGIN_PATH
export OMP_NUM_THREADS=7

B="mkow075-ens-nssl-highio-ah-0.0-ahl-0.0-ccn-0.5e9"

ibrun ./cm1.exe namelist.input.$B $B/history.$B $B $B/restart.$B > outfiles/${B}-30km-b.out 2>&1
