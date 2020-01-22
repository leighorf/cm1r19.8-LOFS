
#SHELL = /bin/csh

#-----------------------------------------------------------------------------
#                      NETCDF SECTION
#  (uncomment the following four lines if you want netcdf output capability)
#   (also, make sure the paths to netcdf files are correct for your machine)
#              (NOTE: Don't change lines 3 and 4!)
#  Note:  you may need to remove -DNCFPLUS if you use an old version of netcdf
#
#OUTPUTINC = -I$(NETCDF)/include
#OUTPUTLIB = -L$(NETCDF)/lib
#OUTPUTOPT = -DNETCDF -DNCFPLUS
#LINKOPTS  = -lnetcdf -lnetcdff
#-----------------------------------------------------------------------------


#-----------------------------------------------------------------------------
#                     HARDWARE SECTION
#-- Choose the appropriate architecture, and uncomment all lines 
#-- in that section.  See "README.compile" for more information.
#-----------------------------------------------------------------------------
#  single processor, Intel compiler 
#      (eg, NCAR's yellowstone/caldera/cheyenne)
#FC   = ifort
#OPTS = -O3 -xHost -ip -assume byterecl -fp-model precise -ftz -no-fma
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#-----------------------------------------------------------------------------
#  multiple processors, distributed memory (MPI), Intel compiler 
#      (eg, NCAR's yellowstone/cheyenne)
#FC   = mpif90
#OPTS = -O3 -xHost -ip -assume byterecl -fp-model precise -ftz -no-fma
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#DM   = -DMPI
#-----------------------------------------------------------------------------
#  multiple processors, shared memory (OpenMP), Intel compiler 
#      (eg, NCAR's yellowstone/cheyenne)
#FC   = mpif90
#OPTS = -O3 -xHost -ip -assume byterecl -fp-model precise -ftz -no-fma -qopenmp
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#-----------------------------------------------------------------------------
#  single processor, Portland Group compiler
#FC   = pgf90
#OPTS = -Mfree -O2 -Ktrap=none -Mautoinline -Minline=reshape
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#-----------------------------------------------------------------------------
#  multiple processors, distributed memory (MPI), Portland Group compiler
#FC   = mpif90
#OPTS = -Mfree -O2 -Ktrap=none -Mautoinline -Minline=reshape
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#DM   = -DMPI
#-----------------------------------------------------------------------------
#  multiple processors, shared memory (OpenMP), Portland Group compiler
#FC   = pgf90
#OPTS = -Mfree -O2 -Ktrap=none -Mautoinline -Minline=reshape -mp
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#-----------------------------------------------------------------------------
#  single processor, Portland Group compiler, double precision
#FC   = pgf90
#OPTS = -Mfree -O2 -Ktrap=none -Mautoinline -Minline=reshape -r8
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#DP   = -DDP
#-----------------------------------------------------------------------------
#  multiple processors, shared memory (OpenMP), Portland Group compiler, double precision
#FC   = pgf90
#OPTS = -Mfree -O2 -Ktrap=none -Mautoinline -Minline=reshape -r8 -mp
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#DP   = -DDP
#-----------------------------------------------------------------------------
#  single processor, gnu compiler
#FC   = gfortran
#OPTS = -ffree-form -ffree-line-length-none -O2 -finline-functions
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#-----------------------------------------------------------------------------
#  multiple processors, distributed memory (MPI), gnu compiler
#FC = mpif90
#OPTS = -ffree-form -ffree-line-length-none -O2 -finline-functions
#CPP  = cpp -C -P -traditional -Wno-invalid-pp-token -ffreestanding
#DM = -DMPI
#-----------------------------------------------------------------------------
#  single processor, Cray fortran compiler
#      (eg, NCSA's bluewaters)
#  Remember to enter this on command line first:  module load libfast
#      (or, comment-out the "-lfast_mv" line below)
#FC   = ftn
#OPTS = -O3 -Ovector3 -Oscalar3 -Othread3 -h noomp
#LINKOPTS = -lfast_mv
#CPP  = cpp -C -P -traditional
#-----------------------------------------------------------------------------
#  multiple processors, distributed memory (MPI), Cray fortran compiler
#      (eg, NCSA's bluewaters)
#  Remember to enter this on command line first:  module load libfast
#      (or, comment-out the "-lfast_mv" line below)
#FC   = ftn
#OPTS = -O3 -Ovector3 -Oscalar3 -Othread3 -h noomp
#LINKOPTS = -lfast_mv
#CPP  = cpp -C -P -traditional
#DM   = -DMPI
#-----------------------------------------------------------------------------
#  multiple processors, shared memory (OpenMP), Cray fortran compiler
#      (eg, NCSA's bluewaters)
#  Remember to enter this on command line first:  module load libfast
#      (or, comment-out the "-lfast_mv" line below)
#FC   = ftn
#OPTS = -O3 -Ovector3 -Oscalar3 -Othread3 -h omp
#LINKOPTS = -lfast_mv
#CPP  = cpp -C -P -traditional
#DM   = -DMPI
#-----------------------------------------------------------------------------
#-- You shouldn't need to change anything below here
#-----------------------------------------------------------------------------

SRC   = constants.F \
	input.F \
	adv.F \
	adv_routines.F \
	anelp.F \
	azimavg.F \
	base.F \
	bc.F \
	cm1.F \
	cm1libs.F \
	comm.F \
	testcase_simple_phys.F \
	diff2.F \
	goddard.F \
	hifrq.F \
	init3d.F \
	init_physics.F \
	init_surface.F \
	init_terrain.F \
	interp_routines.F \
	kessler.F \
	lfoice.F \
	maxmin.F \
	misclibs.F \
	morrison.F \
	module_mp_nssl_2mom.F \
	param.F \
	parcel.F \
	pdef.F \
	pdcomp.F \
	poiss.F \
	sfcphys.F \
	singleton.F \
	radiation_driver.F \
	solve.F \
	sounde.F \
	sound.F \
	soundns.F \
	soundcb.F \
	statpack.F \
	stopcm1.F \
	thompson.F \
	module_mp_radar.F \
	turb.F \
	turbdiag.F \
	writeout.F \
	restart.F \
	writeout_nc.F \
	radlib3d.F \
	irrad3d.F \
	sorad3d.F \
	radtrns3d.F \
	getcape.F \
	ysu.F \
	sfclay.F \
	sfclayrev.F \
	slab.F \
	oml.F \
	module_ra_etc.F \
	module_ra_rrtmg_lw.F \
	module_ra_rrtmg_sw.F

OBJS = $(addsuffix .o, $(basename $(SRC)))

FFLAGS  =  $(OPTS)
AR      = ar cru

.SUFFIXES:
.SUFFIXES:      .F .f90 .o

all : cm1

cm1:			$(OBJS)
			$(FC) $(OBJS) $(FFLAGS) $(OUTPUTINC) $(OUTPUTLIB) $(LINKOPTS) -o ../run/cm1.exe
			$(AR) onefile.F $(SRC)
			mv onefile.F ../run

.F.o:
			$(CPP) $(DM) $(DP) $(ADV) $(OUTPUTOPT) $*.F > $*.f90
			$(FC) $(FFLAGS) $(OUTPUTINC) -c $*.f90

code:
			$(AR) onefile.F $(SRC)
			mv onefile.F ../run

clean:
			rm -f *.f90 *.o *.a *.mod

# DEPENDENCIES : only dependencies after this line (don't remove the word DEPENDENCIES)

adv.o: constants.o input.o pdef.o adv_routines.o
adv_routines.o: input.o constants.o pdef.o comm.o
anelp.o: constants.o input.o misclibs.o bc.o poiss.o
azimavg.o: input.o constants.o cm1libs.o
base.o: constants.o input.o bc.o comm.o goddard.o cm1libs.o getcape.o
bc.o: constants.o input.o
cm1.o: constants.o input.o param.o base.o init3d.o misclibs.o solve.o diff2.o turb.o statpack.o writeout.o restart.o radiation_driver.o radtrns3d.o turbdiag.o azimavg.o hifrq.o parcel.o init_physics.o init_surface.o
cm1libs.o: input.o constants.o
comm.o: input.o bc.o
diff2.o: constants.o input.o
goddard.o: constants.o input.o cm1libs.o
hifrq.o: input.o constants.o cm1libs.o
init3d.o:  constants.o input.o misclibs.o cm1libs.o bc.o comm.o module_mp_nssl_2mom.o poiss.o parcel.o
init_physics.o: constants.o input.o sfclay.o sfclayrev.o slab.o radtrns3d.o irrad3d.o goddard.o module_ra_rrtmg_lw.o module_ra_rrtmg_sw.o
init_surface.o: constants.o input.o oml.o
init_terrain.o: constants.o input.o bc.o comm.o adv_routines.o
interp_routines.o: constants.o input.o
irrad3d.o: radlib3d.o
kessler.o: constants.o input.o
lfoice.o: input.o
maxmin.o: input.o
misclibs.o: constants.o input.o goddard.o lfoice.o
module_mp_radar.o: module_ra_etc.o
module_ra_rrtmg_lw.o: module_ra_etc.o
module_ra_rrtmg_sw.o: module_ra_etc.o module_ra_rrtmg_lw.o
morrison.o: input.o constants.o
param.o: constants.o input.o init_terrain.o bc.o comm.o thompson.o morrison.o module_mp_nssl_2mom.o goddard.o lfoice.o
parcel.o: constants.o input.o cm1libs.o bc.o comm.o writeout_nc.o
pdef.o: input.o bc.o comm.o
pdcomp.o: constants.o input.o adv.o poiss.o
poiss.o: input.o singleton.o
radiation_driver.o: constants.o input.o bc.o radtrns3d.o module_ra_etc.o module_ra_rrtmg_lw.o module_ra_rrtmg_sw.o
radtrns3d.o: irrad3d.o sorad3d.o radlib3d.o
restart.o: constants.o input.o writeout_nc.o
sfcphys.o: constants.o input.o cm1libs.o
solve.o: constants.o input.o bc.o comm.o adv.o adv_routines.o diff2.o turb.o sound.o sounde.o soundns.o soundcb.o anelp.o misclibs.o kessler.o thompson.o morrison.o module_mp_nssl_2mom.o goddard.o lfoice.o testcase_simple_phys.o parcel.o pdcomp.o
sorad3d.o: radlib3d.o
sound.o: constants.o input.o misclibs.o bc.o comm.o
sounde.o: constants.o input.o misclibs.o bc.o comm.o
soundcb.o: constants.o input.o misclibs.o bc.o comm.o
soundns.o: constants.o input.o misclibs.o bc.o
statpack.o: constants.o input.o maxmin.o misclibs.o cm1libs.o writeout_nc.o
testcase_simple_phys.o: constants.o input.o
thompson.o: input.o module_mp_radar.o module_ra_etc.o
turb.o: constants.o input.o bc.o comm.o sfcphys.o sfclay.o sfclayrev.o slab.o oml.o ysu.o cm1libs.o
turbdiag.o: constants.o input.o interp_routines.o cm1libs.o getcape.o
writeout.o: constants.o input.o bc.o comm.o writeout_nc.o misclibs.o getcape.o
writeout_nc.o: constants.o input.o
