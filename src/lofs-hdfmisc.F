#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

subroutine writetimeindex_unlimited(d_id,index,dtime)
     implicit none
     integer,  intent(in)    :: index
     double precision,  intent(in)    :: dtime

     integer(HID_T) :: d_id
     integer(HSIZE_T), dimension(1) :: maxdims,chunkdims,currentdims,singledims,offset
     integer :: rank,nvals

     maxdims(1) = H5S_UNLIMITED_F
     chunkdims(1) = 100
     singledims(1)=1
     offset(1)=index
     currentdims(1)=index+1

     rank=1
     nvals=1

     varname(:) = ' '
     units(:) = ' '
     description(:) = ' '
     varname='times'
     description='model times (double precision) in this file'
     units='s'

!ORF we may go to just time step and calcluate actual time later so we can save more frequently than 1 frame per sec
     call writeval_hdf_unlimited(rank,nvals,index,d_id,chunkdims,maxdims,currentdims,singledims,offset,doubleval=dtime)
     return
end subroutine writetimeindex_unlimited

!-----------------------------------------------------------------------------------MARK

subroutine writeval_hdf_unlimited(rank,nvals,index,f_id,chunkdims,maxdims,currentdims,singledims,offset,intval,floatval,doubleval)

    implicit none

    integer(HID_T) :: f_id,dset_id,dspace_id,chunk_id
    integer(HID_T) :: desctype_id,desc_id,aspace_id
    integer(HID_T) :: memoryspace,filespace
    integer rank,nvals !nvals no longer needed? We were passing array of length 1, now just int b/c HDF allows that
    integer(HSIZE_T),dimension(rank) :: chunkdims,maxdims,currentdims,singledims,offset
    integer(HSIZE_T), DIMENSION(1) :: adims = (/1/)
    integer(HSIZE_T), DIMENSION(1) :: strdims = (/1/)
    integer, intent(in),optional :: intval
    real, intent(in),optional :: floatval
    double precision, intent(in),optional :: doubleval
    integer index
    integer(SIZE_T) :: stringlen
    logical is_integer,is_float,is_double

    is_integer = present(intval)
    is_float = present(floatval)
    is_double = present(doubleval)

    if (index.eq.0) then
        call h5screate_simple_f(rank, singledims, dspace_id, ierr, maxdims); check_err(ierr)
        call h5screate_simple_f(rank, singledims, memoryspace, ierr, singledims); check_err(ierr)
        call h5pcreate_f(H5P_DATASET_CREATE_F,chunk_id,ierr); check_err(ierr)
        call h5pset_chunk_f(chunk_id,rank,chunkdims,ierr); check_err(ierr)
! This is an example of how you would add gzip compression to unlimited dimension arrays for parcel and stats hdf5 files
!           if (output_format.eq.3.or.output_format.eq.4)call h5pset_deflate_f (chunk_id,1,ierr)
        if(is_integer) then
            call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr,chunk_id); check_err(ierr)
        else if(is_float) then
            call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr,chunk_id); check_err(ierr)
        else if(is_double) then
            call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr,chunk_id); check_err(ierr)
        endif
        call h5dset_extent_f(dset_id,currentdims,ierr); check_err(ierr)
        call h5dget_space_f(dset_id,filespace,ierr); check_err(ierr)
        call h5sselect_hyperslab_f(filespace,H5S_SELECT_SET_F,offset,singledims,ierr); check_err(ierr)
        if(is_integer) then
            call h5dwrite_f(dset_id,H5T_NATIVE_INTEGER,intval,singledims,ierr,memoryspace,filespace,H5P_DEFAULT_F); check_err(ierr)
        else if(is_float) then
            call h5dwrite_f(dset_id,H5T_NATIVE_REAL,floatval,singledims,ierr,memoryspace,filespace,H5P_DEFAULT_F); check_err(ierr)
        else if(is_double) then
            call h5dwrite_f(dset_id,H5T_NATIVE_DOUBLE,doubleval,singledims,ierr,memoryspace,filespace,H5P_DEFAULT_F); check_err(ierr)
        endif
        call h5sclose_f(memoryspace,ierr); check_err(ierr)
        call h5sclose_f(filespace,ierr); check_err(ierr)
        call h5sclose_f(dspace_id,ierr); check_err(ierr)
        call H5pclose_f(chunk_id,ierr); check_err(ierr)

        call h5tcopy_f(H5T_NATIVE_CHARACTER,desctype_id,ierr); check_err(ierr)
        stringlen = len_trim(description)
        call h5tset_size_f(desctype_id,stringlen,ierr); check_err(ierr)
        call h5screate_simple_f(1,adims,aspace_id,ierr); check_err(ierr)
        call h5acreate_f(dset_id,"description",desctype_id,aspace_id,desc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F); check_err(ierr)
        call h5awrite_f(desc_id,desctype_id,description,strdims,ierr); check_err(ierr)
        call H5aclose_f (desc_id,ierr); check_err(ierr)
        call H5sclose_f (aspace_id,ierr); check_err(ierr)
        call H5tclose_f (desctype_id,ierr); check_err(ierr)

        call h5tcopy_f(H5T_NATIVE_CHARACTER,desctype_id,ierr); check_err(ierr)
        stringlen = len_trim(units)
        call h5tset_size_f(desctype_id,stringlen,ierr); check_err(ierr)
        call h5screate_simple_f(1,adims,aspace_id,ierr); check_err(ierr)
        call h5acreate_f(dset_id,"units",desctype_id,aspace_id,desc_id,ierr,H5P_DEFAULT_F,H5P_DEFAULT_F); check_err(ierr)
        call h5awrite_f(desc_id,desctype_id,units,strdims,ierr); check_err(ierr)
        call H5aclose_f (desc_id,ierr); check_err(ierr)
        call H5sclose_f (aspace_id,ierr); check_err(ierr)
        call H5tclose_f (desctype_id,ierr); check_err(ierr)

        call h5dclose_f(dset_id,ierr); check_err(ierr)
    else
        call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
        call h5dset_extent_f(dset_id,currentdims,ierr); check_err(ierr)
        call h5dget_space_f(dset_id,filespace,ierr); check_err(ierr)
        call h5sselect_hyperslab_f(filespace,H5S_SELECT_SET_F,offset,singledims,ierr); check_err(ierr)
        call h5screate_simple_f(rank, singledims, memoryspace, ierr, singledims); check_err(ierr)
        if(is_integer) then
            call h5dwrite_f(dset_id,H5T_NATIVE_INTEGER,intval,singledims,ierr,memoryspace,filespace,H5P_DEFAULT_F); check_err(ierr)
        else if(is_float) then
            call h5dwrite_f(dset_id,H5T_NATIVE_REAL,floatval,singledims,ierr,memoryspace,filespace,H5P_DEFAULT_F); check_err(ierr)
        else if(is_double) then
            call h5dwrite_f(dset_id,H5T_NATIVE_DOUBLE,doubleval,singledims,ierr,memoryspace,filespace,H5P_DEFAULT_F); check_err(ierr)
        endif
        call h5sclose_f(memoryspace,ierr); check_err(ierr)
        call h5sclose_f(filespace,ierr); check_err(ierr)
        call h5dclose_f(dset_id,ierr); check_err(ierr)
    endif
    return
end subroutine writeval_hdf_unlimited

!-----------------------------------------------------------------------------------MARK
