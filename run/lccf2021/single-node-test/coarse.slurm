#!/bin/bash
#SBATCH -J coarse
#SBATCH -N 1
#SBATCH -n 8
#SBATCH -p development
#SBATCH -A ATM20006
#SBATCH -o coarse.o
#SBATCH -e coarse.e
#SBATCH -t 0:10:00
#------------------------------------------------------

pwd
date

export OMP_NUM_THREADS=7
ibrun ../../cm1.exe namelist.input.2km coarse/history.coarse coarse coarse/restart.coarse > coarse.out 2>&1
