  MODULE writeout_pcl_nc_module

  implicit none

  private
#ifdef PARCELS
  public :: writepdata_nc,disp_err
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

    string(:) = 'cm1out_pdata.nc'

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

  END MODULE writeout_pcl_nc_module
