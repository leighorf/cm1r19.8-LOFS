#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

subroutine h5_prelim(xh,xf,yh,yf,zh,zf,pi0,th0,prs0,rho0,qv0,u0,v0)
    use ISO_C_BINDING !Why again??
    implicit none

    real, dimension(ib:ie),   intent(in) :: xh
    real, dimension(ib:ie+1), intent(in) :: xf
    real, dimension(jb:je),   intent(in) :: yh
    real, dimension(jb:je+1), intent(in) :: yf
    real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: zh,pi0,prs0,rho0,th0,qv0
    real, dimension(ib:ie+1,jb:je,kb:ke), intent(in) :: u0
    real, dimension(ib:ie,jb:je+1,kb:ke), intent(in) :: v0
    real, dimension(ib:ie,jb:je,kb:ke+1) :: zf

    integer itime,tmpint
    character(len=padtimeint), save :: fileindexname,totalindexname
    character(len=floatstringlen) :: floatindexname
    logical backing_store
    logical wr3d_once !ORF IWRITE3D
    integer(HID_T) plist_id,fcpl_id
    integer(HSIZE_T), DIMENSION(1) :: dims,count
    integer(HSSIZE_T), DIMENSION(1) :: offset

    integer info

    character(LEN=4),  parameter :: grid_group_name = 'grid' !for 3D files
    character(LEN=4),  parameter :: mesh_group_name = 'mesh' !for 3D files
    character(LEN=4),  parameter :: misc_group_name = 'misc' !for stuff that doesn't fit elsewhere
    character(LEN=9),  parameter :: basestate_group_name = 'basestate' !for 3D files
    character(LEN=11), parameter :: threed_basestate_group_name = '3Dbasestate' !for 3D files
    character(LEN=2),  parameter :: twod_group_name = '2D'         !for 3D files
    character(LEN=5),  parameter :: twod_swath_group_name = 'swath'         !for 3D files
    character(LEN=6),  parameter :: twod_static_group_name = 'static'         !for 3D files
    character(LEN=6),  parameter :: twodfull_group_name = '2Dfull' !for 2D files
    character(LEN=2),  parameter :: threed_group_name = '3D'       !for 3D files
! ORF Fuck it, just save all the namelist stuff using the same namelist nomenclature
    character(LEN=8),  parameter :: namelist_group_name = 'namelist'
    character(LEN=6),  parameter :: param0_group_name = 'param0'
    character(LEN=6),  parameter :: param1_group_name = 'param1'
    character(LEN=6),  parameter :: param2_group_name = 'param2'
    character(LEN=6),  parameter :: param3_group_name = 'param3'
    character(LEN=6),  parameter :: param4_group_name = 'param4'
    character(LEN=6),  parameter :: param5_group_name = 'param5'
    character(LEN=6),  parameter :: param6_group_name = 'param6'
    character(LEN=6),  parameter :: param7_group_name = 'param7'
    character(LEN=6),  parameter :: param8_group_name = 'param8'
    character(LEN=6),  parameter :: param9_group_name = 'param9'
    character(LEN=7),  parameter :: param10_group_name = 'param10'
    character(LEN=7),  parameter :: param11_group_name = 'param11'
    character(LEN=7),  parameter :: param12_group_name = 'param12'
    character(LEN=12),  parameter :: param_wforce_group_name = 'param_wforce'
    character(LEN=12),  parameter :: zfp_accuracy_group_name = 'zfp_accuracy'
    character(LEN=6),  parameter :: orf_io_group_name = 'orf_io'

! ORF 6/2/12 for now ignore extra stagger point
    real, dimension(1:myMCMni) :: xhMCM
    real, dimension(1:myMCMni) :: xfMCM !+1
    real, dimension(1:myMCMnj) :: yhMCM
    real, dimension(1:myMCMnj) :: yfMCM !+1

!   if(dowr) then 
!       write(outfile,*) "  Beginning history file output cycle..."
!       call FFLUSH(outfile)
!   endif

102 format(i5.5)
103 format(f0.7)

! Sticking with floating point and hoping for the best

! We write our file when file is closed
    backing_store = .true.

!   blocksize is set above to 512 MB 

1720 format("Flushing LOFS data to disk at t = ",f9.3)
1729 format("New (empty) LOFS files created on disk at t = ",f9.3)
1730 format("Done flushing LOFS data to disk at t = ",f9.3)

!print *,myid,"PRELIM: iamio = ",iamio,"wr3d = ",wr3d,"iwrite3d = ",iwrite3d, "firstvisit = ",firstvisit, "newcycle = ",newcycle

    iamwriting3d: if (iamio.and.wr3d.and.iwrite3d) then
        firstvis: if (firstvisit) then
            i3d_time_index = 0
!           wr3dindex = 0
! not for restarts!
            threedbytes = 0

            write(fileindexname,102)i3d_time_index
!           write(totalindexname,102)wr3dindex
            write(floatindexname,103)iotime
            call h5_file_op(op_mk3dfilename,iotime)
            CALL h5pcreate_f(H5P_FILE_ACCESS_F, plist_id, ierr); check_err(ierr)
            CALL h5pset_fclose_degree_f(plist_id, H5F_CLOSE_SEMI_F, ierr); check_err(ierr)
            CALL h5pset_fapl_core_f(plist_id, blocksize, backing_store, ierr); check_err(ierr)

            call h5pcreate_f(H5P_FILE_CREATE_F,fcpl_id,ierr);check_err(ierr)
            call h5Pset_userblock_f(fcpl_id,userblock_size,ierr);check_err(ierr) !ORF we will stick namelist.input and other useful things here

            call h5fcreate_f(trim(filename),H5F_ACC_TRUNC_F,file_3d_id,ierr,creation_prp=fcpl_id,access_prp=plist_id);check_err(ierr)
            CALL h5pclose_f(fcpl_id, ierr); check_err(ierr)
            CALL h5pclose_f(plist_id, ierr); check_err(ierr)
            if(iprintinfo) write(6,1729) iotime
            if(iprintinfo) call FFLUSH(6)
    
            call h5gcreate_f(file_3d_id,grid_group_name,grid_group_id,ierr); check_err(ierr)
            if(ierr.lt.0) then
                  if(myid.eq.0)print *, file_3d_id,grid_group_name,grid_group_id
                  call stopcm1
            endif
            call h5gcreate_f(file_3d_id,mesh_group_name,mesh_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,misc_group_name,misc_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,basestate_group_name,basestate_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,threed_basestate_group_name,threed_basestate_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,namelist_group_name,namelist_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param0_group_name,param0_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param1_group_name,param1_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param2_group_name,param2_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param3_group_name,param3_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param4_group_name,param4_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param5_group_name,param5_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param6_group_name,param6_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param7_group_name,param7_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param8_group_name,param8_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param9_group_name,param9_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param10_group_name,param10_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param11_group_name,param11_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param12_group_name,param12_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param_wforce_group_name,param_wforce_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,zfp_accuracy_group_name,zfp_accuracy_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,orf_io_group_name,orf_io_group_id,ierr); check_err(ierr)
        
            call h5gcreate_f(file_3d_id,fileindexname,fileindex_group_id,ierr) !Our 2d and 3d fields are inside the index group now
            call h5gcreate_f(fileindex_group_id,twod_group_name,twod_group_id,ierr); check_err(ierr)
            call h5gcreate_f(twod_group_id,twod_swath_group_name,twod_swath_group_id,ierr); check_err(ierr) !added swaths
            call h5gcreate_f(twod_group_id,twod_static_group_name,twod_static_group_id,ierr); check_err(ierr) !added static 2d
            call h5gcreate_f(fileindex_group_id,threed_group_name,threed_group_id,ierr) ; check_err(ierr)
            call h5lcreate_soft_f(fileindexname,file_3d_id,trim(floatindexname),ierr);check_err(ierr)
        else if (newcycle) then
            call h5gclose_f(grid_group_id,ierr); check_err(ierr)
            call h5gclose_f(mesh_group_id,ierr); check_err(ierr)
            call h5gclose_f(misc_group_id,ierr); check_err(ierr)
            call h5gclose_f(basestate_group_id,ierr); check_err(ierr)
            call h5gclose_f(threed_basestate_group_id,ierr); check_err(ierr)
            call h5gclose_f(param0_group_id,ierr); check_err(ierr)
            call h5gclose_f(param1_group_id,ierr); check_err(ierr)
            call h5gclose_f(param2_group_id,ierr); check_err(ierr)
            call h5gclose_f(param3_group_id,ierr); check_err(ierr)
            call h5gclose_f(param4_group_id,ierr); check_err(ierr)
            call h5gclose_f(param5_group_id,ierr); check_err(ierr)
            call h5gclose_f(param6_group_id,ierr); check_err(ierr)
            call h5gclose_f(param7_group_id,ierr); check_err(ierr)
            call h5gclose_f(param8_group_id,ierr); check_err(ierr)
            call h5gclose_f(param9_group_id,ierr); check_err(ierr)
            call h5gclose_f(param10_group_id,ierr); check_err(ierr)
            call h5gclose_f(param11_group_id,ierr); check_err(ierr)
            call h5gclose_f(param12_group_id,ierr); check_err(ierr)
            call h5gclose_f(param_wforce_group_id,ierr); check_err(ierr)
            call h5gclose_f(zfp_accuracy_group_id,ierr); check_err(ierr)
            call h5gclose_f(orf_io_group_id,ierr); check_err(ierr)
            call h5gclose_f(namelist_group_id,ierr); check_err(ierr)
            call h5gclose_f(twod_static_group_id,ierr); check_err(ierr)
            call h5gclose_f(twod_swath_group_id,ierr); check_err(ierr)
            call h5gclose_f(twod_group_id,ierr); check_err(ierr)
            call h5gclose_f(threed_group_id,ierr); check_err(ierr)
            call h5gclose_f(fileindex_group_id,ierr); check_err(ierr)
            if(iprintinfo) write(*,1720)iotime
            if(iprintinfo) call FFLUSH(6)
            call h5fclose_f(file_3d_id,ierr); check_err(ierr) !Everything should get flushed to disk here
!Free any memory blobs that may be accumulating (avoid OOM)
!Could also call h5fget_obj_count_f(H5F_OBJ_ALL,H5F_OBJ_ALL_F,obj_count)
!obj_count should be zero unless we accidentally did not close all
!groups/datasets (see h5fclose - "delayed close")
            call h5garbage_collect_f(ierr); check_err(ierr)
            if(iprintinfo) write(*,1730)iotime
            if(iprintinfo) call FFLUSH(6)

            i3d_time_index = 0
            wr3dindex = wr3dindex + 1
            write(fileindexname,102)i3d_time_index
!           write(totalindexname,102)wr3dindex
            write(floatindexname,103)iotime
            call h5_file_op(op_mk3dfilename,iotime)
            CALL h5pcreate_f(H5P_FILE_ACCESS_F, plist_id, ierr); check_err(ierr)
            call h5pcreate_f(H5P_FILE_CREATE_F,fcpl_id,ierr);check_err(ierr)
            call h5Pset_userblock_f(fcpl_id,userblock_size,ierr);check_err(ierr) !ORF we will stick namelist.input and other useful things here
            CALL h5pset_fclose_degree_f(plist_id, H5F_CLOSE_SEMI_F, ierr); check_err(ierr)
            CALL h5pset_fapl_core_f(plist_id, blocksize, backing_store, ierr); check_err(ierr)
            if(iprintinfo) write(6,1729) iotime
            if(iprintinfo) call FFLUSH(6)

            call h5fcreate_f(trim(filename),H5F_ACC_TRUNC_F,file_3d_id,ierr,creation_prp=fcpl_id,access_prp=plist_id);check_err(ierr)
            CALL h5pclose_f(fcpl_id, ierr); check_err(ierr)
            CALL h5pclose_f(plist_id, ierr); check_err(ierr)
            threedbytes = 0

            call h5gcreate_f(file_3d_id,grid_group_name,grid_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,mesh_group_name,mesh_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,misc_group_name,misc_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,basestate_group_name,basestate_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,threed_basestate_group_name,threed_basestate_group_id,ierr); check_err(ierr)
            call h5gcreate_f(file_3d_id,fileindexname,fileindex_group_id,ierr);check_err(ierr)
            call h5gcreate_f(file_3d_id,namelist_group_name,namelist_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param0_group_name,param0_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param1_group_name,param1_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param2_group_name,param2_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param3_group_name,param3_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param4_group_name,param4_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param5_group_name,param5_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param6_group_name,param6_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param7_group_name,param7_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param8_group_name,param8_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param9_group_name,param9_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param10_group_name,param10_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param11_group_name,param11_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param12_group_name,param12_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,param_wforce_group_name,param_wforce_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,zfp_accuracy_group_name,zfp_accuracy_group_id,ierr); check_err(ierr)
            call h5gcreate_f(namelist_group_id,orf_io_group_name,orf_io_group_id,ierr); check_err(ierr)
!           if(fileindexname.ne.totalindexname) then
!               call h5lcreate_soft_f(fileindexname,file_3d_id,totalindexname,ierr);check_err(ierr)
!           endif
            call h5lcreate_soft_f(fileindexname,file_3d_id,trim(floatindexname),ierr);check_err(ierr)
            call h5gcreate_f(fileindex_group_id,twod_group_name,twod_group_id,ierr);check_err(ierr)
            call h5gcreate_f(twod_group_id,twod_swath_group_name,twod_swath_group_id,ierr); check_err(ierr) !added swaths
            call h5gcreate_f(twod_group_id,twod_static_group_name,twod_static_group_id,ierr); check_err(ierr) !added static 2d
            call h5gcreate_f(fileindex_group_id,threed_group_name,threed_group_id,ierr); check_err(ierr)
        else !Close current time group, open next one
            call h5gclose_f(twod_static_group_id,ierr); check_err(ierr)
            call h5gclose_f(twod_swath_group_id,ierr); check_err(ierr)
            call h5gclose_f(twod_group_id,ierr); check_err(ierr)
            call h5gclose_f(threed_group_id,ierr); check_err(ierr)
            call h5gclose_f(fileindex_group_id,ierr); check_err(ierr)
            i3d_time_index = i3d_time_index + 1
            wr3dindex = wr3dindex + 1
            write(fileindexname,102)i3d_time_index
!           write(totalindexname,102)wr3dindex
            write(floatindexname,103)iotime
            call h5gcreate_f(file_3d_id,fileindexname,fileindex_group_id,ierr); check_err(ierr)
!           if(fileindexname.ne.totalindexname) then
!               call h5lcreate_soft_f(fileindexname,file_3d_id,totalindexname,ierr);check_err(ierr)
!           endif
            call h5lcreate_soft_f(fileindexname,file_3d_id,trim(floatindexname),ierr);check_err(ierr)
            call h5gcreate_f(fileindex_group_id,twod_group_name,twod_group_id,ierr); check_err(ierr)
            call h5gcreate_f(twod_group_id,twod_swath_group_name,twod_swath_group_id,ierr); check_err(ierr) !added swaths
            call h5gcreate_f(twod_group_id,twod_static_group_name,twod_static_group_id,ierr); check_err(ierr) !added static 2d
            call h5gcreate_f(fileindex_group_id,threed_group_name,threed_group_id,ierr); check_err(ierr)
        endif firstvis

!       call writetimeindex_unlimited(file_3d_id,i3d_time_index,itime)
        call writetimeindex_unlimited(file_3d_id,i3d_time_index,iotime)
! ORF not sure where the different name came from
!       call writetime_unlimited(file_3d_id,i3d_time_index,itime)

    endif iamwriting3d


!ORF probably a good idea because some nodes will take a lot longer to flush, we have to sync eventually
    if (newcycle) then
          call mpi_barrier(MPI_COMM_CM1,ierr)
          check_err(ierr)
    endif

! ORF IWRITE3D 
! declare new boolean: wr3d_once = (iamio.and.wr3d.and.iwrite3d.and.(firstvisit.or.newcycle))

    wr3d_once=(iamio.and.wr3d.and.iwrite3d.and.(firstvisit.or.newcycle))

write_3d_once:    if (wr3d_once) then
        varname='dx'
        description='grid spacing in the x direction. If E/W grid stretching, this should be somehwat representative'
        units='meters'
        call h5_write_val_iamio(mesh_group_id,floatval=dx)
    
        varname='dy'
        description='grid spacing in the y direction. If N/S grid stretching, this should be somehwat representative'
        units='meters'
        call h5_write_val_iamio(mesh_group_id,floatval=dy)
    
        varname='dz'
        description='grid spacing in the z direction. If grid stretching, this should be somehwat representative'
        units='meters'
        call h5_write_val_iamio(mesh_group_id,floatval=dz)
    
        varname='nx'
        description='number of gridpoints spanning the east/west direction of full the model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=nx)
    
        varname='ny'
        description='number of gridpoints spanning the north/south direction of full the model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=ny)
    
        varname='nz'
        description='number of gridpoints spanning the vertical extent of the full the model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=nz)
    
        varname='x0'
        description='index of westmost point of 3d field in this hdf5 file with respect to full model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMx0)
    
        varname='x1'
        description='index of eastmost point of 3d field in this hdf5 file with respect to full model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMx1)
    
        varname='y0'
        description='index of southmost point of 3d field in this hdf5 file with respect to full model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMy0)
    
        varname='y1'
        description='index of northmost point of 3d field in this hdf5 file with respect to full model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMy1)

        varname='nkwrite_val'
        description='Top index, as we often do not save up to nz'
        units='index'
        if(save_full_vertical_extent) then
           call h5_write_val_iamio  (misc_group_id,intval=nk)
        else
           call h5_write_val_iamio  (misc_group_id,intval=nkwrite_val)
        endif

        varname='dt_long'
        description='The model long time step. This is a 32 bit float in r16.'
        units='s'
        call h5_write_val_iamio  (misc_group_id,floatval=real(dtl_dbl_orf))
    
        varname='kdiff6'
        description='Coefficient of sixth order diffusion filter (only written if used)'
        units='s'
        if(wr3d_once.and.idiff.eq.1.and.difforder.eq.6) call h5_write_val_iamio  (misc_group_id,floatval=kdiff6)
    
        varname='umove'
        description='box motion in x direction (subtracted off the sounding)'
        units='meters per second'
        call h5_write_val_iamio(mesh_group_id,floatval=umove)
    
        varname='vmove'
        description='box motion in y direction (subtracted off the sounding)'
        units='meters per second'
        call h5_write_val_iamio(mesh_group_id,floatval=vmove)

        varname='cores_per_MCM'
        description='cores per MCM'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=cores_per_MCM)

        varname='MCMnx'
        description='number of MCMs in x'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=MCMnx)

        varname='MCMny'
        description='number of MCMs in y'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=MCMny)

        varname='myMCMid'
        description='The MCM id of this file'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMid)
    
        varname='myi'
        description='east/west index of hdf5 file in 2d decomposition. (1 < myi <= nodex)'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=MCMi)
    
        varname='myj'
        description='north/south index of hdf5 file in 2d decomposition. (1 < myj <= nodej)'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=MCMj)
    
        varname='ni'
        description='number of gridpoints in east/west direction in this hdf5 file for 2d and 3d data'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMni)
    
        varname='nj'
        description='number of gridpoints in north/south direction in this hdf5 file for 2d and 3d data'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=myMCMnj)
    
        varname='nodex'
        description='number of hdf5 files spanning the full east/west extent of the model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=MCMnx)
    
        varname='nodey'
        description='number of hdf5 files spanning the full north/south extent of the model domain'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=MCMny)
    
        varname='corex'
        description='number of cores in the x direction on a node'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=corex)
    
        varname='corey'
        description='number of cores in the y direction on a node'
        units='index'
        call h5_write_val_iamio  (grid_group_id,intval=corey)
    
    ! ORF Note: base state 1d arrays assume no terrain such that any vertical column anywhere in domain could be used
    
        varname='u0'
        description='U (E/W wind) base state, (i.e., from sounding)'
        units='m/s'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,u0(1,1,1:nz),nz,dims,count,offset)
    
        varname='v0'
        description='V (N/S wind) base state, (i.e., from sounding)'
        units='m/s'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,v0(1,1,1:nz),nz,dims,count,offset)
    
        varname='pres0'
        description='Pressure base state, (i.e., from sounding)'
        units='dimensionless'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,prs0(1,1,1:nz),nz,dims,count,offset)
    
        varname='pi0'
        description='Exner base state, (i.e., from sounding)'
        units='dimensionless'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,pi0(1,1,1:nz),nz,dims,count,offset)
        
        varname='th0'
        description='potential temperature base state, (i.e., from sounding)'
        units='K'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,th0(1,1,1:nz),nz,dims,count,offset)
    
        varname='rh0'
        description='density base state, (i.e., from sounding)'
        units='kg/m^3'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,rho0(1,1,1:nz),nz,dims,count,offset)
    
        varname='qv0'
        description='mixing ratio base state, (i.e., from sounding)'
        units='kg/kg'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(basestate_group_id,qv0(1,1,1:nz),nz,dims,count,offset)
    
        varname='zh'
        description='height AGL of scalars'
        units='m'
        dims(1)=nz;count(1)=nz;offset(1)=0
        call h5_write_1d_float_iamio(mesh_group_id,zh(1,1,1:nz),nz,dims,count,offset)
    
        varname='zf'
        description='height AGL of w (on staggered C grid)'
        units='m'
        dims(1)=nz+1;count(1)=nz+1;offset(1)=0
        call h5_write_1d_float_iamio(mesh_group_id,zf(1,1,1:nz+1),nz+1,dims,count,offset)
    
        varname='yhfull'
        description='N/S location of scalar points for full domain (model uses Arakawa C grid)'
        units='meters'
        dims(1)=ny; count(1)=ny; offset(1)=0
    
        call h5_write_1d_float_iamio(mesh_group_id,yhfull(1:ny),ny,dims,count,offset)
    
        varname='xhfull'
        description='E/W location of scalar points for full domain (model uses Arakawa C grid)'
        units='meters'
        dims(1)=nx; count(1)=nx; offset(1)=0
        call h5_write_1d_float_iamio(mesh_group_id,xhfull(1:nx),nx,dims,count,offset)
    
        varname='yffull'
        description='N/S location of v points for full domain (model uses Arakawa C grid)'
        units='meters'
        dims(1)=ny+1; count(1)=ny+1; offset(1)=0
    
        call h5_write_1d_float_iamio(mesh_group_id,yffull(1:ny+1),ny+1,dims,count,offset)
    
        varname='xffull'
        description='E/W location of u points for full domain (model uses Arakawa C grid)'
        units='meters'
        dims(1)=nx+1; count(1)=nx+1; offset(1)=0
        call h5_write_1d_float_iamio(mesh_group_id,xffull(1:nx+1),nx+1,dims,count,offset)

! ORF 2019-10-07 Now we save namelist stuff in LOFS files, hooray.

! ORF save all values even where I save stuff elsewhere (grid and mesh groups).

        varname='nx'
        description='number of scalar grid points in x'
        units='#'
        call h5_write_val_iamio(param0_group_id,intval=nx)

        varname='ny'
        description='number of scalar grid points in y'
        units='#'
        call h5_write_val_iamio(param0_group_id,intval=ny)

        varname='nz'
        description='number of scalar grid points in z'
        units='#'
        call h5_write_val_iamio(param0_group_id,intval=nz)

        varname='nodex'
        description='number of MPI ranks x'
        units='#'
        call h5_write_val_iamio(param0_group_id,intval=nodex)

        varname='nodey'
        description='number of MPI ranks y'
        units='#'
        call h5_write_val_iamio(param0_group_id,intval=nodey)

        varname='dx'
        description='constant grid spacing in EW direction if stretch_x=0'
        units='m'
        call h5_write_val_iamio(param1_group_id,floatval=dx)

        varname='dy'
        description='constant grid spacing in NS direction if stretch_y=0'
        units='m'
        call h5_write_val_iamio(param1_group_id,floatval=dy)

        varname='dz'
        description='constant vertical grid spacing if stretch_z=0'
        units='m'
        call h5_write_val_iamio(param1_group_id,floatval=dz)

        varname='dtl'
        description='THIS VALUE IS IGNORED... see orf_io/dtl_dbl_orf for actual time step'
        units='s'
        call h5_write_val_iamio(param1_group_id,floatval=dtl)

        varname='timax'
        description='Time to stop model'
        units='s'
        call h5_write_val_iamio(param1_group_id,floatval=timax)

        varname='tapfrq'
        description='Time interval between LOFS history data saves'
        units='s'
        call h5_write_val_iamio(param1_group_id,floatval=tapfrq)

        varname='rstfrq'
        description='Time interval between restart/checkpoint saves'
        units='s'
        call h5_write_val_iamio(param1_group_id,floatval=rstfrq)

        varname='statfrq'
        description='Time interval between statistics output to stdio'
        units='s'
        call h5_write_val_iamio(param1_group_id,floatval=statfrq)

        varname='prclfrq'
        description='Time interval to save parcel data. Negative value means every time step'
        units='s'
        call h5_write_val_iamio(param1_group_id,floatval=prclfrq)

        varname='dtl_dbl_orf'
        description='model time step'
        units='s'
        call h5_write_val_iamio(orf_io_group_id,doubleval=dtl_dbl_orf)

        varname='numconcfreq'
        description='number concentration save interval'
        units='s'
        call h5_write_val_iamio(orf_io_group_id,floatval=numconcfreq)

        varname='time_levels_per_histfile'
        description='Time levels per LOFS file'
        units='s'
        call h5_write_val_iamio(orf_io_group_id,intval=time_levels_per_histfile)

!ORF there is no H5T_NATIVE_LOGICAL type, so we convert fortran logical to an integer, 0=false 1=true
        varname='save_full_domain'
        description='Are we saving full horizontal extent of domain?'
        units='boolean'
        if(save_full_domain) then; tmpint=1; else; tmpint=0; endif
        call h5_write_val_iamio(orf_io_group_id,intval=tmpint)

        varname='save_full_vertical_extent'
        description='Are we saving full vertical extent of domain?'
        units='boolean'
        if(save_full_vertical_extent) then; tmpint=1; else; tmpint=0; endif
        call h5_write_val_iamio(orf_io_group_id,intval=tmpint)

        varname='save_x0'
        description='Requested save_x0'
        units='index'
        call h5_write_val_iamio(orf_io_group_id,intval=save_x0)

        varname='save_x1'
        description='Requested save_x1'
        units='index'
        call h5_write_val_iamio(orf_io_group_id,intval=save_x1)

        varname='save_y0'
        description='Requested save_y0'
        units='index'
        call h5_write_val_iamio(orf_io_group_id,intval=save_y0)

        varname='save_y1'
        description='Requested save_y1'
        units='index'
        call h5_write_val_iamio(orf_io_group_id,intval=save_y1)

        varname='nkwrite_val'
        description='Actual top (vertical) index saved (we often do not save up to nz)'
        units='index'
        if(save_full_vertical_extent) then
           call h5_write_val_iamio  (orf_io_group_id,intval=nk)
        else
           call h5_write_val_iamio  (orf_io_group_id,intval=nkwrite_val)
        endif

        varname='prespert_swath_start_time'
        description='Model time when we start collecting pressure swath data (to avoid initial pulse)'
        units='s'
        call h5_write_val_iamio(orf_io_group_id,floatval=prespert_swath_start_time)

        varname='u_acc'
        description='u zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=u_acc)

        varname='v_acc'
        description='v zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=v_acc)
    
        varname='w_acc'
        description='w zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=w_acc)

        varname='thrhopert_acc'
        description='thrhopert zfp accuracy parameter'
        units='K'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=thrhopert_acc)

        varname='thpert_acc'
        description='thpert zfp accuracy parameter'
        units='K'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=thpert_acc)

        varname='prespert_acc'
        description='prespert zfp accuracy parameter'
        units='hPa'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=prespert_acc)

        varname='km_acc'
        description='km zfp accuracy parameter'
        units='m^2/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=km_acc)

        varname='kh_acc'
        description='kh zfp accuracy parameter'
        units='m^2/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=kh_acc)

        varname='rhopert_acc'
        description='rhopert zfp accuracy parameter'
        units='kg/m^3'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=rhopert_acc)

        varname='dbz_acc'
        description='dbz zfp accuracy parameter'
        units='dBZ'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=dbz_acc)

        varname='tke_acc'
        description='tke zfp accuracy parameter'
        units='kg m^2/s^2'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=tke_acc)

        varname='qvpert_acc'
        description='qvpert zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qvpert_acc)

        varname='qc_acc'
        description='qc zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qc_acc)

        varname='qi_acc'
        description='qi zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qi_acc)

        varname='qr_acc'
        description='qr zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qr_acc)

        varname='qs_acc'
        description='qs zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qs_acc)

        varname='qg_acc'
        description='qg zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qg_acc)

        varname='nci_acc'
        description='nci zfp accuracy parameter'
        units='/m3'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=nci_acc)

        varname='ncs_acc'
        description='ncs zfp accuracy parameter'
        units='/m3'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=ncs_acc)

        varname='ncr_acc'
        description='ncr zfp accuracy parameter'
        units='/m3'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=ncr_acc)

        varname='ncg_acc'
        description='ncg zfp accuracy parameter'
        units='/m3'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=ncg_acc)

        varname='uinterp_acc'
        description='uinterp zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=uinterp_acc)

        varname='vinterp_acc'
        description='vinterp zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=vinterp_acc)

        varname='winterp_acc'
        description='winterp zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=winterp_acc)

        varname='upert_acc'
        description='upert zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=upert_acc)

        varname='vpert_acc'
        description='vpert zfp accuracy parameter'
        units='m/s'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=vpert_acc)

        varname='th_acc'
        description='th zfp accuracy parameter'
        units='K'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=th_acc)

        varname='prs_acc'
        description='prs zfp accuracy parameter'
        units='hPa'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=prs_acc)

        varname='pi_acc'
        description='pi zfp accuracy parameter'
        units='#'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=pi_acc)

        varname='pipert_acc'
        description='pipert zfp accuracy parameter'
        units='#'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=pipert_acc)

        varname='rho_acc'
        description='rho zfp accuracy parameter'
        units='kg/m^3'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=rho_acc)

        varname='qv_acc'
        description='qv zfp accuracy parameter'
        units='g/kg'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=qv_acc)

        varname='xvort_acc'
        description='xvort zfp accuracy parameter'
        units='s^-1'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=xvort_acc)

        varname='yvort_acc'
        description='yvort zfp accuracy parameter'
        units='s^-1'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=yvort_acc)

        varname='zvort_acc'
        description='zvort zfp accuracy parameter'
        units='s^-1'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=zvort_acc)

        varname='vortmag_acc'
        description='vortmag zfp accuracy parameter'
        units='s^-1'
        call h5_write_val_iamio(zfp_accuracy_group_id,doubleval=vortmag_acc)

        varname='adapt_dt'
        description='adaptive time stepping?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=adapt_dt)

        varname='irst'
        description='Restart run?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=irst)

        varname='rstnum'
        description='Restart time'
        units='s'
        call h5_write_val_iamio(param2_group_id,intval=rstnum)

        varname='hadvorder'
        description='horizontal advection order of accuracy'
        units='integer'
        call h5_write_val_iamio(param2_group_id,intval=hadvorder)

        varname='vadvorder'
        description='vertical advection order of accuracy'
        units='integer'
        call h5_write_val_iamio(param2_group_id,intval=vadvorder)

        varname='pdscheme'
        description='ensure positive definiteness of moisture?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=pdscheme)

        varname='advweno'
        description='Advect scalars (except for pressure) with WENO scheme?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=advweno)

        varname='idiff'
        description='Include additional artificial diffusion?'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=idiff)

        varname='vdiff'
        description='When idiff=1, apply artificial diffusion to vertical direction?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=vdiff)

        varname='mdiff'
        description='When idiff=1 and diforder=6, apply monotonic version of artificial diffusion?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=mdiff)

        varname='difforder'
        description='Order of diffusion scheme?'
        units='integer'
        call h5_write_val_iamio(param2_group_id,intval=difforder)

! ORF TODO: /cmdline group with command line options

        varname='imoist'
        description='Moist run?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=imoist)

        varname='iturb'
        description='1=TKE 2=Smagorinsky'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=iturb)

        varname='tconfig'
        description='Turb coefficient calculation: 1=isotropic-ish mesh, 2=dz<<dx,dy'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=tconfig)

        varname='bcturbu'
        description='Lower/upper boundary condition for vertical diffusion of winds (u and v)'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=bcturbu)

        varname='bcturbs'
        description='Lower/upper boundary condition for vertical diffusion of all scalars'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=bcturbs)

        varname='dns'
        description='Dirct Numerical Simulation?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=dns)

!ORF should turn this on to see if pressure fluctuations go away
        varname='irdamp'
        description='Use upper-level Rayleigh damping zone (acts on u,v,w, and theta; user must set rdalpha and xhd) (0=no 1=yes)?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=irdamp)

!ORF and this
        varname='hrdamp'
        description='Use Rayleigh damping near lateral boundaries (acts on u,v,w, only; use rmust set rdalpha and xhd) (0=no 1=yes)?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=hrdamp)

        varname='psolver'
        description='Pressure solver. 1=truly compressible 2=KW ts fully explicit 3=KW ts vertically implicit 4=anelastic 5=incompressible?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=psolver)

        varname='nsound'
        description='Number of small (acoustic) time steps per large time step'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=nsound)

        varname='ptype'
        description='Microphysics. 1=Kessler 2=NASA-Goddard LFO 3=Thompson 4=Gilmore/Straka/Rasmussen LFO 5=Morrison 6=Rotunno-Emanuel(1987)?'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=ptype)

        varname='ihail'
        description='1=hail 0=graupel for large ice category, ptype 2,5'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=ihail)

        varname='iautoc'
        description='Include autoconversion of qc to qr when ptype=2?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=iautoc)

        varname='icor'
        description='Coriolis?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=icor)

        varname='pertcor'
        description='Apply Coriolis to perturbation winds only?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=pertcor)

        varname='neweqts'
        description='Use Bryan and Fritsch(2002) equations? 2 recommended.'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=neweqts)

        varname='idiss'
        description='Include dissipative heating?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=idiss)

        varname='efall'
        description='Include energy fallout term?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=efall)

!ORF should we check this out for AACP?
        varname='rterm'
        description='Include simple relaxation term that mimics atmospheric radiation?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=rterm)

        varname='wbc'
        description='West lateral boundary condition. 1=periodic 2=open-radiative 3=rigid walls'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=wbc)

        varname='ebc'
        description='East lateral boundary condition. 1=periodic 2=open-radiative 3=rigid walls'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=ebc)

        varname='sbc'
        description='South lateral boundary condition. 1=periodic 2=open-radiative 3=rigid walls'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=sbc)

        varname='nbc'
        description='North lateral boundary condition. 1=periodic 2=open-radiative 3=rigid walls'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=nbc)

        varname='irbc'
        description='Type of radiative scheme. 1=KW on large stapes, 2=KW on small steps 4=Durran-Klemp(1983)?'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=irbc)

!ORF could turn this on
        varname='roflux'
        description='Restrict outward flux?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=roflux)

        varname='isnd'
        description='Sounding option. 7=read from external file'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=isnd)

        varname='iwnd'
        description='Base state wind profile (ignored if isnd=7)'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=iwnd)

        varname='itern'
        description='Initial topography specifications'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=itern)

        varname='iinit'
        description='3D initialization option (ignored for LOFS which uses wforcing [see param_wforce])'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=iinit)

        varname='irandp'
        description='Include random theta perturbations in initial conditions?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=irandp)

        varname='ibalance'
        description='Specified balance assumption for initial 3D pressure field'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=ibalance)

        varname='iorigin'
        description='Specifies location of origin in horizontal space. 1=bottom left 2=center of domain?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=iorigin)

        varname='axisymm'
        description='Run axisymmetric version of model'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=axisymm)

        varname='imove'
        description='Move domain at constant speedl?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=imove)

        varname='iptra'
        description='Integrate passive fluid tracer? Must initialize pta array'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=iptra)

        varname='npt'
        description='Total number of passive fluid tracersr'
        units='index'
        call h5_write_val_iamio(param2_group_id,intval=npt)

        varname='iprcl'
        description='Integrate passive parcels?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=iprcl)

        varname='nparcels'
        description='Total number of parcels?'
        units='boolean'
        call h5_write_val_iamio(param2_group_id,intval=nparcels)

        varname='kdiff2'
        description='diffusion coefficient for difforder=2'
        units='m^2/s'
        call h5_write_val_iamio(param3_group_id,floatval=kdiff2)

        varname='kdiff6'
        description='Diffusion coefficient for difforder=6. Specified as a fraction of one-dimensional stability. Recommend value between 0.02 and 0.24'
        units='#'
        call h5_write_val_iamio(param3_group_id,floatval=kdiff6)

        varname='fcor'
        description='Coriolis parameter'
        units='s^-1'
        call h5_write_val_iamio(param3_group_id,floatval=fcor)

        varname='kdiv'
        description='coefficient for divergence damper. Value of ~0.1 is recommended'
        units='#'
        call h5_write_val_iamio(param3_group_id,floatval=kdiv)

!ORF we don't have this consideration for explicit vertical solver
        varname='alph'
        description='Off-centering coefficient for vertically implicit acoustic solver. Recommend 0.6'
        units='#'
        call h5_write_val_iamio(param3_group_id,floatval=alph)

        varname='rdalpha'
        description='Inverse e-folding time for upper-level Rayleigh damping layer. Recommend 1/300'
        units='s^-1'
        call h5_write_val_iamio(param3_group_id,floatval=rdalpha)

        varname='zd'
        description='Height above which Rayleigh damping is applied'
        units='m'
        call h5_write_val_iamio(param3_group_id,floatval=zd)

        varname='xhd'
        description='Distance from lateral boundaries where Rayleigh damping is applied'
        units='m'
        call h5_write_val_iamio(param3_group_id,floatval=xhd)

        varname='umove'
        description='Constant speed for domain translation in x-direction'
        units='m/s'
        call h5_write_val_iamio(param3_group_id,floatval=umove)

        varname='vmove'
        description='Constant speed for domain translation in y-direction'
        units='m/s'
        call h5_write_val_iamio(param3_group_id,floatval=vmove)

        varname='v_t'
        description='Constant terminal fall velocity of liquid water when ptype=6'
        units='m/s'
        call h5_write_val_iamio(param3_group_id,floatval=v_t)

        varname='l_h'
        description='Horizontal turbulence length scale when iturb=3'
        units='m'
        call h5_write_val_iamio(param3_group_id,floatval=l_h)

        varname='l_inf'
        description='Asymptotic vertical turbulence lengh scale used for iturb=3'
        units='m'
        call h5_write_val_iamio(param3_group_id,floatval=l_inf)

        varname='ndcnst'
        description='Specified cloud droplet concentration for default version of Morrison microphysics scheme.'
        units='cm^-3'
        call h5_write_val_iamio(param3_group_id,floatval=ndcnst)

        varname='radopt'
        description='Use atmospheric radiation code?'
        units='boolean'
        call h5_write_val_iamio(param11_group_id,intval=radopt)

        varname='dtrad'
        description='Time increment between calculation of radiation tendency'
        units='s'
        call h5_write_val_iamio(param11_group_id,floatval=dtrad)

        varname='ctrlat'
        description='Latitude'
        units='degrees'
        call h5_write_val_iamio(param11_group_id,floatval=ctrlat)

        varname='ctrlon'
        description='Longitude'
        units='degrees'
        call h5_write_val_iamio(param11_group_id,floatval=ctrlon)






        varname='year'
        description='Year at start of simulation'
        units='#'
        call h5_write_val_iamio(param11_group_id,intval=year)

        varname='month'
        description='Month at start of simulation'
        units='#'
        call h5_write_val_iamio(param11_group_id,intval=month)

        varname='day'
        description='Day at start of simulation'
        units='#'
        call h5_write_val_iamio(param11_group_id,intval=day)

        varname='hour'
        description='Hour at start of simulation'
        units='#'
        call h5_write_val_iamio(param11_group_id,intval=hour)

        varname='minute'
        description='Minute at start of simulation'
        units='#'
        call h5_write_val_iamio(param11_group_id,intval=minute)

        varname='second'
        description='Second at start of simulation'
        units='#'
        call h5_write_val_iamio(param11_group_id,intval=second)

        varname='idrag'
        description='Include surface drag?'
        units='boolean'
        call h5_write_val_iamio(param12_group_id,intval=idrag)

        varname='isfcflx'
        description='Include surface fluxes of heat and moisture?'
        units='boolean'
        call h5_write_val_iamio(param12_group_id,intval=isfcflx)

        varname='sfcmodel'
        description='Surface model (see README.namelist)'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=sfcmodel)

        varname='oceanmodel'
        description='Model for ocean conditions'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=oceanmodel)

        varname='ipbl'
        description='Use YSU PBL parameterization?'
        units='boolean'
        call h5_write_val_iamio(param12_group_id,intval=ipbl)

        varname='initsfc'
        description='Initial surface contitions'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=initsfc)

        varname='tsk0'
        description='Default initial value for skin temperature'
        units='K'
        call h5_write_val_iamio(param12_group_id,floatval=tsk0)

        varname='tmn0'
        description='Default nitial value for deep-layer temperature of soil'
        units='K'
        call h5_write_val_iamio(param12_group_id,floatval=tmn0)

        varname='xland0'
        description='Day at start of simulation'
        units='#'
        call h5_write_val_iamio(param12_group_id,floatval=xland0)


        varname='lu0'
        description='Default initial value for land-use index'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=lu0)

        varname='season'
        description='Which set of land-use conditions to use from LANDUSE.TBL file'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=season)




        varname='cecd'
        description='sfc exchange method'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=cecd)

        varname='pertflx'
        description='Use only perturbation winds for calculation of surface fluxes?'
        units='boolean'
        call h5_write_val_iamio(param12_group_id,intval=pertflx)

! ORF Surface fluxes must be on for this to be active
        varname='cnstce'
        description='Constant value of Ce for cecd=1 and isfcflx=1'
        units='#'
        call h5_write_val_iamio(param12_group_id,floatval=cnstce)

! ORF We've used this drag coefficient in all of our friction runs
        varname='cnstcd'
        description='Constant value of Cd if cecd=1 and idrag=1'
        units='#'
        call h5_write_val_iamio(param12_group_id,floatval=cnstcd)

        varname='isftcflx'
        description='Tropical storm term - see README.namelist'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=isftcflx)

        varname='iz0tlnd'
        description='When using sfcmodel=2, option for thermal roughness length'
        units='index'
        call h5_write_val_iamio(param12_group_id,intval=iz0tlnd)

        varname='oml_hml0'
        description='For oceanmodel=2, deep ocean mixed layer depth at initial time'
        units='m'
        call h5_write_val_iamio(param12_group_id,floatval=oml_hml0)

        varname='oml_gamma'
        description='For oceanmodel=2, default deep water lapse rate'
        units='K/m'
        call h5_write_val_iamio(param12_group_id,floatval=oml_gamma)

        varname='stretch_x'
        description='Use horizontally stretched grid in x?'
        units='index'
        call h5_write_val_iamio(param4_group_id,intval=stretch_x)

        varname='dx_inner'
        description='Smallest grid spacing'
        units='m'
        call h5_write_val_iamio(param4_group_id,floatval=dx_inner)
        
        varname='dx_outer'
        description='Largest grid spacing (at edge of domain)'
        units='m'
        call h5_write_val_iamio(param4_group_id,floatval=dx_outer)

        varname='nos_x_len'
        description='Length of the no-stretching part of domain'
        units='m'
        call h5_write_val_iamio(param4_group_id,floatval=nos_x_len)

        varname='tot_x_len'
        description='Total length of the domain in x'
        units='#'
        call h5_write_val_iamio(param4_group_id,floatval=tot_x_len)

        varname='stretch_y'
        description='Use horizontally stretched grid in y?'
        units='index'
        call h5_write_val_iamio(param5_group_id,intval=stretch_y)

        varname='dy_inner'
        description='Smallest grid spacing'
        units='m'
        call h5_write_val_iamio(param5_group_id,floatval=dy_inner)
        
        varname='dy_outer'
        description='Largest grid spacing (at edge of domain)'
        units='m'
        call h5_write_val_iamio(param5_group_id,floatval=dy_outer)

        varname='nos_y_len'
        description='Length of the no-stretching part of domain'
        units='m'
        call h5_write_val_iamio(param5_group_id,floatval=nos_y_len)

        varname='tot_y_len'
        description='Total length of the domain in y'
        units='#'
        call h5_write_val_iamio(param5_group_id,floatval=tot_y_len)

        varname='stretch_z'
        description='Use horizontally stretched grid in z?'
        units='index'
        call h5_write_val_iamio(param6_group_id,intval=stretch_z)

        varname='ztop'
        description='Total depth of domain'
        units='m'
        call h5_write_val_iamio(param6_group_id,floatval=ztop)
        
        varname='str_bot'
        description='Level where stretching begins'
        units='m'
        call h5_write_val_iamio(param6_group_id,floatval=str_bot)

        varname='str_top'
        description='Level where stretching ends'
        units='m'
        call h5_write_val_iamio(param6_group_id,floatval=str_top)

        varname='dz_bot'
        description='grid spacing at (and below) str_bot'
        units='m'
        call h5_write_val_iamio(param6_group_id,floatval=dz_bot)

        varname='dz_top'
        description='Grid spacing at (and above) str_top'
        units='m'
        call h5_write_val_iamio(param6_group_id,floatval=dz_top)

        varname='bc_wind'
        description='dns=1 top/bottom boundary conditions for horizontal winds'
        units='index'
        call h5_write_val_iamio(param7_group_id,intval=bc_wind)

        varname='bc_temp'
        description='dns=1 top/bottom boundary condition for theta'
        units='index'
        call h5_write_val_iamio(param7_group_id,intval=bc_temp)

        varname='ptc_top'
        description='dns=1 potential temperature closure for top of model'
        units='K or K/s'
        call h5_write_val_iamio(param7_group_id,floatval=ptc_top)

        varname='ptc_bot'
        description='dns=1 potential temperature closure for bottom of model'
        units='K or K/s'
        call h5_write_val_iamio(param7_group_id,floatval=ptc_bot)

        varname='viscosity'
        description='dns=1 Value for kinematic viscosity'
        units='m^2/s'
        call h5_write_val_iamio(param7_group_id,floatval=viscosity)

        varname='pr_num'
        description='dns=1 Prandtl number'
        units='#'
        call h5_write_val_iamio(param7_group_id,floatval=pr_num)

        varname='var1'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var1)

        varname='var2'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var2)

        varname='var3'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var3)

        varname='var4'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var4)

        varname='var5'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var5)

        varname='var6'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var6)

        varname='var7'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var7)

        varname='var8'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var8)

        varname='var9'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var9)

        varname='var10'
        description='User supplied variable'
        units='whatevah'
        call h5_write_val_iamio(param8_group_id,floatval=var10)

        varname='wforceon'
        description='Are we doing wforce?'
        units='boolean'
        if(wforceon) then; tmpint=1; else; tmpint=0; endif
        call h5_write_val_iamio(param_wforce_group_id,intval=tmpint)

        varname='wforceendtime'
        description='End time of w forcing'
        units='s'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforceendtime)

        varname='wforceendval'
        description='End value of updraft forcing following ramp up'
        units='m/s'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforceendval)

        varname='wforcealpha'
        description='Time to ramp up to end val'
        units='s'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforcealpha)

        varname='wforcexrad'
        description='X radius of w forcing'
        units='m'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforcexrad)

        varname='wforceyrad'
        description='Y radius of w forcing'
        units='m'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforceyrad)

        varname='wforcezrad'
        description='Z radius of w forcing'
        units='m'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforcezrad)

        varname='wforcexctr'
        description='X center of w forcing'
        units='#'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforcexctr)

        varname='wforceyctr'
        description='Y center of w forcing'
        units='#'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforceyctr)

        varname='wforcezctr'
        description='Z center of w forcing'
        units='#'
        call h5_write_val_iamio(param_wforce_group_id,floatval=wforcezctr)

    endif write_3d_once

!ORF iwrite3d just added here (these are different; 3d files containing global
!1d arrays)
    varname='yh'
    description='N/S location of scalar points (model uses Arakawa C grid)'
    units='meters'
    if (wr3d.and.(newcycle.or.firstvisit)) then
        if (myMCMlyrank.ne.MPI_UNDEFINED) then;call MPI_Gather (yh(1:nj),nj,MPI_REAL,yhMCM,nj,MPI_REAL,0,myMCMlycomm,ierr);check_err(ierr);endif
        dims(1)=myMCMnj; count(1)=myMCMnj; offset(1)=0
        if(iamio.and.iwrite3d)call h5_write_1d_float_iamio(mesh_group_id,   yhMCM,myMCMnj,dims,count,offset)
    endif

! ORF 6/2/12 for now ignore extra point in arrays with u, v extra staggered point

    varname='yf'
    description='N/S location of V points (model uses Arakawa C grid)'
    units='meters'
    if (wr3d.and.(newcycle.or.firstvisit)) then
        if (myMCMlyrank.ne.MPI_UNDEFINED) then;call MPI_Gather (yf(1:nj),nj,MPI_REAL,yfMCM,nj,MPI_REAL,0,myMCMlycomm,ierr);check_err(ierr);endif
        dims(1)=myMCMnj; count(1)=myMCMnj; offset(1)=0
        if(iamio.and.iwrite3d)call h5_write_1d_float_iamio(mesh_group_id,   yfMCM,myMCMnj,dims,count,offset)
    endif


    varname='xh'
    description='E/W location of scalar points (model uses Arakawa C grid)'
    units='meters'
    if (wr3d.and.(newcycle.or.firstvisit)) then
        if (myMCMbxrank.ne.MPI_UNDEFINED) then;call MPI_Gather (xh(1:ni),ni,MPI_REAL,xhMCM,ni,MPI_REAL,0,myMCMbxcomm,ierr);check_err(ierr);endif
        dims(1)=myMCMni; count(1)=myMCMni; offset(1)=0
        if(iamio.and.iwrite3d)call h5_write_1d_float_iamio(mesh_group_id,   xhMCM,myMCMni,dims,count,offset)
    endif

    varname='xf'
    description='E/W location of U points (model uses Arakawa C grid)'
    units='meters'
    if (wr3d.and.(newcycle.or.firstvisit)) then
        if (myMCMbxrank.ne.MPI_UNDEFINED) then;call MPI_Gather (xf(1:ni),ni,MPI_REAL,xfMCM,ni,MPI_REAL,0,myMCMbxcomm,ierr);check_err(ierr);endif
        dims(1)=myMCMni; count(1)=myMCMni; offset(1)=0
        if(iamio.and.iwrite3d)call h5_write_1d_float_iamio(mesh_group_id,   xfMCM,myMCMni,dims,count,offset)
    endif


end subroutine h5_prelim
