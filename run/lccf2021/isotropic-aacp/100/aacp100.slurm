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
#SBATCH -J aacp100
#SBATCH -N 128
#SBATCH -n 1024
#SBATCH -p normal
#SBATCH --mail-type=all
#SBATCH --mail-user=leigh.orf@gmail.com
#SBATCH -o aacp100.o
#SBATCH -e aacp100.e
#SBATCH -t 2:00:00
#------------------------------------------------------

pwd
date

export OMP_NUM_THREADS=7
ibrun ../cm1.exe-OMP7 namelist.input.aacp.100m aacp.100m/history.aacp.100m aacp.100m aacp.100m/restart.aacp.100m > aacp100-a.out 2>&1
