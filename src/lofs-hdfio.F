#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr, "myid= ",myid

subroutine wr1dsimpler (f_id,var,niwrite)
    implicit none
    integer rank,niwrite,ierr
    real, intent(in), dimension(niwrite) :: var
    integer(HID_T) :: f_id,dspace_id,dset_id
    integer(HSIZE_T), DIMENSION(1) :: dims
    if(myid.eq.0)print *,"varname = ",varname
    rank=1
    dims(1)=niwrite
    call h5screate_simple_f(rank,dims,dspace_id,ierr); check_err(ierr)
    call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr); check_err(ierr)
    call h5dwrite_f(dset_id, H5T_NATIVE_REAL, var, dims, ierr); check_err(ierr)
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    call h5sclose_f(dspace_id,ierr); check_err(ierr)
    return
end subroutine wr1dsimpler

subroutine wr1dsimpled (f_id,var,niwrite)
    implicit none
    integer rank,niwrite,ierr
    real*8, dimension(niwrite) :: var
    integer(HID_T) :: f_id,dspace_id,dset_id
    integer(HSIZE_T), DIMENSION(1) :: dims
    rank=1
    dims(1)=niwrite
    call h5screate_simple_f(rank,dims,dspace_id,ierr); check_err(ierr)
    call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
    call h5dwrite_f(dset_id, H5T_NATIVE_REAL, var, dims, ierr); check_err(ierr)
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    call h5sclose_f(dspace_id,ierr); check_err(ierr)
    return
end subroutine wr1dsimpled

subroutine wr2dsimpler (f_id,var,niwrite,njwrite)
    implicit none
    integer rank,niwrite,njwrite,ierr
    real, dimension(niwrite,njwrite) :: var
    integer(HID_T) :: f_id,dspace_id,dset_id
    integer(HSIZE_T), DIMENSION(2) :: dims
    rank=2
    dims(1)=niwrite
    dims(2)=njwrite
    call h5screate_simple_f(rank,dims,dspace_id,ierr); check_err(ierr)
    call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr); check_err(ierr)
    call h5dwrite_f(dset_id, H5T_NATIVE_REAL, var, dims, ierr); check_err(ierr)
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    call h5sclose_f(dspace_id,ierr); check_err(ierr)
    return
end subroutine wr2dsimpler

subroutine wr3dsimpler (f_id,var,niwrite,njwrite,nkwrite)
    implicit none
    integer rank,niwrite,njwrite,nkwrite,ierr
    real, dimension(niwrite,njwrite,nkwrite) :: var
    integer(HID_T) :: f_id,dspace_id,dset_id,chunk_id
    integer(HSIZE_T), DIMENSION(3) :: dims,chunkdims
    rank=3
    dims(1)=niwrite
    dims(2)=njwrite
    dims(3)=nkwrite
    call h5screate_simple_f(rank,dims,dspace_id,ierr); check_err(ierr)
    chunkdims(1)=niwrite
    chunkdims(2)=njwrite
!NOTE nk is passed to this routine, is not global nk
    if(nkwrite.ge.100) then
          chunkdims(3)=100
    else
          chunkdims(3)=nkwrite
    endif
    call h5pcreate_f(H5P_DATASET_CREATE_F,chunk_id,ierr)
    call h5pset_chunk_f(chunk_id,rank,chunkdims,ierr)
    call h5pset_deflate_f(chunk_id,9,ierr) ! <---- gzip level 9
    call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr,dcpl_id=chunk_id);check_err(ierr)
    call h5dwrite_f(dset_id, H5T_NATIVE_REAL, var, dims, ierr); check_err(ierr)
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    call h5sclose_f(dspace_id,ierr); check_err(ierr)
    call h5pclose_f (chunk_id,ierr);check_err(ierr)
    return
end subroutine wr3dsimpler

subroutine wr4dsimpler (f_id,var,niwrite,njwrite,nkwrite,nlwrite)
    implicit none
    integer rank,niwrite,njwrite,nkwrite,nlwrite,ierr
    real, dimension(niwrite,njwrite,nkwrite,nlwrite) :: var
    integer(HID_T) :: f_id,dspace_id,dset_id,chunk_id
    integer(HSIZE_T), DIMENSION(4) :: dims,chunkdims
    rank=4
    dims(1)=niwrite
    dims(2)=njwrite
    dims(3)=nkwrite
    dims(4)=nlwrite
    call h5screate_simple_f(rank,dims,dspace_id,ierr); check_err(ierr)
    chunkdims(1)=niwrite
    chunkdims(2)=njwrite
!NOTE nk is passed to this routine, is not global nk
    if(nkwrite.ge.100) then
          chunkdims(3)=100
    else
          chunkdims(3)=nkwrite
    endif
    chunkdims(4)=1 !The only thing we write in 4D is microphysics vars
    call h5pcreate_f(H5P_DATASET_CREATE_F,chunk_id,ierr)
    call h5pset_chunk_f(chunk_id,rank,chunkdims,ierr)
    call h5pset_deflate_f(chunk_id,9,ierr) ! <---- gzip level 9
    call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr,dcpl_id=chunk_id); check_err(ierr)
    call h5dwrite_f(dset_id, H5T_NATIVE_REAL, var, dims, ierr); check_err(ierr)
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    call h5sclose_f(dspace_id,ierr); check_err(ierr)
    call h5pclose_f (chunk_id,ierr);check_err(ierr)
    return
end subroutine wr4dsimpler

!-----------------------------------------------------------------------------------MARK
! This routine gathers data from all MPI ranks on a node (this assumes
! myMCMcomm is set correctly) and assembles it into a continuous chunk
! of memory that can be written to history files

subroutine h5_gather_3d(core3d,mcmtype)
    implicit none

    integer :: i,j,k,iix,iiy,ixcore,iycore,ioffset
    integer :: mcmtype
    real, intent(in), dimension(ni,nj,nk) :: core3d

    call MPI_Gather(core3d,1,mcmtype,MCM3dbuf,1,mcmtype,0,myMCMcomm,ierr);check_err(ierr)

    if (iamio.and.iwrite3d) then
!ORF this cannot be parallelized, as it reads a global (to a node) array sequentially. The
!only way to do it in parallel would be to read from MCM3dbuf concurrently between
!threads or to not do the gather first, but do normal message passing (bleah)
        do iycore=0,corey-1
            do ixcore=0,corex-1
                ioffset=ni*nj*nk*(ixcore + iycore*corex)
                do k=1,nk
                    do j=1,nj
                        do i=1,ni
                            iix = i + (ixcore*ni)
                            iiy = j + (iycore*nj)
                            ioffset=ioffset+1
                            MCM3d(iix,iiy,k) = MCM3dbuf(ioffset)
                        enddo
                    enddo
                enddo
            enddo
        enddo
    endif
    return
end subroutine h5_gather_3d

!-----------------------------------------------------------------------------------MARK
! This routine gathers 2d data from all MPI ranks on a node (this assumes
! myMCMcomm is set correctly) and assembles it into a continuous 2d chunk
! of memory that can be written to history files. This was added 4/29/19 in
! order to accommodate 2D swath/static writes within the 3D files (because 2D
! big writes are too slow for large core counts)

subroutine h5_gather_2d(core2d,mcmtype)
    implicit none

    integer :: i,j,iix,iiy,ixcore,iycore,ioffset
    integer :: mcmtype
    real, intent(in), dimension(ni,nj) :: core2d

    call MPI_Gather(core2d,1,mcmtype,MCM2dbuf,1,mcmtype,0,myMCMcomm,ierr);check_err(ierr)

    if (iamio.and.iwrite3d) then
        do iycore=0,corey-1
            do ixcore=0,corex-1
                ioffset=ni*nj*(ixcore + iycore*corex)
                do j=1,nj
                    do i=1,ni
                      iix = i + (ixcore*ni)
                      iiy = j + (iycore*nj)
                      ioffset=ioffset+1
                      MCM2d(iix,iiy) = MCM2dbuf(ioffset)
                    enddo
                enddo
            enddo
        enddo
    endif
    return
end subroutine h5_gather_2d

!-----------------------------------------------------------------------------------MARK

subroutine h5_write_val_iamio (f_id,intval,floatval,doubleval)
    implicit none

    integer(HSIZE_T), DIMENSION(1) :: strdims
    integer :: arank = 1
    integer(HSIZE_T), DIMENSION(1) :: adims = (/1/)
    integer(SIZE_T) :: stringlen

    integer, intent(in), optional :: intval
    real, intent(in), optional :: floatval
    double precision, intent(in), optional :: doubleval
    real value
    integer rank
    integer(HSIZE_T), DIMENSION(1) :: dims,count
    integer(HSSIZE_T), DIMENSION(1) :: offset
    integer(HID_T) :: f_id,dset_id,filespace_id,memspace_id,aspace_id,desc_id,desctype_id,unitstype_id,units_id
    logical is_integer,is_float,is_double

    is_integer = present(intval)
    is_float = present(floatval)
    is_double = present(doubleval)

    call h5screate_simple_f(arank,adims,aspace_id,ierr);check_err(ierr)
    call h5tcopy_f(H5T_NATIVE_CHARACTER,desctype_id,ierr);check_err(ierr)
    call h5tcopy_f(H5T_NATIVE_CHARACTER,unitstype_id,ierr);check_err(ierr)
    stringlen = len_trim(description)
    call h5tset_size_f(desctype_id,stringlen,ierr);check_err(ierr)
    stringlen = len_trim(units)
    call h5tset_size_f(unitstype_id,stringlen,ierr);check_err(ierr)
    rank=1
    strdims(1)=1
    dims(1)=1
    count(1)=1
    offset(1) = 0
    call h5screate_simple_f(rank,dims,filespace_id,ierr);check_err(ierr)

    if (is_integer) then
        call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,filespace_id,dset_id,ierr);check_err(ierr)
    else if (is_float) then
        call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,filespace_id,dset_id,ierr);check_err(ierr)
    else if (is_double) then
        call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,filespace_id,dset_id,ierr);check_err(ierr)
    endif
    call h5sclose_f(filespace_id,ierr);check_err(ierr)
    call h5screate_simple_f(rank,count,memspace_id,ierr);check_err(ierr)
    call h5dget_space_f(dset_id,filespace_id,ierr);check_err(ierr)
    call h5sselect_hyperslab_f(filespace_id,H5S_SELECT_SET_F,offset,count,ierr);check_err(ierr)
    if (is_integer) then
        call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, intval, dims, ierr, &
            file_space_id = filespace_id, mem_space_id = memspace_id);check_err(ierr)
    else if (is_float) then
        call h5dwrite_f(dset_id, H5T_NATIVE_REAL, floatval, dims, ierr, &
            file_space_id = filespace_id, mem_space_id = memspace_id);check_err(ierr)
    else if (is_double) then
        call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, doubleval, dims, ierr, &
            file_space_id = filespace_id, mem_space_id = memspace_id);check_err(ierr)
    endif
    call h5acreate_f(dset_id,"description",desctype_id,aspace_id,desc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
    call h5awrite_f(desc_id,desctype_id,trim(description),strdims,ierr);check_err(ierr)
    call h5acreate_f(dset_id,"units",unitstype_id,aspace_id,units_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
    call h5awrite_f(units_id,unitstype_id,trim(units),strdims,ierr);check_err(ierr)
    call H5aclose_f (desc_id,ierr);check_err(ierr)
    call H5aclose_f (units_id,ierr);check_err(ierr)
    call H5sclose_f (aspace_id,ierr);check_err(ierr)
    call H5tclose_f (desctype_id,ierr);check_err(ierr)
    call H5tclose_f (unitstype_id,ierr);check_err(ierr)
    call h5dclose_f (dset_id,ierr);check_err(ierr)
    call h5sclose_f (filespace_id,ierr);check_err(ierr)
    call h5sclose_f (memspace_id,ierr);check_err(ierr)
    if(dbg)    print *,myid,"ORF: Wrote ",trim(varname)
    return
    end subroutine h5_write_val_iamio


!-----------------------------------------------------------------------------------MARK

    subroutine h5_write_1d_float_iamio (f_id,local1darray,nlocal,dims,count,offset)
    implicit none

    integer(HSIZE_T), DIMENSION(1) :: strdims
    integer :: arank = 1
    integer(HSIZE_T), DIMENSION(1) :: adims = (/1/)
    integer(SIZE_T) :: stringlen

    integer :: nlocal
    real, dimension(nlocal) ::  local1darray

    integer rank
    integer(HSIZE_T), DIMENSION(1) :: dims,count
    integer(HSSIZE_T), DIMENSION(1) :: offset
    integer(HID_T) :: f_id,dset_id,filespace_id,memspace_id,aspace_id,desc_id,desctype_id,unitstype_id,units_id
    integer(HID_T) :: plist_id
    
    call h5screate_simple_f(arank,adims,aspace_id,ierr);check_err(ierr)
    call h5tcopy_f(H5T_NATIVE_CHARACTER,desctype_id,ierr);check_err(ierr)
    call h5tcopy_f(H5T_NATIVE_CHARACTER,unitstype_id,ierr);check_err(ierr)
    stringlen = len_trim(description)
    call h5tset_size_f(desctype_id,stringlen,ierr);check_err(ierr)
    stringlen = len_trim(units)
    call h5tset_size_f(unitstype_id,stringlen,ierr);check_err(ierr)

! filespace first
    rank=1
    strdims(1)=1

    call h5screate_simple_f(rank,dims,filespace_id,ierr);check_err(ierr)
    call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,filespace_id,dset_id,ierr);check_err(ierr)
    call h5sclose_f(filespace_id,ierr);check_err(ierr)

! memoryspace:
    call h5screate_simple_f(rank,count,memspace_id,ierr);check_err(ierr)
    call h5dget_space_f(dset_id,filespace_id,ierr);check_err(ierr)

    call h5sselect_hyperslab_f(filespace_id,H5S_SELECT_SET_F,offset,count,ierr);check_err(ierr)
    CALL h5dwrite_f(dset_id, H5T_NATIVE_REAL, local1darray, dims, ierr, &
             file_space_id = filespace_id, mem_space_id = memspace_id); check_err(ierr)

    call h5acreate_f(dset_id,"description",desctype_id,aspace_id,desc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
    call h5awrite_f(desc_id,desctype_id,trim(description),strdims,ierr);check_err(ierr)
    call h5acreate_f(dset_id,"units",unitstype_id,aspace_id,units_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
    call h5awrite_f(units_id,unitstype_id,trim(units),strdims,ierr);check_err(ierr)

    call H5aclose_f (desc_id,ierr);check_err(ierr)
    call H5aclose_f (units_id,ierr);check_err(ierr)
    call H5sclose_f (aspace_id,ierr);check_err(ierr)
    call H5tclose_f (desctype_id,ierr);check_err(ierr)
    call H5tclose_f (unitstype_id,ierr);check_err(ierr)
    call h5dclose_f (dset_id,ierr);check_err(ierr)
    call h5sclose_f (filespace_id,ierr);check_err(ierr)
    call h5sclose_f (memspace_id,ierr);check_err(ierr)
    if(dbg)    print *,myid,"ORF: Wrote ",trim(varname)
    return
    end subroutine h5_write_1d_float_iamio

!-----------------------------------------------------------------------------------MARK
 
     subroutine h5_write_3d_float_scalar(f_id,core3d,mcmtype,accuracy)
     use ISO_C_BINDING
     use HDF5
     implicit none

     integer(HSIZE_T), DIMENSION(3) :: dims,chunkdims,stride,block
     integer(HSIZE_T), DIMENSION(1) :: strdims
     integer :: arank = 1
     integer(HSIZE_T), DIMENSION(1) :: adims = (/1/)
     integer(SIZE_T) :: stringlen
     integer(HID_T) :: f_id,dset_id,dspace_id,chunk_id,datatype_id,desctype_id,unitstype_id,desc_id,units_id,aspace_id,zfpacc_id
     integer(HID_T) :: localmax_id,localmin_id,globalmax_id,globalmin_id,maxmintype_id,zfpacctype_id
     integer(HID_T) :: memspace_id,filespace_id,plist_id
     integer :: mcmtype
     integer :: rank,i,j,k
     real, intent(in), dimension(ni,nj,nk) :: core3d
     double precision, intent(in) :: accuracy
     real localmax,localmin,globalmax,globalmin
     integer source, dest, tag
     integer, dimension(MPI_STATUS_SIZE) :: mpi_status
     logical :: lossless,lossy

     lossless=.false.
     lossy=.true.
     if(accuracy .lt. 0.0)  then
         lossless = .true.
         lossy = .false.
     endif

     rank = 3

! ORF at some point we might want to set these right although I'm not sure what it
! gets us

     localmax = -9876.5
     localmin =  4321.0

     call h5_gather_3d(core3d,mcmtype)

iamioandwrite3d: &
     if (iamio.and.iwrite3d) then

!ORF DONE: If we are not saving the full vertical extent, we should
!only calculate prognostics up to the level we are saving - to save
!cycles. So we really need to set nkwrite_val in all the 3d loops
!where we do these calculations, not just here.

!TODO: We might someday want to allow saving any arbitrary Z slab, not
!assuming we save what is happening at ground level to save space (AACP
!for instance!)

         dims(1)=myMCMni
         dims(2)=myMCMnj
         if(save_full_vertical_extent) then
               dims(3)=nk
         else
               dims(3)=nkwrite_val
         endif
         chunkdims(1)=ni
         chunkdims(2)=nj

! ORF 2016-06-14
! Previously chunkdims(3) was always set to nk. But that is way too big
! for having nk in the thousands. So we just set it to a minimum of 100
! which seems good. Should improve read performance for Z chunks that do
! not start at z=0.

         if(dims(3).gt.100) then
               chunkdims(3)=100
         else
               chunkdims(3)=dims(3)
         endif

         strdims(1)=1

         call h5screate_simple_f(arank,adims,aspace_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_CHARACTER,desctype_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_CHARACTER,unitstype_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_REAL,maxmintype_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_DOUBLE,zfpacctype_id,ierr);check_err(ierr)
         stringlen = len_trim(description)
         call h5tset_size_f(desctype_id,stringlen,ierr);check_err(ierr)
         stringlen = len_trim(units)
         call h5tset_size_f(unitstype_id,stringlen,ierr);check_err(ierr)
         call h5screate_simple_f(rank,dims,dspace_id,ierr);check_err(ierr)
         call h5pcreate_f(H5P_DATASET_CREATE_F,chunk_id,ierr);check_err(ierr)
         call h5pset_chunk_f(chunk_id,rank,chunkdims,ierr);check_err(ierr)
!        if (lossless) then ! gzip level 9
!            call h5pset_deflate_f(chunk_id,9,ierr);check_err(ierr) ! <---- gzip level 9
         if (lossless) then ! ZFP reversible 
             ierr = h5pset_zfp_reversible(chunk_id);check_err(ierr)
         else ! zfp with fixed accuracy
             ierr = h5pset_zfp_accuracy(chunk_id,accuracy);check_err(ierr)
         endif
1010 format(a20," accuracy = ",f10.6)
!        if(myid.eq.0)write(*,1010)trim(varname),accuracy
         print*, myid, trim(varname)
         call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr,dcpl_id=chunk_id);check_err(ierr)
         call h5acreate_f(dset_id,"description",desctype_id,aspace_id,desc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(desc_id,desctype_id,description,strdims,ierr);check_err(ierr)
         call h5acreate_f(dset_id,"units",unitstype_id,aspace_id,units_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(units_id,unitstype_id,units,strdims,ierr);check_err(ierr)
         call h5acreate_f(dset_id,"localmax",maxmintype_id,aspace_id,localmax_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(localmax_id,maxmintype_id,localmax,strdims,ierr);check_err(ierr)
         call h5acreate_f(dset_id,"localmin",maxmintype_id,aspace_id,localmin_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(localmin_id,maxmintype_id,localmin,strdims,ierr);check_err(ierr)
         call h5dwrite_f(dset_id, H5T_NATIVE_REAL, MCM3d,dims, ierr);check_err(ierr)
         call h5acreate_f(dset_id,"zfp_accuracy",zfpacctype_id,aspace_id,zfpacc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(zfpacc_id,zfpacctype_id,accuracy,strdims,ierr);check_err(ierr)
         threedbytes = threedbytes + int(dims(1)*dims(2)*dims(3)*4,kind=8) 
         !4 byte floats, 3D array space. Note, compression will reduce actual space taken by data in file

         call h5aclose_f (desc_id,ierr);check_err(ierr)
         call h5aclose_f (units_id,ierr);check_err(ierr)
         call h5sclose_f (aspace_id,ierr);check_err(ierr)
         call h5tclose_f (desctype_id,ierr);check_err(ierr)
         call h5aclose_f (zfpacc_id,ierr);check_err(ierr)
         call h5tclose_f (zfpacctype_id,ierr);check_err(ierr)
         call h5tclose_f (unitstype_id,ierr);check_err(ierr)
         call h5tclose_f (maxmintype_id,ierr);check_err(ierr)
         call h5aclose_f (localmax_id,ierr);check_err(ierr)
         call h5aclose_f (localmin_id,ierr);check_err(ierr)
         call h5dclose_f (dset_id,ierr);check_err(ierr)
         call h5sclose_f (dspace_id,ierr);check_err(ierr)
         call h5pclose_f (chunk_id,ierr);check_err(ierr)
         if(dbg)     print *,myid,"ORF: Wrote ",trim(varname)
     endif iamioandwrite3d
     return
     end subroutine h5_write_3d_float_scalar

!-----------------------------------------------------------------------------------MARK
     subroutine h5_write_2d_float_scalar(f_id,core2d,mcmtype)
     use ISO_C_BINDING
     use HDF5
     implicit none

     integer(HSIZE_T), DIMENSION(3) :: dims,chunkdims,stride,block
     integer(HSIZE_T), DIMENSION(1) :: strdims
     integer :: arank = 1
     integer(HSIZE_T), DIMENSION(1) :: adims = (/1/)
     integer(SIZE_T) :: stringlen
     integer(HID_T) :: f_id,dset_id,dspace_id,chunk_id,datatype_id,desctype_id,unitstype_id,desc_id,units_id,aspace_id
     integer(HID_T) :: localmax_id,localmin_id,globalmax_id,globalmin_id,maxmintype_id
     integer(HID_T) :: memspace_id,filespace_id,plist_id

!mcmtype is ninjtype (for 2d) of course, probably does not need to be
!passed as arg.... could combine this routine with 3d to save code...
!except maybe not with compression only being used for 3D.

     integer :: mcmtype

     integer :: rank,i,j
     real, intent(in), dimension(ni,nj) :: core2d
!    double precision, intent(in) :: accuracy
     real localmax,localmin,globalmax,globalmin
     integer source, dest, tag
     integer, dimension(MPI_STATUS_SIZE) :: mpi_status

     rank = 2

! ORF at some point we might want to set these right although I'm not sure what it
! gets us

     localmax = -9876.5
     localmin =  4321.0

     call h5_gather_2d(core2d,mcmtype)
!MCM2dbuf now holds our correctly organized data

iamioandwrite3d: &
     if (iamio.and.iwrite3d) then

         dims(1)=myMCMni
         dims(2)=myMCMnj
         chunkdims(1)=ni
         chunkdims(2)=nj

         strdims(1)=1

         call h5screate_simple_f(arank,adims,aspace_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_CHARACTER,desctype_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_CHARACTER,unitstype_id,ierr);check_err(ierr)
         call h5tcopy_f(H5T_NATIVE_REAL,maxmintype_id,ierr);check_err(ierr)
         stringlen = len_trim(description)
         call h5tset_size_f(desctype_id,stringlen,ierr);check_err(ierr)
         stringlen = len_trim(units)
         call h5tset_size_f(unitstype_id,stringlen,ierr);check_err(ierr)
         call h5screate_simple_f(rank,dims,dspace_id,ierr);check_err(ierr)

!no compression for 2d

         call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr);check_err(ierr)

         call h5acreate_f(dset_id,"description",desctype_id,aspace_id,desc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(desc_id,desctype_id,description,strdims,ierr);check_err(ierr)
         call h5acreate_f(dset_id,"units",unitstype_id,aspace_id,units_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(units_id,unitstype_id,units,strdims,ierr);check_err(ierr)
         call h5acreate_f(dset_id,"localmax",maxmintype_id,aspace_id,localmax_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(localmax_id,maxmintype_id,localmax,strdims,ierr);check_err(ierr)
         call h5acreate_f(dset_id,"localmin",maxmintype_id,aspace_id,localmin_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F);check_err(ierr)
         call h5awrite_f(localmin_id,maxmintype_id,localmin,strdims,ierr);check_err(ierr)
         call h5dwrite_f(dset_id, H5T_NATIVE_REAL, MCM2d,dims, ierr);check_err(ierr)

         call h5aclose_f (desc_id,ierr);check_err(ierr)
         call h5aclose_f (units_id,ierr);check_err(ierr)
         call h5sclose_f (aspace_id,ierr);check_err(ierr)
         call h5tclose_f (desctype_id,ierr);check_err(ierr)
         call h5tclose_f (unitstype_id,ierr);check_err(ierr)

         call h5tclose_f (maxmintype_id,ierr);check_err(ierr)
         call h5aclose_f (localmax_id,ierr);check_err(ierr)
         call h5aclose_f (localmin_id,ierr);check_err(ierr)

         call h5dclose_f (dset_id,ierr);check_err(ierr)
         call h5sclose_f (dspace_id,ierr);check_err(ierr)
         if(dbg)     print *,myid,"ORF: Wrote ",trim(varname)
     endif iamioandwrite3d
     return
     end subroutine h5_write_2d_float_scalar
