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
#SBATCH -J aacp.50m-1024nodes
#SBATCH -N 1024
#SBATCH -n 8192
#SBATCH -p large
#SBATCH --mail-type=all
#SBATCH --mail-user=leigh.orf@gmail.com
#SBATCH -o aacp.50m-1024nodes.o
#SBATCH -e aacp.50m-1024nodes.e
#SBATCH -t 2:00:00
#------------------------------------------------------

pwd
date

RUN=aacp.50m-1024nodes
export OMP_NUM_THREADS=7
ibrun ./cm1.exe-OMP7 namelist.input.${RUN} ${RUN}/history.${RUN} $RUN ${RUN}/restart.${RUN} > ${RUN}-a.out 2>&1
