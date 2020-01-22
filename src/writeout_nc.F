  MODULE writeout_nc_module

  implicit none

  private
  public :: netcdf_prelim
#ifdef NETCDF
  public :: restart_prelim,writestat_nc,writepdata_nc,disp_err,  &
            write2d_nc,write3d_nc
#endif

  CONTAINS

!-------------------------------------------------------------
!
!  This subroutine writes data in NetCDF files.
!
!  Code originally written by Daniel Kirshbaum
!  Code converted to netcdf4 (f90) by George Bryan, May 2013
!  Code last modified by George Bryan, 130910
!
!-------------------------------------------------------------


      subroutine netcdf_prelim(rtime,nwrite,ncid,time_index,qname,                           &
                               name_output,desc_output,unit_output,grid_output,cmpr_output,  &
                               xh,xf,yh,yf,xfref,yfref,sigma,sigmaf,zs,zh,zf,                &
                               d2d,ds,du,dv,                                                 &
                               dumz,dumx,dumy)
      use input
      use constants
#ifdef NETCDF
      use netcdf
#endif
      implicit none

      real, intent(in) :: rtime
      integer, intent(in) :: nwrite
      integer, intent(inout) :: ncid,time_index
      character(len=3), dimension(maxq), intent(in) :: qname
      character(len=60), intent(in), dimension(maxvars) :: desc_output
      character(len=40), intent(in), dimension(maxvars) :: name_output,unit_output
      character(len=1),  intent(in), dimension(maxvars) :: grid_output
      logical, intent(in), dimension(maxvars) :: cmpr_output
      real, dimension(ib:ie),   intent(in) :: xh
      real, dimension(ib:ie+1), intent(in) :: xf
      real, dimension(jb:je),   intent(in) :: yh
      real, dimension(jb:je+1), intent(in) :: yf
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      real, dimension(kb:ke)  , intent(in) :: sigma
      real, dimension(kb:ke+1), intent(in) :: sigmaf
      real, dimension(ib:ie,jb:je), intent(in) :: zs
      real, dimension(ib:ie,jb:je,kb:ke),   intent(in) :: zh
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: zf
      real, dimension(ni,nj) :: d2d
      real, dimension(ni,nj,nk) :: ds
      real, dimension(ni+1,nj,nk) :: du
      real, dimension(ni,nj+1,nk) :: dv
      real, intent(inout), dimension(nz+1) :: dumz
      real, intent(inout), dimension(nx+1) :: dumx
      real, intent(inout), dimension(ny+1) :: dumy

#ifdef NETCDF
      integer i,j,k,n,irec

      ! Users of GrADS might want to set coards to .true.
      logical, parameter :: coards = .false.

      integer :: cdfid    ! ID for the netCDF file to be created
      integer :: status,dimid,varid
      integer :: niid,njid,nkid,nip1id,njp1id,nkp1id,timeid,oneid,tfile,num_write
      character(len=8) chid

!-------------------------------------------------------------
! Declare and set integer values for the netCDF dimensions 
!-------------------------------------------------------------

      integer :: ival,jval,kval,ivalp1,jvalp1,kvalp1
      real :: actual_time

      logical :: allinfo

      integer, parameter :: shuffle       = 1
      integer, parameter :: deflate       = 1
      integer, parameter :: deflate_level = 1

      integer :: chkx,chky,chkxp1,chkyp1

      logical, parameter :: stop_on_error = .true.

      if( myid.eq.0 ) print *,'  Entering netcdf_prelim '

!--------------------------------------------------------------
! Initializing some things
!--------------------------------------------------------------

    if(coards)then
      if(tapfrq.lt.60.0)then
        print *
        print *,'  Output frequency cannot be less than 60 s for coards format'
        print *
        call stopcm1
      endif
      actual_time = rtime/60.0
    else
      actual_time = rtime
    endif

!--------------------------------------------------------------
!  Write data to cdf file
!--------------------------------------------------------------

    IF(output_filetype.eq.1)THEN
      string(totlen+1:totlen+22) = '.nc                   '
    ELSEIF(output_filetype.eq.2)THEN
      string(totlen+1:totlen+22) = '_XXXXXX.nc            '
      write(string(totlen+2:totlen+7),100) nwrite
    ELSEIF(output_filetype.eq.3)THEN
      string(totlen+1:totlen+17) = '_XXXXXX_YYYYYY.nc     '
      write(string(totlen+ 2:totlen+ 7),100) myid
      write(string(totlen+ 9:totlen+14),100) nwrite
    ELSE
      if(dowr) write(outfile,*) '  for netcdf output, output_filetype must be either 1,2, or 3 '
      call stopcm1
    ENDIF

      if(myid.eq.0) print *,string

100   format(i6.6)

!--------------------------------------------------------------
!  Dimensions of data:

    IF( output_filetype.eq.1 .or. output_filetype.eq.2 )THEN
      ival = nx
      jval = ny
      chkx = nx
      chky = ny
      chkxp1 = nx+1
      chkyp1 = ny+1
    ELSEIF( output_filetype.eq.3 )THEN
      ival = ni
      jval = nj
      chkx = ni
      chky = nj
      chkxp1 = ni+1
      chkyp1 = nj+1
    ELSE
      print *,'  unrecognized value for output_filetype '
      call stopcm1
    ENDIF

    ivalp1 = ival+1
    jvalp1 = jval+1

    kval = min(maxk,nk)
    kvalp1 = min(maxk+1,nk+1)

!--------------------------------------------------------------
!  if this is the start of a file, then do this stuff:

    num_write = nwrite

    allinfo = .false.
    IF(num_write.eq.1) allinfo=.true.
    IF(output_filetype.ge.2)THEN
      allinfo=.true.
      num_write=1
    ENDIF

    IF( num_write.ne.1 )THEN
      ! cm1r18:  Try to open file.
      !          If error, set num_write to 1 and write all info.
      status = nf90_open( path=string , mode=nf90_write , ncid=ncid )
      if( status.eq.nf90_noerr )then
        ! no error, file exists.  Get number of time levels in file:
        call disp_err( nf90_inq_dimid(ncid,'time',timeid) , .true. )
        call disp_err( nf90_inquire_dimension(ncid=ncid,dimid=timeid,len=tfile), .true. )
        if( (tfile+1).lt.num_write )then
          if(myid.eq.0) print *,'  tfile,num_write = ',tfile,num_write
          num_write = tfile+1
        endif
      else
        ! if error opening file, then write all info:
        if(myid.eq.0) print *,'  status = ',status
!!!        if(myid.eq.0) print *,nf90_strerror(status)
        allinfo = .true.
        num_write = 1
      endif
    ENDIF

    time_index = num_write

    ifallinfo: IF(allinfo)THEN
!!!      print *,'  allinfo ... '

!-----------------------------------------------------------------------
!  BEGIN NEW:

      if( myid.eq.0 ) print *,'  calling nf90_create '
#ifdef NCFPLUS
!--- works with netcdf 4.2, but not 4.0 (grumble)
      call disp_err( nf90_create( path=string , cmode=IOR(nf90_netcdf4, nf90_classic_model) , ncid=ncid ) , .true. )
#else
      ! must do this for netcdf 4.0 (it seems) !
      call disp_err( nf90_create(path=string,cmode=0,ncid=ncid) , .true. )
#endif

      call disp_err( nf90_def_dim(ncid,'ni',ival,niid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nj',jval,njid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nk',kval,nkid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nip1',ivalp1,nip1id) , .true. )
      call disp_err( nf90_def_dim(ncid,'njp1',jvalp1,njp1id) , .true. )
      call disp_err( nf90_def_dim(ncid,'nkp1',kvalp1,nkp1id) , .true. )
      call disp_err( nf90_def_dim(ncid,'time',nf90_unlimited,timeid) , .true. )
      call disp_err( nf90_def_dim(ncid,'one',1,oneid) , .true. )

    IF(icor.eq.1)THEN
      call disp_err( nf90_def_var(ncid,"f_cor",nf90_float,oneid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","Coriolis parameter") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","1/s") , .true. )
    ENDIF

    if(.not.coards)then
      call disp_err( nf90_def_var(ncid,"ztop",nf90_float,oneid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )
    endif

    IF(coards)THEN

      call disp_err( nf90_def_var(ncid,"time",nf90_float,timeid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","time since beginning of simulation") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","minutes") , .true. )

      call disp_err( nf90_def_var(ncid,"ni",nf90_float,niid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","degree_east") , .true. )

      call disp_err( nf90_def_var(ncid,"nip1",nf90_float,nip1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location of staggered u grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","degree_east") , .true. )

      call disp_err( nf90_def_var(ncid,"nj",nf90_float,njid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","degree_north") , .true. )

      call disp_err( nf90_def_var(ncid,"njp1",nf90_float,njp1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location of staggered v grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","degree_north") , .true. )

      call disp_err( nf90_def_var(ncid,"nk",nf90_float,nkid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","nominal height of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

      call disp_err( nf90_def_var(ncid,"nkp1",nf90_float,nkp1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","nominal height of staggered w grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

    ELSE

      call disp_err( nf90_def_var(ncid,"time",nf90_float,timeid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","time since beginning of simulation") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","seconds") , .true. )

      call disp_err( nf90_def_var(ncid,"xh",nf90_float,niid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

      call disp_err( nf90_def_var(ncid,"xf",nf90_float,nip1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location of staggered u grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

      call disp_err( nf90_def_var(ncid,"yh",nf90_float,njid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

      call disp_err( nf90_def_var(ncid,"yf",nf90_float,njp1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location of staggered v grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

      call disp_err( nf90_def_var(ncid,"z",nf90_float,nkid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","nominal height of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

      call disp_err( nf90_def_var(ncid,"zf",nf90_float,nkp1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","nominal height of staggered w grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","km") , .true. )

    ENDIF

!--------------------------------------------------------
!  Just to be sure:

        call disp_err( nf90_inq_dimid(ncid,'time',timeid) , .true. )
        call disp_err( nf90_inq_dimid(ncid,'ni',niid) , .true. )
        call disp_err( nf90_inq_dimid(ncid,'nj',njid) , .true. )
        call disp_err( nf90_inq_dimid(ncid,'nk',nkid) , .true. )
        call disp_err( nf90_inq_dimid(ncid,'nip1',nip1id) , .true. )
        call disp_err( nf90_inq_dimid(ncid,'njp1',njp1id) , .true. )
        call disp_err( nf90_inq_dimid(ncid,'nkp1',nkp1id) , .true. )

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!--- 2D and 3D vars:
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

    ! new for cm1r19:  use "_output" arrays, which are
    !                  defined in writeout.F

      varloop:  &
      do n = 1,n_out
!!!        if( myid.eq.0 ) print *,'  n = ',n,trim(name_output(n))
        if(     grid_output(n).eq.'s' )then
          call disp_err( nf90_def_var(ncid,trim(name_output(n)),nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        elseif( grid_output(n).eq.'u' )then
          call disp_err( nf90_def_var(ncid,trim(name_output(n)),nf90_float,(/nip1id,njid,nkid,timeid/),varid) , .true. )
        elseif( grid_output(n).eq.'v' )then
          call disp_err( nf90_def_var(ncid,trim(name_output(n)),nf90_float,(/niid,njp1id,nkid,timeid/),varid) , .true. )
        elseif( grid_output(n).eq.'w' )then
          call disp_err( nf90_def_var(ncid,trim(name_output(n)),nf90_float,(/niid,njid,nkp1id,timeid/),varid) , .true. )
        elseif( grid_output(n).eq.'2' )then
          call disp_err( nf90_def_var(ncid,trim(name_output(n)),nf90_float,(/niid,njid,timeid/),varid) , .true. )
        else
          print *,'  Unknown setting for grid_output = ',grid_output(n)
          print *,'    67329 '
          call stopcm1
        endif
        call disp_err( nf90_put_att(ncid,varid,"long_name",trim(desc_output(n))) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units",trim(unit_output(n))) , .true. )
#ifdef NCFPLUS
        if(     grid_output(n).eq.'s' .or. grid_output(n).eq.'w' )then
          call disp_err( NF90_DEF_VAR_CHUNKING(ncid,varid,NF90_CHUNKED,(/chkx,chky,1,1/)) , .true. )
        elseif( grid_output(n).eq.'u' )then
          call disp_err( NF90_DEF_VAR_CHUNKING(ncid,varid,NF90_CHUNKED,(/chkxp1,chky,1,1/)) , .true. )
        elseif( grid_output(n).eq.'v' )then
          call disp_err( NF90_DEF_VAR_CHUNKING(ncid,varid,NF90_CHUNKED,(/chkx,chkyp1,1,1/)) , .true. )
        elseif( grid_output(n).eq.'2' )then
          call disp_err( NF90_DEF_VAR_CHUNKING(ncid,varid,NF90_CHUNKED,(/chkx,chky,1/)) , .true. )
        else
          print *,'  Unknown setting for grid_output = ',grid_output(n)
          print *,'    67330 '
          call stopcm1
        endif
        if( cmpr_output(n) )then
!!!          if( myid.eq.0 ) print *,'    ... compressing ... '
          call disp_err( nf90_def_var_deflate(ncid,varid,shuffle,deflate,deflate_level) , .true. )
        endif
#endif
      enddo  varloop

!--------------------------------------------------
      ! global attributes:

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'cm1 version','cm1r19.1') , .true. )
    if(coards)then
      call disp_err( nf90_put_att(ncid, NF90_GLOBAL, 'Conventions','COARDS') , .true. )
    endif
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'x_units','km') , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'x_label','x') , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'y_units','km') , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'y_label','y') , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'z_units','km') , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'z_label','z') , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nx",nx) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ny",ny) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nz",nz) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"imoist",imoist) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"sgsmodel",sgsmodel) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"tconfig",tconfig) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"bcturbs",bcturbs) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ptype",ptype) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"wbc",wbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ebc",ebc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"sbc",sbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nbc",nbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"bbc",bbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"tbc",tbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"iorigin",iorigin) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"axisymm",axisymm) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"iptra",iptra) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"npt",npt) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"fcor",fcor) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"radopt",radopt) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dtrad" ,dtrad) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ctrlat",ctrlat) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ctrlon",ctrlon) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"year"  ,year) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"month" ,month) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"day"   ,day) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"hour"  ,hour) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"minute",minute) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"second",second) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"sfcmodel",sfcmodel) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"oceanmodel",oceanmodel) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ipbl",ipbl) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"iice",iice) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"idm",idm) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"idmplus",idmplus) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"numq",numq) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nql1",nql1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nql2",nql2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nqs1",nqs1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nqs2",nqs2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nnc1",nnc1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nnc2",nnc2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nzl1",nzl1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nzl2",nzl2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nvl1",nvl1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nvl2",nvl2) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_m",c_m) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_e1",c_e1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_e2",c_e2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_s",c_s) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgs1",cgs1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgs2",cgs2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgs3",cgs3) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgs1",dgs1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgs2",dgs2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgs3",dgs3) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgt1",cgt1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgt2",cgt2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgt3",cgt3) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgt1",dgt1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgt2",dgt2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgt3",dgt3) , .true. )

      call disp_err( nf90_enddef(ncid) , .true. )

! ... end of defs
!--------------------------------------------------
! begin data ... initial time ...

    IF(icor.eq.1)THEN
      call disp_err( nf90_inq_varid(ncid,'f_cor',varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,fcor) , .true. )
    ENDIF

    if(.not.coards)then
      call disp_err( nf90_inq_varid(ncid,'ztop',varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,0.001*ztop) , .true. )
    endif

      if(coards)then
        call disp_err( nf90_inq_varid(ncid,'ni',varid) , .true. )
      else
        call disp_err( nf90_inq_varid(ncid,'xh',varid) , .true. )
      endif
      do i=1,nx
        dumx(i) = 0.001*0.5*(xfref(i)+xfref(i+1))
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumx,(/1/),(/nx/)) , .true. )

      if(coards)then
        call disp_err( nf90_inq_varid(ncid,'nip1',varid) , .true. )
      else
        call disp_err( nf90_inq_varid(ncid,'xf',varid) , .true. )
      endif
      do i=1,nx+1
        dumx(i) = 0.001*xfref(i)
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumx,(/1/),(/nx+1/)) , .true. )

      if(coards)then
        call disp_err( nf90_inq_varid(ncid,'nj',varid) , .true. )
      else
        call disp_err( nf90_inq_varid(ncid,'yh',varid) , .true. )
      endif
      do j=1,ny
        dumy(j) = 0.001*0.5*(yfref(j)+yfref(j+1))
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumy,(/1/),(/ny/)) , .true. )

      if(coards)then
        call disp_err( nf90_inq_varid(ncid,'njp1',varid) , .true. )
      else
        call disp_err( nf90_inq_varid(ncid,'yf',varid) , .true. )
      endif
      do j=1,ny+1
        dumy(j) = 0.001*yfref(j)
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumy,(/1/),(/ny+1/)) , .true. )

      if(coards)then
        call disp_err( nf90_inq_varid(ncid,'nk',varid) , .true. )
      else
        call disp_err( nf90_inq_varid(ncid,'z',varid) , .true. )
      endif
      if(terrain_flag)then
        do k=1,kval
          dumz(k) = 0.001*sigma(k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kval/)) , .true. )
      else
        do k=1,kval
          dumz(k) = 0.001*zh(1,1,k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kval/)) , .true. )
      endif

      if(coards)then
        call disp_err( nf90_inq_varid(ncid,'nkp1',varid) , .true. )
      else
        call disp_err( nf90_inq_varid(ncid,'zf',varid) , .true. )
      endif
      if(terrain_flag)then
        do k=1,kvalp1
          dumz(k) = 0.001*sigmaf(k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kvalp1/)) , .true. )
      else
        do k=1,kvalp1
          dumz(k) = 0.001*zf(1,1,k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kvalp1/)) , .true. )
      endif

      ! ... end if info at initial time only

!----------------------------------------------------------

    ENDIF ifallinfo

      call disp_err( nf90_inq_varid(ncid,'time',varid) , stop_on_error )
      call disp_err( nf90_put_var(ncid,varid,actual_time,(/time_index/)) , stop_on_error )

#endif

      if( myid.eq.0 ) print *,'  Leaving netcdf_prelim '

    end subroutine netcdf_prelim


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
#ifdef NETCDF


    ! cm1r18:  netcdf restart files
    subroutine restart_prelim(nrst,ncid,mtime,xfref,yfref,zh,zf,sigma,sigmaf,  &
                              qname,num_soil_layers,nrad2d,dumx,dumy,dumz,time_index)

    use input
    use constants
    use netcdf
    implicit none

    integer, intent(in) :: nrst
    integer, intent(inout) :: ncid
    double precision, intent(in) :: mtime
    real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
    real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
    real, intent(in), dimension(ib:ie,jb:je,kb:ke)   :: zh
    real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf
    real, intent(in), dimension(kb:ke)   :: sigma
    real, intent(in), dimension(kb:ke+1) :: sigmaf
    character(len=3), intent(in), dimension(maxq) :: qname
    integer, intent(in) :: num_soil_layers,nrad2d
    real, intent(inout), dimension(nx+1) :: dumx
    real, intent(inout), dimension(ny+1) :: dumy
    real, intent(inout), dimension(nz+1) :: dumz
    integer, intent(inout) :: time_index

    integer :: i,j,k,n
    integer :: ival,jval,kval,ivalp1,jvalp1,kvalp1
    integer :: chkx,chky,chkxp1,chkyp1
    integer :: status,varid
    real :: actual_time
    integer :: niid,njid,nkid,nip1id,njp1id,nkp1id,timeid
    integer :: nbudgetid,numqid,plocid,nparcelsid
    character(len=8) :: text1
    integer :: num_write,tfile
    logical :: allinfo

    chkx = nx
    chky = ny

    chkxp1 = nx+1
    chkyp1 = ny+1

    time_index = 1

    actual_time = mtime

  IF(     restart_filetype.eq.1 )THEN
    string(totlen+1:totlen+22) = '_rst.nc               '
  ELSEIF( restart_filetype.eq.2 )THEN
    string(totlen+1:totlen+22) = '_rst_XXXXXX.nc        '
    write(string(totlen+6:totlen+11),100) nrst
100 format(i6.6)
  ELSE
    print *,'  invalid value for restart_filetype '
    stop 33443
  ENDIF

    if(myid.eq.0) print *,'  string = ',string

!--------------------------------------------------------------
!  Dimensions of data:

    ival = nx
    jval = ny
    kval = nk

    ivalp1 = ival+1
    jvalp1 = jval+1
    kvalp1 = kval+1

!--------------------------------------------------------------
!  if this is the start of a file, then do this stuff:

    num_write = nrst

    allinfo = .false.
    IF( num_write.eq.1 ) allinfo = .true.
    IF( restart_filetype.ge.2 )THEN
      allinfo = .true.
      num_write = 1
    ENDIF

    IF( num_write.ne.1 )THEN
      ! cm1r18:  Try to open file.
      !          If error, set num_write to 1 and write all info.
      status = nf90_open( path=string , mode=nf90_write , ncid=ncid )
      if( status.eq.nf90_noerr )then
        ! no error, file exists.  Get number of time levels in file:
        call disp_err( nf90_inq_dimid(ncid,'time',timeid) , .true. )
        call disp_err( nf90_inquire_dimension(ncid=ncid,dimid=timeid,len=tfile), .true. )
        if( (tfile+1).lt.num_write )then
          if(myid.eq.0) print *,'  tfile,num_write = ',tfile,num_write
          num_write = tfile+1
        endif
      else
        ! if error opening file, then write all info:
        if(myid.eq.0) print *,'  status = ',status
!!!        if(myid.eq.0) print *,nf90_strerror(status)
        allinfo = .true.
        num_write = 1
      endif
    ENDIF

    time_index = num_write

!-----------------------------------------------------------------------
!  BEGIN

    ifallinfo:  IF( allinfo )THEN

#ifdef NCFPLUS
!--- works with netcdf 4.2, but not 4.0 (grumble)
      call disp_err( nf90_create( path=string , cmode=IOR(nf90_netcdf4, nf90_classic_model) , ncid=ncid ) , .true. )
#else
      ! must do this for netcdf 4.0 (it seems) !
      call disp_err( nf90_create(path=string,cmode=0,ncid=ncid) , .true. )
#endif

      !------------------
      ! define dims:

      call disp_err( nf90_def_dim(ncid,'ni',ival,niid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nj',jval,njid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nk',kval,nkid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nip1',ivalp1,nip1id) , .true. )
      call disp_err( nf90_def_dim(ncid,'njp1',jvalp1,njp1id) , .true. )
      call disp_err( nf90_def_dim(ncid,'nkp1',kvalp1,nkp1id) , .true. )
      call disp_err( nf90_def_dim(ncid,'time',nf90_unlimited,timeid) , .true. )
      call disp_err( nf90_def_dim(ncid,'nbudget',nbudget,nbudgetid) , .true. )
      call disp_err( nf90_def_dim(ncid,'numq',numq,numqid) , .true. )
    if( iprcl.eq.1 )then
      n = 3
      call disp_err( nf90_def_dim(ncid,'nploc',n,plocid) , .true. )
      n = max( 1 , nparcels )
      call disp_err( nf90_def_dim(ncid,'nparcels',n,nparcelsid) , .true. )
    endif

      !------------------
      ! define vars:

      call disp_err( nf90_def_var(ncid,"time",nf90_float,timeid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","time since beginning of simulation") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","seconds") , .true. )

      call disp_err( nf90_def_var(ncid,"xh",nf90_float,niid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

      call disp_err( nf90_def_var(ncid,"xf",nf90_float,nip1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location of staggered u grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

      call disp_err( nf90_def_var(ncid,"yh",nf90_float,njid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

      call disp_err( nf90_def_var(ncid,"yf",nf90_float,njp1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location of staggered v grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

      call disp_err( nf90_def_var(ncid,"zh",nf90_float,nkid,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","nominal height of scalar grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

      call disp_err( nf90_def_var(ncid,"zf",nf90_float,nkp1id,varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","nominal height of staggered w grid points") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

      !--------------------------------------------------------
      !  Just to be sure:

      call disp_err( nf90_inq_dimid(ncid,'time',timeid) , .true. )

      !------------------
      ! vars:

      call disp_err( nf90_def_var(ncid,"nstep"   ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"srec"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"sirec"   ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"urec"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"vrec"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"wrec"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"nrec"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"prec"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"trecs"   ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"trecw"   ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"arecs"   ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"arecw"   ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"nwrite"  ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"nwritet" ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"nwritea" ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"nwriteh" ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"nrst"    ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"ndt"     ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"icenter" ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"jcenter" ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"old_format",nf90_int,(/timeid/),varid) , .true. )

      call disp_err( nf90_def_var(ncid,"npt"     ,nf90_int,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"numparcels",nf90_int,(/timeid/),varid) , .true. )

      call disp_err( nf90_def_var(ncid,"dt"      ,nf90_float,(/timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","timestep") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","s") , .true. )

      call disp_err( nf90_def_var(ncid,"dtlast"  ,nf90_float,(/timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","previous timestep") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","s") , .true. )

      call disp_err( nf90_def_var(ncid,"xcenter" ,nf90_float,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"ycenter" ,nf90_float,(/timeid/),varid) , .true. )

      call disp_err( nf90_def_var(ncid,"cflmax"  ,nf90_float,(/timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max Courant number from previous timestep") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

      call disp_err( nf90_def_var(ncid,"mtime"   ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","model time (i.e., time since beginning of simulation)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","s") , .true. )

      call disp_err( nf90_def_var(ncid,"stattim" ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"taptim"  ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"rsttim"  ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"radtim"  ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"prcltim" ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"adt"     ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"acfl"    ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"dbldt"   ,nf90_double,(/timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"mass1"   ,nf90_double,(/timeid/),varid) , .true. )

      call disp_err( nf90_def_var(ncid,"qbudget" ,nf90_double,(/nbudgetid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"asq"     ,nf90_double,(/numqid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"bsq"     ,nf90_double,(/numqid,timeid/),varid) , .true. )

      !------------------
      ! 2d/3d vars:

      call disp_err( nf90_def_var(ncid,"rain"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","accumulated surface rainfall") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","cm") , .true. )

      call disp_err( nf90_def_var(ncid,"sws"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max windspeed at lowest level") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"svs"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max vert vorticity at lowest level") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","s^(-1)") , .true. )

      call disp_err( nf90_def_var(ncid,"sps"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","min pressure at lowest level") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","Pa") , .true. )

      call disp_err( nf90_def_var(ncid,"srs"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max surface rainwater") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )

      call disp_err( nf90_def_var(ncid,"sgs"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max surface graupel/hail") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )

      call disp_err( nf90_def_var(ncid,"sus"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max w at 5 km AGL") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"shs"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max integrated updraft helicity") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m2/s2") , .true. )

    if( nrain.eq.2 )then

      call disp_err( nf90_def_var(ncid,"rain2"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","accumulated surface rainfall (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","cm") , .true. )

      call disp_err( nf90_def_var(ncid,"sws2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max windspeed at lowest level (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"svs2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max vert vorticity at lowest level (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","s^(-1)") , .true. )

      call disp_err( nf90_def_var(ncid,"sps2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","min pressure at lowest level (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","Pa") , .true. )

      call disp_err( nf90_def_var(ncid,"srs2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max surface rainwater (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )

      call disp_err( nf90_def_var(ncid,"sgs2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max surface graupel/hail (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )

      call disp_err( nf90_def_var(ncid,"sus2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max w at 5 km AGL (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"shs2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","max integrated updraft helicity (translated)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m2/s2") , .true. )

    endif

      call disp_err( nf90_def_var(ncid,"tsk"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","soil/ocean temperature") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","K") , .true. )

      call disp_err( nf90_def_var(ncid,"rho"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","dry-air density") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/m^3") , .true. )

      call disp_err( nf90_def_var(ncid,"prs"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","pressure") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","Pa") , .true. )

      call disp_err( nf90_def_var(ncid,"ua"      ,nf90_float,(/nip1id,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","west-east velocity (at u points)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"va"      ,nf90_float,(/niid,njp1id,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","south-north velocity (at v points)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"wa"      ,nf90_float,(/niid,njid,nkp1id,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","vertical velocity (at w points)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

      call disp_err( nf90_def_var(ncid,"ppi"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","perturbation non-dimensional pressure") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

      call disp_err( nf90_def_var(ncid,"tha"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","perturbation potential temperature") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","K") , .true. )

      call disp_err( nf90_def_var(ncid,"ppx"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","change in nondimensional pressure used for forward-time-weighting on small steps") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

    if( psolver.eq.6 )then
      call disp_err( nf90_def_var(ncid,"phi1",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","phi1") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

      call disp_err( nf90_def_var(ncid,"phi2",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","phi2") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )
    endif

    if( imoist.eq.1 )then
      do n=1,numq
        text1 = '        '
        write(text1(1:3),156) qname(n)
156     format(a3)
        call disp_err( nf90_def_var(ncid,text1     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        if( n.eq.nqv )then
          call disp_err( nf90_put_att(ncid,varid,"long_name","water vapor mixing ratio") , .true. )
          call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )
        elseif(idm.eq.1.and.n.ge.nnc1.and.n.le.nnc2)then
          call disp_err( nf90_put_att(ncid,varid,"long_name","number concentration") , .true. )
          call disp_err( nf90_put_att(ncid,varid,"units","kg^{-1}") , .true. )
        elseif(idm .eq. 1 .and. n.ge.nzl1 .and. n .le. nzl2)then
          call disp_err( nf90_put_att(ncid,varid,"long_name","reflectivity moment") , .true. )
          call disp_err( nf90_put_att(ncid,varid,"units","Z m^{-3}kg^{-1}") , .true. )
        elseif(idm .eq. 1 .and. n.ge.nvl1 .and. n .le. nvl2)then
          call disp_err( nf90_put_att(ncid,varid,"long_name","particle volume") , .true. )
          call disp_err( nf90_put_att(ncid,varid,"units","m^{3}kg^{-1}") , .true. )
        else
          call disp_err( nf90_put_att(ncid,varid,"long_name","mixing ratio") , .true. )
          call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )
        endif
      enddo
    endif
    if(imoist.eq.1.and.eqtset.eq.2)then
      call disp_err( nf90_def_var(ncid,"qpten"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","ppi tendency from microphysics on previous timestep (related to h_diabatic in WRF)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","s^(-1)") , .true. )
      !---
      call disp_err( nf90_def_var(ncid,"qtten"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","theta tendency from microphysics on previous timestep (related to h_diabatic in WRF)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","K/s") , .true. )
      !---
      call disp_err( nf90_def_var(ncid,"qvten"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","qv tendency from microphysics on previous timestep (related to qv_diabatic in WRF)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg/s") , .true. )
      !---
      call disp_err( nf90_def_var(ncid,"qcten"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","qc tendency from microphysics on previous timestep (related to qc_diabatic in WRF)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg/s") , .true. )
    endif
    if(sgsmodel.eq.1)then
      call disp_err( nf90_def_var(ncid,"tkea"    ,nf90_float,(/niid,njid,nkp1id,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","subgrid turbulence kinetic energy") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m^2/s^2") , .true. )
    endif

    if( radopt.ge.1 )then
      call disp_err( nf90_def_var(ncid,"lwten"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"swten"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"radsw"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"rnflx"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"radswnet",nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"radlwin" ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      do n=1,nrad2d
        if( n.lt.10 )then
          text1 = 'radX    '
          write(text1(4:4),181) n
181       format(i1.1)
        elseif( n.lt.100 )then
          text1 = 'radXX   '
          write(text1(4:5),182) n
182       format(i2.2)
        elseif( n.lt.1000 )then
          text1 = 'radXXX  '
          write(text1(4:6),183) n
183       format(i3.3)
        else
          stop 11611
        endif
        call disp_err( nf90_def_var(ncid,text1     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      enddo
     endif

    if( radopt.ge.1 .and. ptype.eq.5 )then
      call disp_err( nf90_def_var(ncid,"effc"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"effi"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"effs"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"effr"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"effg"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_def_var(ncid,"effis"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
    endif

    if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
      if(sfcmodel.ge.1)then
        call disp_err( nf90_def_var(ncid,"ust"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","friction velocity") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"znt"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","roughness length") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

        call disp_err( nf90_def_var(ncid,"cd"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","surface drag coefficient") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

        call disp_err( nf90_def_var(ncid,"ch"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","surface exchange coefficient for sensible heat") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

        call disp_err( nf90_def_var(ncid,"cq"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","surface exchange coefficient for moisture") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )

        call disp_err( nf90_def_var(ncid,"u1"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","u component of velocity at lowest model level") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"v1"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","v component of velocity at lowest model level") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"s1"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","horizontal windspeed at lowest model level") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"u10"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","u component of windspeed at z=10 m") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"v10"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","v component of windspeed at z=10 m") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"s10"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","horizontal windspeed at z=10 m") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )

        call disp_err( nf90_def_var(ncid,"xland"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","land/water flag (1=land,2=water)") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","integer flag") , .true. )

        call disp_err( nf90_def_var(ncid,"thflux"  ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","surface potential temperature flux") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","K m s^{-1}") , .true. )

        call disp_err( nf90_def_var(ncid,"qvflux"  ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","surface water vapor flux") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","kg kg^{-1} m s^{-1}") , .true. )

        call disp_err( nf90_def_var(ncid,"psfc"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","surface pressure") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","Pa") , .true. )
      endif
      if(sfcmodel.ge.1)then
        call disp_err( nf90_def_var(ncid,"lu_index",nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"kpbl2d"  ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"hfx"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"qfx"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"hpbl"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"wspd"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"psim"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"psih"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"gz1oz0"  ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"br"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"chs"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"chs2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"cqs2"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"cpmm"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"zol"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"mavail"  ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"mol"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"rmol"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"regime"  ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"lh"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"tmn"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"flhc"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"flqc"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"qgh"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"ck"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"cka"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"cda"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"ustm"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"qsfc"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )

        call disp_err( nf90_def_var(ncid,"t2"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","temperature at z=2m") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","K") , .true. )

        call disp_err( nf90_def_var(ncid,"q2"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","water vapor mixing ratio at z=2m") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )

        call disp_err( nf90_def_var(ncid,"th2"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","potential temperature at z=2m") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","K") , .true. )

        call disp_err( nf90_def_var(ncid,"emiss"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"thc"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"albd"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"gsw"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"glw"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"chklowq" ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"capg"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"snowc"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"fm"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"fh"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        do n=1,num_soil_layers
          if( n.lt.10 )then
            text1 = 'tslbX   '
            write(text1(5:5),171) n
171         format(i1.1)
          elseif( n.lt.100 )then
            text1 = 'tslbXX  '
            write(text1(5:6),172) n
172         format(i2.2)
          else
            stop 22122
          endif
          call disp_err( nf90_def_var(ncid,text1     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        enddo
      endif
      if(oceanmodel.eq.2)then
        call disp_err( nf90_def_var(ncid,"tml"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"t0ml"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"hml"     ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"h0ml"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"huml"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"hvml"    ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
        call disp_err( nf90_def_var(ncid,"tmoml"   ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      endif
    endif

    if( iptra.eq.1 )then
      do n=1,npt
        if( n.le.9 )then
          text1 = 'ptX     '
          write(text1(3:3),161) n
161       format(i1.1)
        elseif( n.le.99 )then
          text1 = 'ptXX    '
          write(text1(3:4),162) n
162       format(i2.2)
        elseif( n.le.999 )then
          text1 = 'ptXXX   '
          write(text1(3:5),163) n
163       format(i3.3)
        else
          stop 11511
        endif
        call disp_err( nf90_def_var(ncid,text1,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      enddo
    endif

    if( iprcl.eq.1 )then
      call disp_err( nf90_def_var(ncid,"ploc"    ,nf90_float,(/nparcelsid,plocid,timeid/),varid) , .true. )
    endif

    if(irbc.eq.4)then
      if( wbc.eq.2 )then
        call disp_err( nf90_def_var(ncid,"radbcw"  ,nf90_float,(/njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","estimated gravity wave phase speed on west boundary") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( ebc.eq.2 )then
        call disp_err( nf90_def_var(ncid,"radbce"  ,nf90_float,(/njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","estimated gravity wave phase speed on east boundary") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( sbc.eq.2 )then
        call disp_err( nf90_def_var(ncid,"radbcs"  ,nf90_float,(/niid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","estimated gravity wave phase speed on south boundary") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( nbc.eq.2 )then
        call disp_err( nf90_def_var(ncid,"radbcn"  ,nf90_float,(/niid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","estimated gravity wave phase speed on north boundary") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
    endif

      !------------------
      ! 150820:  optionals

    !-----
    IF( restart_file_theta )THEN
      call disp_err( nf90_def_var(ncid,"theta"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","potential temperature") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","K") , .true. )
    ENDIF
    IF( restart_file_dbz )THEN
      call disp_err( nf90_def_var(ncid,"dbz"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","reflectivity") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","dBZ") , .true. )
    ENDIF
    !-----
    IF( restart_file_th0 )THEN
      call disp_err( nf90_def_var(ncid,"th0"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state potential temperature") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","K") , .true. )
    ENDIF
    IF( restart_file_prs0 )THEN
      call disp_err( nf90_def_var(ncid,"prs0"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state pressure") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","Pa") , .true. )
    ENDIF
    IF( restart_file_pi0 )THEN
      call disp_err( nf90_def_var(ncid,"pi0"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state nondimensional pressure") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","nondimensional") , .true. )
    ENDIF
    IF( restart_file_rho0 )THEN
      call disp_err( nf90_def_var(ncid,"rho0"    ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state dry-air density") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/m^3") , .true. )
    ENDIF
    IF( restart_file_qv0 )THEN
      call disp_err( nf90_def_var(ncid,"qv0"     ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state water vapor mixing ratio") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","kg/kg") , .true. )
    ENDIF
    IF( restart_file_u0 )THEN
      call disp_err( nf90_def_var(ncid,"u0"      ,nf90_float,(/nip1id,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state x-component velocity") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
    ENDIF
    IF( restart_file_v0 )THEN
      call disp_err( nf90_def_var(ncid,"v0"      ,nf90_float,(/niid,njp1id,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","base-state y-component velocity") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
    ENDIF
    !-----
    IF( restart_file_zs )THEN
      call disp_err( nf90_def_var(ncid,"zs"      ,nf90_float,(/niid,njid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","terrain height") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )
    ENDIF
    IF( restart_file_zh )THEN
      call disp_err( nf90_def_var(ncid,"zhalf"   ,nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","height of half (scalar) grid points (3d array)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )
    ENDIF
    IF( restart_file_zf )THEN
      call disp_err( nf90_def_var(ncid,"zfull"   ,nf90_float,(/niid,njid,nkp1id,timeid/),varid) , .true. )
      call disp_err( nf90_put_att(ncid,varid,"long_name","height of full (w) grid points (3d array)") , .true. )
      call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )
    ENDIF
    !-----
    IF( restart_file_diags )THEN
      if( td_diss.gt.0 )then
        call disp_err( nf90_def_var(ncid,"dissheat",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","dissipative heating (potential temperature tendency)") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","K/s") , .true. )
      endif
      if( td_mp.gt.0 )then
        call disp_err( nf90_def_var(ncid,"mptend",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","potential temperature tendency from microphysics") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","K/s") , .true. )
      endif
      if( qd_vtc.gt.0 )then
        call disp_err( nf90_def_var(ncid,"vtc",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","terminal fall velocity of qc") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( qd_vtr.gt.0 )then
        call disp_err( nf90_def_var(ncid,"vtr",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","terminal fall velocity of qr") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( qd_vts.gt.0 )then
        call disp_err( nf90_def_var(ncid,"vts",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","terminal fall velocity of qs") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( qd_vtg.gt.0 )then
        call disp_err( nf90_def_var(ncid,"vtg",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","terminal fall velocity of qg") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
      if( qd_vti.gt.0 )then
        call disp_err( nf90_def_var(ncid,"vti",nf90_float,(/niid,njid,nkid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name","terminal fall velocity of qi") , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units","m/s") , .true. )
      endif
    ENDIF
    !-----

      !------------------
      ! global attributes:

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nx",nx) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ny",ny) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nz",nz) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"imoist",imoist) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"sgsmodel",sgsmodel) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"tconfig",tconfig) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"bcturbs",bcturbs) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ptype",ptype) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"wbc",wbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ebc",ebc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"sbc",sbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nbc",nbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"bbc",bbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"tbc",tbc) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"iorigin",iorigin) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"axisymm",axisymm) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"iptra",iptra) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"npt",npt) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"fcor",fcor) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"radopt",radopt) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dtrad" ,dtrad) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ctrlat",ctrlat) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ctrlon",ctrlon) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"year"  ,year) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"month" ,month) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"day"   ,day) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"hour"  ,hour) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"minute",minute) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"second",second) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"sfcmodel",sfcmodel) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"oceanmodel",oceanmodel) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"ipbl",ipbl) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"iice",iice) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"idm",idm) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"idmplus",idmplus) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"numq",numq) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nql1",nql1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nql2",nql2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nqs1",nqs1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nqs2",nqs2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nnc1",nnc1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nnc2",nnc2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nzl1",nzl1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nzl2",nzl2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nvl1",nvl1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"nvl2",nvl2) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_m",c_m) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_e1",c_e1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_e2",c_e2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"c_s",c_s) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgs1",cgs1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgs2",cgs2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgs3",cgs3) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgs1",dgs1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgs2",dgs2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgs3",dgs3) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgt1",cgt1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgt2",cgt2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"cgt3",cgt3) , .true. )

      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgt1",dgt1) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgt2",dgt2) , .true. )
      call disp_err( nf90_put_att(ncid,NF90_GLOBAL,"dgt3",dgt3) , .true. )

      !------------------
      ! end definitions:

      call disp_err( nf90_enddef(ncid) , .true. )

      !---------------------------------------------
      !ccccccccccccccccccccccccccccccccccccccccccccc
      !---------------------------------------------


      call disp_err( nf90_inq_varid(ncid,'xh',varid) , .true. )
      do i=1,nx
        dumx(i) = 0.5*(xfref(i)+xfref(i+1))
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumx,(/1/),(/nx/)) , .true. )


      call disp_err( nf90_inq_varid(ncid,'xf',varid) , .true. )
      do i=1,nx+1
        dumx(i) = xfref(i)
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumx,(/1/),(/nx+1/)) , .true. )


      call disp_err( nf90_inq_varid(ncid,'yh',varid) , .true. )
      do j=1,ny
        dumy(j) = 0.5*(yfref(j)+yfref(j+1))
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumy,(/1/),(/ny/)) , .true. )


      call disp_err( nf90_inq_varid(ncid,'yf',varid) , .true. )
      do j=1,ny+1
        dumy(j) = yfref(j)
      enddo
      call disp_err( nf90_put_var(ncid,varid,dumy,(/1/),(/ny+1/)) , .true. )


      call disp_err( nf90_inq_varid(ncid,'zh',varid) , .true. )
      if(terrain_flag)then
        do k=1,kval
          dumz(k) = sigma(k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kval/)) , .true. )
      else
        do k=1,kval
          dumz(k) = zh(1,1,k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kval/)) , .true. )
      endif


      call disp_err( nf90_inq_varid(ncid,'zf',varid) , .true. )
      if(terrain_flag)then
        do k=1,kvalp1
          dumz(k) = sigmaf(k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kvalp1/)) , .true. )
      else
        do k=1,kvalp1
          dumz(k) = zf(1,1,k)
        enddo
        call disp_err( nf90_put_var(ncid,varid,dumz,(/1/),(/kvalp1/)) , .true. )
      endif


    ENDIF  ifallinfo

!  END
!-----------------------------------------------------------------------

      call disp_err( nf90_inq_varid(ncid,'time',varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,actual_time,(/time_index/)) , .true. )

      print *,'  leaving restart_prelim '

    end subroutine restart_prelim


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine write2d_nc(chid,ncid,time_index,ni,nj,d2d)
      use netcdf
      implicit none

      character(len=*), intent(in) :: chid
      integer, intent(in) :: ncid,time_index,ni,nj
      real, dimension(ni,nj), intent(in) :: d2d

      integer :: varid,status

!----------------------------------

      status = nf90_inq_varid(ncid,chid,varid)
      if(status.ne.nf90_noerr)then
        print *,'  Error1 in write2d_nc, chid = ',chid
        print *,nf90_strerror(status)
        call stopcm1
      endif

      status = nf90_put_var(ncid,varid,d2d,(/1,1,time_index/),(/ni,nj,1/))
      if(status.ne.nf90_noerr)then
        print *,'  Error2 in write2d_nc, chid = ',chid
        print *,nf90_strerror(status)
        call stopcm1
      endif

!----------------------------------

      end subroutine write2d_nc

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine write3d_nc(chid,k,ncid,time_index,ni,nj,ds)
      use netcdf
      implicit none

      character(len=*), intent(in) :: chid
      integer, intent(in) :: k,ncid,time_index,ni,nj
      real, dimension(ni,nj), intent(in) :: ds

      integer :: varid,status

!----------------------------------

      status = nf90_inq_varid(ncid,chid,varid)
      if(status.ne.nf90_noerr)then
        print *,'  Error1 in write3d_nc, chid = ',chid
        print *,'  status = ',status
        print *,nf90_strerror(status)
        call stopcm1
      endif

      status = nf90_put_var(ncid,varid,ds,(/1,1,k,time_index/),(/ni,nj,1,1/))
      if(status.ne.nf90_noerr)then
        print *,'  Error2 in write3d_nc, chid = ',chid
        print *,'  status = ',status
        print *,nf90_strerror(status)
        call stopcm1
      endif

!----------------------------------

      end subroutine write3d_nc

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine writestat_nc(nrec,rtime,nstat,rstat,qname,budname,name_stat,desc_stat,unit_stat)
      use input
      use netcdf
      implicit none

      integer, intent(inout) :: nrec
      real,    intent(in)    :: rtime
      integer, intent(in)    :: nstat
      real, dimension(stat_out), intent(in) :: rstat
      character(len=3), dimension(maxq), intent(in) :: qname
      character(len=6), dimension(maxq), intent(in) :: budname
      character(len=40), intent(in), dimension(maxvars) :: name_stat,desc_stat,unit_stat

      integer :: n,ncid,status,dimid,varid,time_index,timeid,tfile
      integer :: xhid,yhid,zhid
      logical :: allinfo

      if( myid.eq.0 ) print *,'  Entering writestat_nc '

    string(totlen+1:totlen+22) = '_stats.nc             '

    if(myid.eq.0) print *,string

    allinfo = .false.
    IF(nrec.eq.1) allinfo=.true.

    IF( nrec.ne.1 )THEN
      ! cm1r18:  Try to open file.
      !          If error, set nrec to 1 and write all info.
      status = nf90_open( path=string , mode=nf90_write , ncid=ncid )
      if( status.eq.nf90_noerr )then
        ! no error, file exists.  Get number of time levels in file:
        call disp_err( nf90_inq_dimid(ncid,'time',timeid) , .true. )
        call disp_err( nf90_inquire_dimension(ncid=ncid,dimid=timeid,len=tfile), .true. )
        if( (tfile+1).lt.nrec )then
          if(myid.eq.0) print *,'  tfile,nrec = ',tfile,nrec
          nrec = tfile+1
        endif
      else
        ! if error opening file, then write all info:
        if(myid.eq.0) print *,'  status = ',status
!!!        if(myid.eq.0) print *,nf90_strerror(status)
        allinfo = .true.
        nrec = 1
      endif
    ENDIF

    if( myid.eq.0 ) print *,'  nrec = ',nrec


  allinfo2:  IF( allinfo )THEN
    ! Definitions/descriptions:

      if( myid.eq.0 ) print *,'  calling nf90_create '
#ifdef NCFPLUS
!--- works with netcdf 4.2, but not 4.0 (grumble)
      call disp_err( nf90_create( path=string , cmode=IOR(nf90_netcdf4, nf90_classic_model) , ncid=ncid ) , .true. )
#else
      ! must do this for netcdf 4.0 (it seems) !
      call disp_err( nf90_create(path=string,cmode=0,ncid=ncid) , .true. )
#endif

    call disp_err( nf90_def_dim(ncid,"xh",1,xhid) , .true. )
    call disp_err( nf90_def_dim(ncid,"yh",1,yhid) , .true. )
    call disp_err( nf90_def_dim(ncid,"zh",1,zhid) , .true. )
    call disp_err( nf90_def_dim(ncid,"time",nf90_unlimited,timeid) , .true. )

    call disp_err( nf90_def_var(ncid,"xh",nf90_float,(/xhid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","degree_east") , .true. )

    call disp_err( nf90_def_var(ncid,"yh",nf90_float,(/yhid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","degree_north") , .true. )

    call disp_err( nf90_def_var(ncid,"zh",nf90_float,(/zhid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","height") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

    call disp_err( nf90_def_var(ncid,"time",nf90_float,(/timeid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","time") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","seconds") , .true. )

  !---------------------------------------------------------------------------!

    ! new for cm1r19:  use "_stat" arrays, which are
    !                  defined in statpack.F

      statloop:  &
      do n = 1,stat_out
        call disp_err( nf90_def_var(ncid,trim(name_stat(n)),nf90_float,timeid,varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name",trim(desc_stat(n))) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units",trim(unit_stat(n))) , .true. )
#ifdef NCFPLUS
        call disp_err( NF90_DEF_VAR_CHUNKING(ncid,varid,NF90_CHUNKED,(/1/)) , .true. )
#endif
      enddo  statloop

  !---------------------------------------------------------------------------!

    call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'cm1 version','cm1r19.1') , .true. )
    call disp_err( nf90_put_att(ncid, NF90_GLOBAL, 'Conventions','COARDS') , .true. )

    call disp_err( nf90_enddef(ncid=ncid) , .true. )

    call disp_err( nf90_inq_varid(ncid,'xh',varid) , .true. )
    call disp_err( nf90_put_var(ncid,varid,0.0) , .true. )

    call disp_err( nf90_inq_varid(ncid,'yh',varid) , .true. )
    call disp_err( nf90_put_var(ncid,varid,0.0) , .true. )

    call disp_err( nf90_inq_varid(ncid,'zh',varid) , .true. )
    call disp_err( nf90_put_var(ncid,varid,0.0) , .true. )

  ENDIF  allinfo2

  !---------------------------------------------------------------------
    ! Write data:

    time_index = nrec

    call disp_err( nf90_inq_varid(ncid,'time',timeid) , .true. )
    call disp_err( nf90_put_var(ncid,timeid,rtime,(/time_index/)) , .true. )

    DO n=1,nstat
      call disp_err( nf90_inq_varid(ncid,trim(name_stat(n)),varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,rstat(n),(/time_index/)) , .true. )
    ENDDO

    ! close file

    call disp_err( nf90_close(ncid) , .true. )

    ! all done

      if( myid.eq.0 ) print *,'  Leaving writestat_nc '

      end subroutine writestat_nc

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine disp_err( status , stop_on_error )
      use netcdf
      implicit none

      integer, intent(in) :: status
      logical, intent(in) :: stop_on_error

      IF( status.ne.nf90_noerr )THEN
        IF( stop_on_error )THEN
          print *,'  netcdf status returned an error: ', status,' ... stopping program'
          print *
          print *,nf90_strerror(status)
          print *
          call stopcm1
        ENDIF
      ENDIF

      end subroutine disp_err

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine writepdata_nc(prec,rtime,qname,name_prcl,desc_prcl,unit_prcl,pdata,pdata2)
      use input
      use netcdf
      implicit none

      integer, intent(inout) :: prec
      real, intent(in) :: rtime
      character(len=3), intent(in), dimension(maxq) :: qname
      character(len=40), intent(in), dimension(maxvars) :: name_prcl,desc_prcl,unit_prcl
      real, intent(in), dimension(nparcels,npvals) :: pdata
      real, intent(inout), dimension(nparcels) :: pdata2

      integer :: ncid,status,dimid,varid,time_index,n,n2,np,timeid,tfile,xid
      integer :: npid,yhid,zhid
      logical :: allinfo

!-----------------------------------------------------------------------

      if( myid.eq.0 ) print *,'  Entering writepdata_nc '

    string(totlen+1:totlen+22) = '_pdata.nc             '

    allinfo = .false.
    IF(prec.eq.1) allinfo=.true.

    IF( prec.ne.1 )THEN
      ! cm1r18:  Try to open file.
      !          If error, set prec to 1 and write all info.
      status = nf90_open( path=string , mode=nf90_write , ncid=ncid )
      if( status.eq.nf90_noerr )then
        ! no error, file exists.  Get number of time levels in file:
        call disp_err( nf90_inq_dimid(ncid,'time',timeid) , .true. )
        call disp_err( nf90_inquire_dimension(ncid=ncid,dimid=timeid,len=tfile), .true. )
        if( (tfile+1).lt.prec )then
!!!          if(myid.eq.0) print *,'  tfile,prec = ',tfile,prec
          prec = tfile+1
        endif
      else
        ! if error opening file, then write all info:
        if(myid.eq.0) print *,'  status = ',status
!!!        if(myid.eq.0) print *,nf90_strerror(status)
        allinfo = .true.
        prec = 1
      endif
    ENDIF

    if( myid.eq.0 ) print *,'  pdata prec = ',prec


  allinfo3:  IF( allinfo )THEN
    ! Definitions/descriptions:

#ifdef NCFPLUS
!--- works with netcdf 4.2, but not 4.0 (grumble)
      call disp_err( nf90_create( path=string , cmode=IOR(nf90_netcdf4, nf90_classic_model) , ncid=ncid ) , .true. )
#else
      ! must do this for netcdf 4.0 (it seems) !
      call disp_err( nf90_create(path=string,cmode=0,ncid=ncid) , .true. )
#endif

    call disp_err( nf90_def_dim(ncid,"xh",nparcels,npid) , .true. )
    call disp_err( nf90_def_dim(ncid,"yh",1,yhid) , .true. )
    call disp_err( nf90_def_dim(ncid,"zh",1,zhid) , .true. )
    call disp_err( nf90_def_dim(ncid,"time",nf90_unlimited,timeid) , .true. )

    call disp_err( nf90_def_var(ncid,"xh",nf90_float,(/npid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","west-east location ... actually, really parcel ID number") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","degree_east") , .true. )

    call disp_err( nf90_def_var(ncid,"yh",nf90_float,(/yhid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","south-north location") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","degree_north") , .true. )

    call disp_err( nf90_def_var(ncid,"zh",nf90_float,(/zhid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","height") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","m") , .true. )

    call disp_err( nf90_def_var(ncid,"time",nf90_float,(/timeid/),varid) , .true. )
    call disp_err( nf90_put_att(ncid,varid,"long_name","time") , .true. )
    call disp_err( nf90_put_att(ncid,varid,"units","seconds") , .true. )

  !---------------------------------------------------------------------------!

    ! new for cm1r19:  use "_prcl" arrays, which are
    !                  defined in parcel.F

      prclloop:  &
      do n = 1,prcl_out
        if(myid.eq.0) print *,n,trim(name_prcl(n))
        call disp_err( nf90_def_var(ncid,trim(name_prcl(n)),nf90_float,(/npid,timeid/),varid) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"long_name",trim(desc_prcl(n))) , .true. )
        call disp_err( nf90_put_att(ncid,varid,"units",trim(unit_prcl(n))) , .true. )
#ifdef NCFPLUS
        call disp_err( NF90_DEF_VAR_CHUNKING(ncid,varid,NF90_CHUNKED,(/nparcels,1/)) , .true. )
#endif
      enddo  prclloop

  !---------------------------------------------------------------------------!

    call disp_err( nf90_put_att(ncid,NF90_GLOBAL,'cm1 version','cm1r19.1') , .true. )
    call disp_err( nf90_put_att(ncid, NF90_GLOBAL, 'Conventions','COARDS') , .true. )

    call disp_err( nf90_enddef(ncid) , .true. )

  do np=1,nparcels
    call disp_err( nf90_put_var(ncid,npid,float(np),(/np/)) , .true. )
  enddo
    call disp_err( nf90_put_var(ncid,yhid,0.0) , .true. )
    call disp_err( nf90_put_var(ncid,zhid,0.0) , .true. )

!------------------------

  ENDIF  allinfo3

      ! Write data:

      time_index = prec

      call disp_err( nf90_inq_varid(ncid,'time',timeid) , .true. )
      call disp_err( nf90_put_var(ncid,timeid,rtime,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,'x',xid) , .true. )

      DO n=1,prcl_out
        call disp_err( nf90_inq_varid(ncid,trim(name_prcl(n)),varid) , .true. )
        do np=1,nparcels
          pdata2(np) = pdata(np,n)
        enddo
        call disp_err( nf90_put_var(ncid,varid,pdata2,(/1,time_index/),(/nparcels,1/)) , .true. )
      ENDDO

      ! close file

      call disp_err( nf90_close(ncid) , .true. )

      prec = prec + 1

      ! all done

      if( myid.eq.0 ) print *,'  Leaving writepdata_nc '

      end subroutine writepdata_nc
#endif

  END MODULE writeout_nc_module
