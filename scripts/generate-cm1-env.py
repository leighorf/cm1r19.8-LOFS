#!/usr/bin/env python
import sys
import re
import os
import errno
from math import *
import numpy as np

'''

ORF 2020-02-12

This code creates unique namelist and slurm batch files based upon
templates in the templates subdirectory. It also checks for the file
input_sounding and creates directories on scratch and corresponding
symbolic links to the scratch top level directory. File names are
generated based upon selected parameter settings. This makes it easy to
repeatedly use this code to generate parameter sweeps/ensembles without
fear of the usual typos or forgetfulness that has you waiting in the
queue for days only to have your run die immediately...

Slurm is the job scheduler used on the Frontera supercomputer. A similar
approach could easily be achieved for whatever scheduler you have; you'd
just need to modify the template file accordingly.

After running the code you can just run "sbatch [blah].slurm".

'''

def main():
# Here are the things we wish to vary. Rest of options are default r19.8
    hadvordrs =  "5"
    vadvordrs =  "5"
    hadvordrv =  "5"
    vadvordrv =  "5"
    advwenos =   "0"
    advwenov =   "2"
    weno_order = "5"
    idiff =      "0" #add 6th order artificial diffusion?
    mdiff =      "0" #monotonic 6th order filter?
    sgsmodel =   "1" #vary
    ptype =      "5" #vary
    bbc =       "11" # 1=free 2=no 3=semi 11=zero-flux-r16
    kdiff6 =  "0.06"
    wfcenterx =  "0.0"
    wfcentery =  "-20000.0"
    wfalpha =    "0.5"    #vary
    morrisondb = "6.0e-6" #vary
    cnstcd = "0.016"

# Check for sounding file
    if not os.path.isfile("input_sounding"):
        print("input_sounding file missing")
        exit()

# Check for CM1 binary
    if not os.path.isfile("cm1.exe"):
        print("cm1.exe missing")
        exit()

# Top level directory for all model history/restart output
    scratchtop="/scratch3/06618/orf/2020/r19.8/100"
    run_basename="24May2011-r19.8-100"
    namelist_template="templates/namelist.input."+run_basename+"-template"
    inf = open(namelist_template,'r')
# construct unique identifier to be used with namelist files, slurm script, output, etc
    identifier=run_basename+"-"
#   identifier=identifier+"hs"+hadvordrs
#   identifier=identifier+"vs"+vadvordrs
#   identifier=identifier+"hv"+hadvordrv
#   identifier=identifier+"vv"+vadvordrv
#   identifier=identifier+"as"+advwenos
#   identifier=identifier+"av"+advwenov
#   identifier=identifier+"wo"+weno_order
#   identifier=identifier+"if"+idiff
#   identifier=identifier+"mf"+mdiff
    identifier=identifier+"sg"+sgsmodel
    identifier=identifier+"pt"+ptype
    identifier=identifier+"bc"+bbc
#   identifier=identifier+"cd"+cnstcd
#   identifier=identifier+"kd"+kdiff6
    identifier=identifier+"wx"+wfcenterx
    identifier=identifier+"wy"+wfcentery
    identifier=identifier+"wa"+wfalpha
    identifier=identifier+"md"+morrisondb
    namelist_output="namelist.input."+identifier
# If a namelist file already exists, quit; we've already constructed it.
    if (os.path.isfile(namelist_output)):
       print ("namelist file already exists, exiting")
       exit()
    outf = open(namelist_output,'w')
# Now, substitute our values into the namelist template and write 
    while 1:
        line = inf.readline()
        if not line: break
        line = line.replace("HADVORDRS",hadvordrs)
        line = line.replace("VADVORDRS",vadvordrs)
        line = line.replace("HADVORDRV",hadvordrv)
        line = line.replace("VADVORDRV",vadvordrv)
        line = line.replace("ADVWENOS",advwenos)
        line = line.replace("ADVWENOV",advwenov)
        line = line.replace("WENOORDER",weno_order)
        line = line.replace("IDIFF",idiff)
        line = line.replace("MDIFF",mdiff)
        line = line.replace("SGSMODEL",sgsmodel)
        line = line.replace("PTYPE",ptype)
        line = line.replace("BBC",bbc)
        line = line.replace("KDIFF6",kdiff6)
        line = line.replace("WFCENTERX",wfcenterx)
        line = line.replace("WFCENTERY",wfcentery)
        line = line.replace("WFALPHA",wfalpha)
        line = line.replace("MORRISONDB",morrisondb)
        line = line.replace("CNSTCD",cnstcd)
        outf.write(line)
    inf.close()
    outf.close()

# Now, generate our slurm script

    slurm_template="templates/24May100.slurm-template"
    inf = open(slurm_template,'r')
    slurm_output=identifier+".slurm"

# If a slurm file already exists, quit; we've already constructed it.
    if (os.path.isfile(slurm_output)):
        print ("slurm file already exists, exiting")
        exit()
    outf = open(slurm_output,'w')

    while 1:
        line = inf.readline()
        if not line: break
        line = line.replace("IDENTIFIER",identifier)
        outf.write(line)
    inf.close()
    outf.close()

# Finally, set up our scratch directories and symbolic links from work

    tld=scratchtop+"/"+identifier
    mkdir_p(tld)
    os.symlink(tld,identifier)

# We put our output files in a directory now since we are going to do
# more ensembles - this keeps them in one convenient place.
    mkdir_p("outfiles")

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST:
            pass
        else: raise
main()
