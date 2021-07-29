#!/bin/bash
#
# Simple SLURM script for submitting multiple serial
# jobs (e.g. parametric studies) using a script wrapper
# to launch the jobs.
#
# To use, build the launcher executable and your
# serial application(s) and place them in your WORKDIR
# directory.  Then, edit the CONTROL_FILE to specify 
# each executable per process.
#-------------------------------------------------------
#-------------------------------------------------------
# 
#         <------ Setup Parameters ------>
#
#SBATCH -J aacp.50m-512nodes
#SBATCH -N 512
#SBATCH -n 4096
#SBATCH -p normal
#SBATCH --mail-type=all
#SBATCH --mail-user=leigh.orf@gmail.com
#SBATCH -o aacp.50m-512nodes.o
#SBATCH -e aacp.50m-512nodes.e
#SBATCH -t 0:30:00
#------------------------------------------------------

pwd
date

RUN=aacp.50m-512nodes
CM1=./cm1.exe-OMP7
export OMP_NUM_THREADS=7
ibrun $CM1 namelist.input.${RUN} ${RUN}/history.${RUN} $RUN ${RUN}/restart.${RUN} > ${RUN}-a.out 2>&1
