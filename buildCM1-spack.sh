#!/usr/bin/env bash
echo "Building CM1-LOFS from spack libraries..."
echo "Loading module files"
spack load h5z-zfp
cd src


if spack find --format "{compiler}" zfp | grep -q intel; then
    echo "It appears ZFP was compiled with Intel. Using Intel Makefile..."
    export HDF5_FC=mpiifort
    PREFIX=$PREFIX make -f Makefile.spack.intel clean 
    PREFIX=$PREFIX make -f Makefile.spack.intel newcomm 
    PREFIX=$PREFIX make -f Makefile.spack.intel lofs
    PREFIX=$PREFIX make -j 8 -f Makefile.spack.intel all
elif spack find --format "{compiler}" zfp | grep -q gcc; then
    export HDF5_FC=mpifort
    PREFIX=$PREFIX make -f Makefile.spack.gcc clean 
    PREFIX=$PREFIX make -f Makefile.spack.gcc all
else
    echo "ZFP wasn't compiled by either gcc or intel, which are currently the only supported configurations. You may have to manually modify the Makefile to work."
fi

