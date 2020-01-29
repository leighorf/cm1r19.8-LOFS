module module_lofs
use hdf5
use h5zzfp_props_f
use mpi_newcomm
implicit none
include 'input.incl'
include 'constants.incl'

#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

integer ::  myMCMid,myMCMcomm,myMCMgroup,mylocalid,MCMi,MCMj,MCMnx,MCMny,numMCM 
integer ::  myMCMni, myMCMnj,cores_per_MCM,myMCMbxcomm,myMCMbxrank,myfulloffseti,myfulloffsetj
integer ::  myMCMlycomm,myMCMlyrank,myMCMx0,myMCMx1,myMCMy0,myMCMy1,MCMrootrank,MCMrootcomm,rootonlyrank
integer ::  nitype,njtype,nxtype,nytype,ninjtype,ninjnktype,x1drank,y1drank,x1dcomm,y1dcomm
integer ::  localMCMrank,localMCMsize,new_mcm_comm,new_local_mcm_rank,new_myid,new_local_mcm_size,new_mcm_id

integer, parameter :: corex = COREX, corey = COREY ! Set in Makefile, # of cores in X and Y on a node
integer, parameter :: nfilesperwrite = NFILES_PER_WRITE !Set in makefile
integer, parameter :: nhistperdir = 1000
logical :: iamio,iwrite3d,iprintinfo,restart_file_exists
logical :: wr3d
logical :: dbg=.false.
integer :: myid_orig
!ORF wr3dindex no longer serves any purpose but to keep track of the number of
!history writes undertaken, which is not really useful for anything
integer :: wr3dindex
double precision :: iotime
real :: tapfrq_save,numconctime

namelist /orf_io/ dtl_dbl_orf,numconcfreq,use_dtinv,dtinv,save_full_domain,save_full_vertical_extent, &
save_all_times,save_x0,save_y0,save_y1,save_x1, nkwrite_val,wr2dfreq, &
time_levels_per_histfile,save_start_time,prespert_swath_start_time,uadjust,vadjust,adjust_box_speed_from_restart

double precision :: dtl_dbl_orf
logical :: use_dtinv,save_full_domain,save_full_vertical_extent,save_all_times
integer :: dtinv,save_x0, save_y0, save_y1, save_x1
integer :: nkwrite_val, time_levels_per_histfile
real :: numconcfreq,save_start_time,prespert_swath_start_time,wr2dfreq

namelist /zfp_accuracy/ u_acc,v_acc,w_acc,uinterp_acc,vinterp_acc,winterp_acc, &
upert_acc,vpert_acc,th_acc,thpert_acc,thrhopert_acc,prs_acc,prespert_acc,pi_acc,pipert_acc, &
rho_acc,rhopert_acc,tke_acc,km_acc,kh_acc,qv_acc,qvpert_acc,dbz_acc, &
qc_acc,qr_acc,qi_acc,qs_acc,qg_acc,nci_acc,ncr_acc,ncs_acc,ncg_acc, &
xvort_acc,yvort_acc,zvort_acc,vortmag_acc,zvort_tilt_acc,zvort_stretch_acc

double precision :: u_acc,v_acc,w_acc,uinterp_acc,vinterp_acc,winterp_acc, &
upert_acc,vpert_acc,th_acc,thpert_acc,thrhopert_acc,prs_acc,prespert_acc,pi_acc,pipert_acc, &
rho_acc,rhopert_acc,tke_acc,km_acc,kh_acc,qv_acc,qvpert_acc,dbz_acc, &
qc_acc,qr_acc,qi_acc,qs_acc,qg_acc,nci_acc,ncr_acc,ncs_acc,ncg_acc, &
xvort_acc,yvort_acc,zvort_acc,vortmag_acc,zvort_tilt_acc,zvort_stretch_acc

logical :: we_are_dumping_hist_data,we_are_doing_new_cycle,we_are_saving_2d_data,we_are_dumping_numconc_data
logical :: we_are_dumping_restarts

real, dimension(:), allocatable :: MCMrootranks,x1dranks,y1dranks,myMCMxranks,myMCMyranks
real, dimension (:,:), allocatable :: var2d
real, dimension (:,:,:), allocatable :: var3d
real, dimension (:,:,:), allocatable :: tmp1,dum5,dum6,dum7,dum8,dum9,dum10
real, dimension (:,:,:), allocatable :: q1mb,q2mb

integer, dimension(1) :: rootonlyranks

real, dimension(:), allocatable :: xhfull, yhfull     ! 1d mesh arrays that span entire domain
real, dimension(:), allocatable :: xffull, yffull     ! 1d mesh arrays that span entire domain for u, v
real, dimension (:), allocatable :: MCM3dbuf          ! buffer for gatherng 3D floats on a node
real, dimension (:), allocatable :: MCM2dbuf          ! buffer for gatherng 2D floats on a node
real, dimension (:,:,:), allocatable,target :: MCM3d  ! local 3D floats on a MPI rank
real, dimension (:,:), allocatable,target :: MCM2d    ! local 3D floats on a MPI rank
real, dimension (:,:,:,:), allocatable ::orfswaths    ! more swaths beyond the normal ones
integer, parameter :: norfswaths = 13                 ! number of orfswaths to malloc
integer, parameter :: strsize = 256                   ! 256 characters ought to be enough for anybody
integer, parameter :: padtimeint = 5                  ! zero-padded integer part of time
integer, parameter :: padtimefrac = 7                 ! Fractional time, if we are not saving every integer seconds
integer, parameter :: padnode = 7                     ! zero-padded node width for naming hdf files
integer, parameter :: op_mkhistdirs = 1               ! make base history directories
integer, parameter :: op_mkrestartdirs = 2            ! make base restart directories
integer, parameter :: op_mk3dfilename = 3             ! make cm1hdf5 filename
integer, parameter :: op_mk2dfilename = 4             ! make 2Dcm1hdf5 filename
integer, parameter :: op_mkrestartfilename = 5        ! make restart filename
integer(HSIZE_T), parameter :: userblock_size = 32768 ! user block size for stashing useful text at head of hdf files
integer, parameter :: floatstringlen=padtimeint+1+padtimefrac

character(len=strsize) filedir,newdir,dircmd,filename,shellcmd,varname,units,description,chid,cmdline_arg
character(len=strsize) executable_cmdline,namelist_cmdline,output_path_cmdline,output_basename_cmdline
character(len=strsize) restart_path_cmdline,restart_basename_cmdline

integer :: n_cmd_args
real :: droplet_breakup_diameter

logical :: firstvisit,newcycle,writingrestart,nobuffer,adjust_box_speed_from_restart

integer :: i3d_time_index
integer :: threedbytes  ! Keep track of how much raw 3D data written to buffered files
integer :: ksfc,k100,k200,k300,k400,k500,kw500,k1km, &
           kw1km,k2km,k3km,k4km,k5km,kw5km ! vertical indices for certain levels AGL
integer(HID_T) :: file_3d_id, file_2d_id
integer(HID_T) :: grid_group_id, mesh_group_id, misc_group_id, basestate_group_id, twod_group_id
integer(HID_T) :: twod_swath_group_id,twod_static_group_id, threed_group_id,threed_basestate_group_id
integer(HID_T) :: twodfull_id,twodfull_mesh_id,twodfull_grid_id,twodfull_base_id,fileindex_group_id,totalindex_link_id
integer(HID_T) :: namelist_group_id,param0_group_id,param1_group_id,param2_group_id,param3_group_id
integer(HID_T) :: param4_group_id,param5_group_id,param6_group_id,param7_group_id
integer(HID_T) :: param8_group_id,param9_group_id,param10_group_id,param11_group_id
integer(HID_T) :: param12_group_id,zfp_accuracy_group_id,orf_io_group_id,param_wforce_group_id
integer(SIZE_T), parameter :: blocksize = 536870912   ! 512 * 1024 * 1024 bytes (2**29)

#ifdef MICROBURST
real q1forc,q2forc,ot
real thrand,frand
#endif

double precision dbldt

real uadjust,vadjust

! ORF 3/13/18
! There is probably a more elegant way to handle this, but hey, it's
! Fortran. Rather than make this one big fat file with dozens of
! subroutines, we can break things up amongst individudal 'themed'
! files. Some makefile hacking was required. To build the code, you
! first must 'make newcomm' then 'make lofs'. Then you can 'make -j 8'
! or whatever and get a parallel build of cm1.

contains

include 'lofs-misc.f90'
include 'lofs-swaths.f90'
include 'lofs-hdfmisc.f90'
include 'lofs-hdfprelim.f90'
include 'lofs-hdfio.f90'
include 'lofs-restart.f90'
include 'lofs-writeout.f90'
include 'lofs-calc.f90'

end module module_lofs
