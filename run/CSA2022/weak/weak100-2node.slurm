#!/bin/bash
#SBATCH -A ATM20006
#SBATCH -J weak100-1node
#SBATCH -N 2
#SBATCH -n 16
#SBATCH -p development
#SBATCH -o weak100-2node.o
#SBATCH -e weak100-2node.e
#SBATCH -t 0:10:00
#------------------------------------------------------

pwd
date

unset HDF5_PLUGIN_PATH
export OMP_NUM_THREADS=7

RUN=weak100-2node

ibrun ./cm1.exe  namelist.input.$RUN $RUN/history.$RUN $RUN $RUN/restart >$RUN.out
