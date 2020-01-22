  MODULE restart_module

  implicit none

  private
  public :: write_restart,read_restart

  CONTAINS

      subroutine write_restart(nstep,srec,sirec,urec,vrec,wrec,nrec,prec,           &
                               trecs,trecw,arecs,arecw,                             &
                               nwrite,nwritet,nwritea,nwriteh,nrst,                 &
                               num_soil_layers,nrad2d,                              &
                               dt,dtlast,mtime,ndt,adt,acfl,dbldt,mass1,            &
                               stattim,taptim,rsttim,radtim,prcltim,                &
                               qbudget,asq,bsq,qname,                               &
                               xfref,yfref,zh,zf,sigma,sigmaf,zs,                   &
                               th0,prs0,pi0,rho0,qv0,u0,v0,                         &
                               rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                               tsk,znt,ust,cd,ch,cq,u1,v1,s1,thflux,qvflux,         &
                               radbcw,radbce,radbcs,radbcn,                         &
                               rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                               swten,lwten,radsw,rnflx,radswnet,radlwin,rad2d,      &
                               effc,effi,effs,effr,effg,effis,                      &
                               lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,      &
                               hpbl,wspd,psim,psih,gz1oz0,br,                       &
                               CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                       &
                               MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                    &
                               CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,       &
                               gsw,glw,chklowq,capg,snowc,fm,fh,tslb,               &
                               tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml,               &
                               qpten,qtten,qvten,qcten,pta,pdata,ploc,ppx,          &
                               tdiag,qdiag,phi1,phi2,                               &
                               icenter,jcenter,xcenter,ycenter,                     &
                               dum1,dat1,dat2,dat3,reqt)
      use input
      use constants
#ifdef MPI
      use mpi
#endif
#ifdef NETCDF
      use netcdf
      use writeout_nc_module, only : restart_prelim,disp_err
#endif
      implicit none

      !----------------------------------------------------------
      ! This subroutine organizes the writing of restart files
      !----------------------------------------------------------

      integer, intent(in) :: nstep,srec,sirec,urec,vrec,wrec,nrec,prec,trecs,trecw,arecs,arecw
      integer, intent(in) :: nwrite,nwritet,nwritea,nwriteh,nrst
      integer, intent(in) :: num_soil_layers,nrad2d
      real, intent(in) :: dt,dtlast
      integer, intent(in) :: ndt
      double precision, intent(in) :: adt,acfl,dbldt,mass1
      double precision, intent(in) :: mtime,stattim,taptim,rsttim,radtim,prcltim
      double precision, intent(inout), dimension(nbudget) :: qbudget
      double precision, intent(inout), dimension(numq) :: asq,bsq
      character(len=3), intent(in), dimension(maxq) :: qname
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      real, intent(in), dimension(kb:ke) :: sigma
      real, intent(in), dimension(kb:ke+1) :: sigmaf
      real, intent(in), dimension(ib:ie,jb:je) :: zs
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: th0,prs0,pi0,rho0,qv0
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: u0
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: v0
      real, intent(in), dimension(ib:ie,jb:je,nrain) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, intent(in), dimension(ib:ie,jb:je) :: tsk,znt,ust,cd,ch,cq,u1,v1,s1,xland,psfc,thflux,qvflux
      real, intent(in), dimension(jb:je,kb:ke) :: radbcw,radbce
      real, intent(in), dimension(ib:ie,kb:ke) :: radbcs,radbcn
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rho,prs
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: ppi,tha
      real, intent(in), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa
      real, intent(in), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea
      real, intent(in), dimension(ibr:ier,jbr:jer,kbr:ker) :: swten,lwten,effc,effi,effs,effr,effg,effis
      real, intent(in), dimension(ni,nj) :: radsw,rnflx,radswnet,radlwin
      real, intent(in), dimension(ni,nj,nrad2d) :: rad2d
      integer, intent(in), dimension(ibl:iel,jbl:jel) :: lu_index
      integer, intent(in), dimension(ibl:iel,jbl:jel) :: kpbl2d
      real, intent(in), dimension(ibl:iel,jbl:jel) :: u10,v10,s10,hfx,qfx,    &
                                      hpbl,wspd,psim,psih,gz1oz0,br,          &
                                      CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,          &
                                      MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,   &
                                      CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,   &
                                      gsw,glw,chklowq,capg,snowc,fm,fh
      real, intent(in), dimension(ibl:iel,jbl:jel,num_soil_layers) :: tslb
      real, intent(in), dimension(ibl:iel,jbl:jel) :: tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml
      real, intent(in), dimension(ibm:iem,jbm:jem,kbm:kem) :: qpten,qtten,qvten,qcten
      real, intent(in), dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta
      real, intent(in), dimension(nparcels,npvals) :: pdata
      real, intent(inout), dimension(nparcels,3) :: ploc
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: ppx
      real, intent(in),    dimension(ibph:ieph,jbph:jeph,kbph:keph) :: phi1,phi2
      real, intent(in   ) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
      real, intent(in   ) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
      integer, intent(in   ) :: icenter,jcenter
      real, intent(in   ) :: xcenter,ycenter
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1
      real, intent(inout), dimension(ni+1,nj+1) :: dat1
      real, intent(inout), dimension(d2i,d2j) :: dat2
      real, intent(inout), dimension(d3i,d3j,d3n) :: dat3
      integer, intent(inout), dimension(d3t) :: reqt

      character(len=80) :: fname
      character(len=8) :: text1
      character(len=6) :: aname
      integer :: i,j,k,n,np,nvar,reqs,orecs,orecu,orecv,orecw,ndum
      integer :: ncid,time_index
      real, dimension(:), allocatable :: dumx,dumy
#ifdef MPI
      integer :: proc,index,count,req1,req2,req3,reqp
      double precision, dimension(nbudget) :: cfoo
      double precision, dimension(numq) :: afoo,bfoo
#endif
#ifdef NETCDF
      integer :: varid,ncstatus
#endif

!-----------------------------------------------------------------------

  IF( restart_format.eq.1 )THEN
    ! unformatted direct-access (grads) format:

  IF( restart_filetype.eq.1 )THEN

    !------------------
    ! one restart file (per stagger type):
    IF(myid.eq.nodemaster)THEN
      fname = '                                                                                '
    if(strlen.gt.0)then
      fname(1:strlen) = output_path(1:strlen)
    endif
      fname(strlen+1:strlen+baselen) = output_basename(1:baselen)

      fname(totlen+1:totlen+1+10) = '_rst_x.dat'

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  Writing to restart file!'
      if(dowr) write(outfile,*) '  fname=',fname

      if( myid.eq.0 )  &
      open(unit=50,file=fname,form='unformatted',status='unknown')

      fname(totlen+1:totlen+1+10) = '_rst_s.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=51,file=fname,form='unformatted',access='direct',recl=4*nx*ny)
      orecs = 1

      fname(totlen+1:totlen+1+10) = '_rst_u.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=52,file=fname,form='unformatted',access='direct',recl=4*(nx+1)*ny)
      orecu = 1

      fname(totlen+1:totlen+1+10) = '_rst_v.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=53,file=fname,form='unformatted',access='direct',recl=4*nx*(ny+1))
      orecv = 1

      fname(totlen+1:totlen+1+10) = '_rst_w.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=54,file=fname,form='unformatted',access='direct',recl=4*nx*ny)
      orecw = 1

      if(dowr) write(outfile,*)
    ENDIF

  ELSEIF( restart_filetype.eq.2 )THEN

    !------------------
    ! one restart file (per restart time):
    IF(myid.eq.nodemaster)THEN
      fname = '                                                                                '
    if(strlen.gt.0)then
      fname(1:strlen) = output_path(1:strlen)
    endif
      fname(strlen+1:strlen+baselen) = output_basename(1:baselen)

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_x.dat'
      write(fname(totlen+ 6:totlen+11),101) nrst
101   format(i6.6)

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  Writing to restart file!'
      if(dowr) write(outfile,*) '  fname=',fname

      if( myid.eq.0 )  &
      open(unit=50,file=fname,form='unformatted',status='unknown')

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_s.dat'
      write(fname(totlen+ 6:totlen+11),101) nrst
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=51,file=fname,form='unformatted',access='direct',recl=4*nx*ny)
      orecs = 1

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_u.dat'
      write(fname(totlen+ 6:totlen+11),101) nrst
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=52,file=fname,form='unformatted',access='direct',recl=4*(nx+1)*ny)
      orecu = 1

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_v.dat'
      write(fname(totlen+ 6:totlen+11),101) nrst
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=53,file=fname,form='unformatted',access='direct',recl=4*nx*(ny+1))
      orecv = 1

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_w.dat'
      write(fname(totlen+ 6:totlen+11),101) nrst
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=54,file=fname,form='unformatted',access='direct',recl=4*nx*ny)
      orecw = 1

      if(dowr) write(outfile,*)
    ENDIF

  ELSEIF( restart_filetype.eq.3 )THEN

    !------------------
    ! one restart file per node (cm1r17 format):
    IF(myid.eq.nodemaster)THEN
      fname = '                                                                                '
    if(strlen.gt.0)then
      fname(1:strlen) = output_path(1:strlen)
    endif
      fname(strlen+1:strlen+baselen) = output_basename(1:baselen)
      fname(totlen+1:totlen+1+22) = '_rst_XXXXXX_YYYYYY.dat'

      write(fname(totlen+ 6:totlen+11),102) mynode
      write(fname(totlen+13:totlen+18),102) nrst
102   format(i6.6)

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  Writing to restart file!'
      if(dowr) write(outfile,*) '  fname=',fname
      if(dowr) write(outfile,*)

      open(unit=50,file=fname,form='unformatted',status='unknown')
    ENDIF
  ELSE
    stop 12388
  ENDIF

#ifdef NETCDF
  ELSEIF( restart_format.eq.2 )THEN
    ! netcdf format:

    if( myid.eq.0 )then
      call     restart_prelim(nrst,ncid,mtime,xfref,yfref,zh,zf,sigma,sigmaf,  &
                              qname,num_soil_layers,nrad2d,dat2(1,1),dat2(1,2),dum1(ib,jb,kb),time_index)
    endif

#endif
  ELSE

    if( myid.eq.0 )then
      print *
      print *,'  unrecognized value for restart_format '
      print *
      print *,'      restart_format = ',restart_format
      print *
    endif
#ifdef MPI
    call MPI_BARRIER (MPI_COMM_WORLD,ierr)
#endif
    call stopcm1

  ENDIF

!---------------------------------------------------------------
! metadata:

  IF( restart_format.eq.1 )THEN
    IF(myid.eq.0)THEN
      ! only processor 0 does this:
      write(50) nstep
      write(50) srec
      write(50) sirec
      write(50) urec
      write(50) vrec
      write(50) wrec
      write(50) nrec
      write(50) prec
      write(50) trecs
      write(50) trecw
      write(50) arecs
      write(50) arecw
      write(50) nwrite
      write(50) nwritet
      write(50) nwritea
      write(50) nrst
      write(50) ndt
      write(50) icenter
      write(50) jcenter
      write(50) output_format
      write(50) dt
      write(50) dtlast
      write(50) xcenter
      write(50) ycenter
      write(50) cflmax
      write(50) mtime
      write(50) stattim
      write(50) taptim
      write(50) rsttim
      write(50) radtim
      write(50) prcltim
      write(50) adt
      write(50) acfl
      write(50) dbldt
      write(50) mass1
    ENDIF
#ifdef NETCDF
  ELSEIF( restart_format.eq.2 )THEN
    IF(myid.eq.0)THEN

      call disp_err( nf90_inq_varid(ncid,"nstep",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nstep,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"srec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,srec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"sirec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,sirec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"urec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,urec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"vrec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,vrec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"wrec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,wrec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nrec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nrec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"prec",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,prec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"trecs",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,trecs,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"trecw",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,trecw,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"arecs",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,arecs,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"arecw",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,arecw,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwrite",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nwrite,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwritet",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nwritet,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwritea",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nwritea,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwriteh",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nwriteh,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nrst",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,nrst,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"ndt",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,ndt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"icenter",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,icenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"jcenter",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,jcenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"old_format",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,output_format,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"dt",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,dt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"dtlast",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,dtlast,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"xcenter",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,xcenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"ycenter",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,ycenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"cflmax",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,cflmax,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"mtime",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,mtime,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"stattim",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,stattim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"taptim",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,taptim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"rsttim",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,rsttim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"radtim",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,radtim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"prcltim",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,prcltim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"adt",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,adt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"acfl",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,acfl,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"dbldt",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,dbldt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"mass1",varid) , .true. )
      call disp_err( nf90_put_var(ncid,varid,mass1,(/time_index/)) , .true. )

    ENDIF
#endif
  ENDIF

!-----------------------------------------------------------------------
#ifdef MPI
      cfoo = 0.0
      call MPI_REDUCE(qbudget(1),cfoo(1),nbudget,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
                      MPI_COMM_WORLD,ierr)
      if( myid.eq.0 )then
        do n=1,nbudget
          qbudget(n)=cfoo(n)
        enddo
      else
        qbudget = 0.0
      endif
      if( imoist.eq.1 )then
        afoo = 0.0
        call MPI_REDUCE(asq(1),afoo(1),numq,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
                        MPI_COMM_WORLD,ierr)
        if( myid.eq.0 )then
          do n=1,numq
            asq(n)=afoo(n)
          enddo
        else
          asq = 0.0
        endif
        bfoo = 0.0
        call MPI_REDUCE(bsq(1),bfoo(1),numq,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
                        MPI_COMM_WORLD,ierr)
        if( myid.eq.0 )then
          do n=1,numq
            bsq(n)=bfoo(n)
          enddo
        else
          bsq = 0.0
        endif
      endif
#endif
!-----------------------------------------------------------------------
! budget variables:

    IF( myid.eq.0 )THEN

      IF( restart_format.eq.1 )THEN
        write(50) qbudget
        write(50) asq
        write(50) bsq
#ifdef NETCDF
      ELSEIF( restart_format.eq.2 )THEN
        call disp_err( nf90_inq_varid(ncid,"qbudget",varid) , .true. )
        call disp_err( nf90_put_var(ncid,varid,qbudget,(/1,time_index/),(/nbudget,1/)) , .true. )
        call disp_err( nf90_inq_varid(ncid,"asq",varid) , .true. )
        call disp_err( nf90_put_var(ncid,varid,asq,(/1,time_index/),(/numq,1/)) , .true. )
        call disp_err( nf90_inq_varid(ncid,"bsq",varid) , .true. )
        call disp_err( nf90_put_var(ncid,varid,bsq,(/1,time_index/),(/numq,1/)) , .true. )
#endif
      ENDIF

    ENDIF

!---------------------------------------------------------------
! standard 2D:

      n = 1
      call writer(ni,nj,1,1,nx,ny,rain(ib,jb,n),'rain    ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sws(ib,jb,n),'sws     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,svs(ib,jb,n),'svs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sps(ib,jb,n),'sps     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,srs(ib,jb,n),'srs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sgs(ib,jb,n),'sgs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sus(ib,jb,n),'sus     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,shs(ib,jb,n),'shs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    if( nrain.eq.2 )then
      n = 2
      call writer(ni,nj,1,1,nx,ny,rain(ib,jb,n),'rain2   ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sws(ib,jb,n),'sws2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,svs(ib,jb,n),'svs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sps(ib,jb,n),'sps2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,srs(ib,jb,n),'srs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sgs(ib,jb,n),'sgs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,sus(ib,jb,n),'sus2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,1,nx,ny,shs(ib,jb,n),'shs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif
      call writer(ni,nj,1,1,nx,ny,tsk(ib,jb),'tsk     ',           &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)

!---------------------------------------------------------------
! standard 3D:

      call writer(ni,nj,1,nk,nx,ny,rho(ib,jb,1),'rho     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,prs(ib,jb,1),'prs     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni+1,nj,1,nk,nx+1,ny,ua(ib,jb,1),'ua      ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecu,52,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2iu,d2ju,d3iu,d3ju)
      call writer(ni,nj+1,1,nk,nx,ny+1,va(ib,jb,1),'va      ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecv,53,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2iv,d2jv,d3iv,d3jv)
      call writer(ni,nj,1,nk+1,nx,ny,wa(ib,jb,1),'wa      ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecw,54,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,ppi(ib,jb,1),'ppi     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,tha(ib,jb,1),'tha     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,ppx(ib,jb,1),'ppx     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    if( psolver.eq.6 )then
      call writer(ni,nj,1,nk,nx,ny,phi1(ib,jb,1),'phi1    ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,phi2(ib,jb,1),'phi2    ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif
    IF(imoist.eq.1)THEN
    do n=1,numq
      text1 = '        '
      write(text1(1:3),156) qname(n)
156   format(a3)
      call writer(ni,nj,1,nk,nx,ny,qa(ib,jb,1,n),text1     ,       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    enddo
    ENDIF
    if(imoist.eq.1.and.eqtset.eq.2)then
      call writer(ni,nj,1,nk,nx,ny,qpten(ib,jb,1),'qpten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,qtten(ib,jb,1),'qtten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,qvten(ib,jb,1),'qvten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call writer(ni,nj,1,nk,nx,ny,qcten(ib,jb,1),'qcten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif
    if(sgsmodel.eq.1)then
      call writer(ni,nj,1,nk+1,nx,ny,tkea(ib,jb,1),'tkea    ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecw,54,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif

!---------------------------------------------------------------
!  radiation:

      if(radopt.ge.1)then
        call writer(ni,nj,1,nk,nx,ny,lwten(ib,jb,1),'lwten   ',      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,nk,nx,ny,swten(ib,jb,1),'swten   ',      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = radsw(i,j)
        enddo
        enddo
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'radsw   ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = rnflx(i,j)
        enddo
        enddo
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'rnflx   ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = radswnet(i,j)
        enddo
        enddo
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'radswnet',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = radlwin(i,j)
        enddo
        enddo
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'radlwin ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        do n=1,nrad2d
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = rad2d(i,j,n)
        enddo
        enddo
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
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),text1,             &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        enddo
      endif

      if( radopt.ge.1 .and. ptype.eq.5 )then
        call writer(ni,nj,1,nk,nx,ny,effc(ib,jb,1),'effc    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,nk,nx,ny,effi(ib,jb,1),'effi    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,nk,nx,ny,effs(ib,jb,1),'effs    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,nk,nx,ny,effr(ib,jb,1),'effr    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,nk,nx,ny,effg(ib,jb,1),'effg    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,nk,nx,ny,effis(ib,jb,1),'effis   ',      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      endif

!---------------------------------------------------------------
!  surface:
!     I don't know how many of these are really needed in restart
!     files, but let's include them all for now ... just to be safe

      if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
        !---- (1) ----!
      if(sfcmodel.ge.1)then
        call writer(ni,nj,1,1,nx,ny,ust(ib,jb),'ust     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,znt(ib,jb),'znt     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,cd(ib,jb),'cd      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,ch(ib,jb),'ch      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,cq(ib,jb),'cq      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,u1(ib,jb),'u1      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,v1(ib,jb),'v1      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,s1(ib,jb),'s1      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,u10(ib,jb),'u10     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,v10(ib,jb),'v10     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,s10(ib,jb),'s10     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,xland(ib,jb),'xland   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,thflux(ib,jb),'thflux  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,qvflux(ib,jb),'qvflux  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,psfc(ib,jb),'psfc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      endif


      if(sfcmodel.ge.1)then
        !---- (2) ----!
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = lu_index(i,j)
        enddo
        enddo
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'lu_index',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          dum1(i,j,1) = kpbl2d(i,j)
        enddo
        enddo
        call writer(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'kpbl2d  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,hfx(ib,jb),'hfx     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,qfx(ib,jb),'qfx     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,hpbl(ib,jb),'hpbl    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,wspd(ib,jb),'wspd    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,psim(ib,jb),'psim    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,psih(ib,jb),'psih    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,gz1oz0(ib,jb),'gz1oz0  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,br(ib,jb),'br      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CHS(ib,jb),'chs     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CHS2(ib,jb),'chs2    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CQS2(ib,jb),'cqs2    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CPMM(ib,jb),'cpmm    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,ZOL(ib,jb),'zol     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,MAVAIL(ib,jb),'mavail  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,MOL(ib,jb),'mol     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,RMOL(ib,jb),'rmol    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,REGIME(ib,jb),'regime  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,LH(ib,jb),'lh      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,tmn(ib,jb),'tmn     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,FLHC(ib,jb),'flhc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,FLQC(ib,jb),'flqc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,QGH(ib,jb),'qgh     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CK(ib,jb),'ck      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CKA(ib,jb),'cka     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,CDA(ib,jb),'cda     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,USTM(ib,jb),'ustm    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,QSFC(ib,jb),'qsfc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,T2(ib,jb),'t2      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,Q2(ib,jb),'q2      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,TH2(ib,jb),'th2     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,EMISS(ib,jb),'emiss   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,THC(ib,jb),'thc     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,ALBD(ib,jb),'albd    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,gsw(ib,jb),'gsw     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,glw(ib,jb),'glw     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,chklowq(ib,jb),'chklowq ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,capg(ib,jb),'capg    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,snowc(ib,jb),'snowc   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,fm(ib,jb),'fm      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,fh(ib,jb),'fh      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
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
          call writer(ni,nj,1,1,nx,ny,tslb(ib,jb,n),text1,             &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                      ncid,time_index,restart_format,restart_filetype, &
                      dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        enddo
      endif
      endif

      if(oceanmodel.eq.2)then
        call writer(ni,nj,1,1,nx,ny,tml(ib,jb),'tml     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,t0ml(ib,jb),'t0ml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,hml(ib,jb),'hml     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,h0ml(ib,jb),'h0ml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,huml(ib,jb),'huml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,hvml(ib,jb),'hvml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call writer(ni,nj,1,1,nx,ny,tmoml(ib,jb),'tmoml   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      endif

!---------------------------------------------------------------
!  passive tracers:

      if(iptra.eq.1)then

        if(myid.eq.0)then
          if( restart_format.eq.1 )then
            write(50) npt
#ifdef NETCDF
          elseif( restart_format.eq.2 )then
            call disp_err( nf90_inq_varid(ncid,"npt",varid) , .true. )
            call disp_err( nf90_put_var(ncid,varid,npt,(/time_index/)) , .true. )
#endif
          endif
        endif
        do n=1,npt
          if( n.lt.10 )then
            text1 = 'ptX     '
            write(text1(3:3),161) n
161         format(i1.1)
          elseif( n.lt.100 )then
            text1 = 'ptXX    '
            write(text1(3:4),162) n
162         format(i2.2)
          else
            stop 11512
          endif
          call writer(ni,nj,1,nk,nx,ny,pta(ib,jb,1,n),text1,           &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                      ncid,time_index,restart_format,restart_filetype, &
                      dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        enddo
      else
        if(myid.eq.0)then
          nvar = 0
          if( restart_format.eq.1 )then
            write(50) nvar
#ifdef NETCDF
          elseif( restart_format.eq.2 )then
            call disp_err( nf90_inq_varid(ncid,"npt",varid) , .true. )
            call disp_err( nf90_put_var(ncid,varid,nvar,(/time_index/)) , .true. )
#endif
          endif
        endif
      endif

!---------------------------------------------------------------
!  parcels:

      if(iprcl.eq.1)then
        !-----------------
        ! with parcels:
        if(myid.eq.0)then
          if( restart_format.eq.1 )then
            write(50) nparcels
#ifdef NETCDF
          elseif( restart_format.eq.2 )then
            call disp_err( nf90_inq_varid(ncid,"numparcels",varid) , .true. )
            call disp_err( nf90_put_var(ncid,varid,nparcels,(/time_index/)) , .true. )
#endif
          endif
        endif
        ! only write position info:
        if(myid.eq.0)then
          if( .not. terrain_flag )then
            DO np=1,nparcels
              ploc(np,1)=pdata(np,prx)
              ploc(np,2)=pdata(np,pry)
              ploc(np,3)=pdata(np,prz)
            ENDDO
          else
            DO np=1,nparcels
              ploc(np,1)=pdata(np,prx)
              ploc(np,2)=pdata(np,pry)
              ploc(np,3)=pdata(np,prsig)
            ENDDO
          endif
          if( restart_format.eq.1 )then
            write(50) ploc
#ifdef NETCDF
          elseif( restart_format.eq.2 )then
            call disp_err( nf90_inq_varid(ncid,"ploc",varid) , .true. )
            n = 3
            call disp_err( nf90_put_var(ncid,varid,ploc,(/1,1,time_index/),(/nparcels,n,1/)) , .true. )
#endif
          endif
        endif
      else
        !-----------------
        ! without parcels:
        if(myid.eq.0)then
          nvar = 0
          if( restart_format.eq.1 )then
            write(50) nvar
#ifdef NETCDF
          elseif( restart_format.eq.2 )then
            call disp_err( nf90_inq_varid(ncid,"numparcels",varid) , .true. )
            call disp_err( nf90_put_var(ncid,varid,nvar,(/time_index/)) , .true. )
#endif
          endif
        endif
        !-----------------
      endif

!---------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!---------------------------------------------------------------
!  open bc:

      if(irbc.eq.4)then
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
        if(myid.eq.0)then
          ndum = ny
        else
          ndum = 1
        endif
        allocate( dumy(ndum) )
        !----------------------
      if( wbc.eq.2 )then
        aname = 'radbcw'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in writerbcwe, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          call writerbcwe(radbcw,aname,ndum,dumy,ibw,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,restart_format,myid,k)
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              write(50) dumy
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_put_var(ncid,varid,dumy,(/1,k,time_index/),(/ny,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in writerbcwe, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
        enddo
      endif
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
      if( ebc.eq.2 )then
        aname = 'radbce'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in writerbcwe, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          call writerbcwe(radbce,aname,ndum,dumy,ibe,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,restart_format,myid,k)
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              write(50) dumy
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_put_var(ncid,varid,dumy,(/1,k,time_index/),(/ny,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in writerbcwe, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
        enddo
      endif
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
        deallocate( dumy )
        if(myid.eq.0)then
          ndum = nx
        else
          ndum = 1
        endif
        allocate( dumx(ndum) )
        !----------------------
      if( sbc.eq.2 )then
        aname = 'radbcs'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in writerbcsn, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          call writerbcsn(radbcs,aname,ndum,dumx,ibs,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,restart_format,myid,k)
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              write(50) dumx
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_put_var(ncid,varid,dumx,(/1,k,time_index/),(/nx,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in writerbcsn, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
        enddo
      endif
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
      if( nbc.eq.2 )then
        aname = 'radbcn'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in writerbcsn, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          call writerbcsn(radbcn,aname,ndum,dumx,ibn,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,restart_format,myid,k)
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              write(50) dumx
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_put_var(ncid,varid,dumx,(/1,k,time_index/),(/nx,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in writerbcsn, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
        enddo
      endif
        !----------------------
        deallocate( dumx )
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
      endif

!---------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!---------------------------------------------------------------
!  150820:  optional variables


    IF( restart_file_theta )THEN
      do k=1,nk
      do j=1,nj
      do i=1,ni
        dum1(i,j,k) = th0(i,j,k)+tha(i,j,k)
      enddo
      enddo
      enddo
      call writer(ni,nj,1,nk,nx,ny,dum1(ib,jb,1),'theta   ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_dbz )THEN
      ! cm1r19:
      call writer(ni,nj,1,nk,nx,ny,qdiag(ibdq,jbdq,1,qd_dbz),'dbz     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    !-----
    IF( restart_file_th0 )THEN
      call writer(ni,nj,1,nk,nx,ny,th0(ib,jb,1),'th0     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_prs0 )THEN
      call writer(ni,nj,1,nk,nx,ny,prs0(ib,jb,1),'prs0    ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_pi0 )THEN
      call writer(ni,nj,1,nk,nx,ny,pi0(ib,jb,1),'pi0     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_rho0 )THEN
      call writer(ni,nj,1,nk,nx,ny,rho0(ib,jb,1),'rho0    ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_qv0 )THEN
      call writer(ni,nj,1,nk,nx,ny,qv0(ib,jb,1),'qv0     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_u0 )THEN
      call writer(ni+1,nj,1,nk,nx+1,ny,u0(ib,jb,1),'u0      ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecu,52,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2iu,d2ju,d3iu,d3ju)
    ENDIF
    IF( restart_file_v0 )THEN
      call writer(ni,nj+1,1,nk,nx,ny+1,v0(ib,jb,1),'v0      ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecv,53,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2iv,d2jv,d3iv,d3jv)
    ENDIF
    !-----
    IF( restart_file_zs )THEN
      call writer(ni,nj,1,1,nx,ny,zs(ib,jb),'zs      ',            &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_zh )THEN
      call writer(ni,nj,1,nk,nx,ny,zh(ib,jb,1),'zhalf   ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF
    IF( restart_file_zf )THEN
      call writer(ni,nj,1,nk+1,nx,ny,zf(ib,jb,1),'zfull   ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecw,54,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF

    IF( restart_file_diags )THEN
      if( td_diss.gt.0 )                                                 &
      call writer(ni,nj,1,nk,nx,ny,tdiag(ib,jb,1,td_diss),'dissheat',    &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      if( td_mp.gt.0 )                                                   &
      call writer(ni,nj,1,nk,nx,ny,tdiag(ib,jb,1,td_mp),'mptend  ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      if( qd_vtc.gt.0 )                                                  &
      call writer(ni,nj,1,nk,nx,ny,qdiag(ib,jb,1,qd_vtc),'vtc     ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      if( qd_vtr.gt.0 )                                                  &
      call writer(ni,nj,1,nk,nx,ny,qdiag(ib,jb,1,qd_vtr),'vtr     ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      if( qd_vts.gt.0 )                                                  &
      call writer(ni,nj,1,nk,nx,ny,qdiag(ib,jb,1,qd_vts),'vts     ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      if( qd_vtg.gt.0 )                                                  &
      call writer(ni,nj,1,nk,nx,ny,qdiag(ib,jb,1,qd_vtg),'vtg     ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      if( qd_vti.gt.0 )                                                  &
      call writer(ni,nj,1,nk,nx,ny,qdiag(ib,jb,1,qd_vti),'vti     ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,         &
                  ncid,time_index,restart_format,restart_filetype,       &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    ENDIF

!---------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!---------------------------------------------------------------

      ! cm1r19.7 fix !
      if( myid.eq.0 )then
        write(50) nwriteh
      endif




    IF( restart_format.eq.1 )THEN
      IF(myid.eq.0) close(unit=50)
      IF(myid.eq.nodemaster) close(unit=51)
      IF(myid.eq.nodemaster) close(unit=52)
      IF(myid.eq.nodemaster) close(unit=53)
      IF(myid.eq.nodemaster) close(unit=54)
#ifdef NETCDF
    ELSEIF( restart_format.eq.2 )THEN
      if( myid.eq.0 )then
        call disp_err( nf90_close(ncid) , .true. )
      endif
#endif
    ENDIF

#ifdef MPI
      if(timestats.ge.1)then
        ! this is needed for proper accounting of timing:
        call MPI_BARRIER (MPI_COMM_WORLD,ierr)
      endif
#endif

      return
      end subroutine write_restart


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine read_restart(nstep,srec,sirec,urec,vrec,wrec,nrec,prec,           &
                              trecs,trecw,arecs,arecw,                             &
                              nwrite,nwritet,nwritea,nwriteh,nrst,                 &
                              num_soil_layers,nrad2d,                              &
                              dt,dtlast,mtime,ndt,adt,acfl,dbldt,mass1,            &
                              stattim,taptim,rsttim,radtim,prcltim,                &
                              qbudget,asq,bsq,qname,                               &
                              xfref,yfref,zh,zf,sigma,sigmaf,zs,                   &
                              th0,prs0,pi0,rho0,qv0,u0,v0,                         &
                              rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                              tsk,znt,ust,cd,ch,cq,u1,v1,s1,thflux,qvflux,         &
                              radbcw,radbce,radbcs,radbcn,                         &
                              rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                              swten,lwten,radsw,rnflx,radswnet,radlwin,rad2d,      &
                              effc,effi,effs,effr,effg,effis,                      &
                              lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,      &
                              hpbl,wspd,psim,psih,gz1oz0,br,                       &
                              CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                       &
                              MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                    &
                              CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,       &
                              gsw,glw,chklowq,capg,snowc,fm,fh,tslb,               &
                              tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml,               &
                              qpten,qtten,qvten,qcten,pta,pdata,ploc,ppx,          &
                              tdiag,qdiag,phi1,phi2,                               &
                              icenter,jcenter,xcenter,ycenter,                     &
                              dum1,dat1,dat2,dat3,reqt,restarted,restart_prcl)
      use input
      use constants
#ifdef MPI
      use mpi
#endif
#ifdef NETCDF
      use netcdf
      use writeout_nc_module, only : disp_err
#endif
      implicit none

      !----------------------------------------------------------
      ! This subroutine organizes the reading of restart files
      !----------------------------------------------------------

      integer, intent(inout) :: nstep,srec,sirec,urec,vrec,wrec,nrec,prec,trecs,trecw,arecs,arecw
      integer, intent(inout) :: nwrite,nwritet,nwritea,nwriteh,nrst
      integer, intent(in) :: num_soil_layers,nrad2d
      real, intent(inout) :: dt,dtlast
      integer, intent(inout) :: ndt
      double precision, intent(inout) :: adt,acfl,dbldt,mass1
      double precision, intent(inout) :: mtime,stattim,taptim,rsttim,radtim,prcltim
      double precision, intent(inout), dimension(nbudget) :: qbudget
      double precision, intent(inout), dimension(numq) :: asq,bsq
      character(len=3), intent(in), dimension(maxq) :: qname
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      real, intent(in), dimension(kb:ke) :: sigma
      real, intent(in), dimension(kb:ke+1) :: sigmaf
      real, intent(in), dimension(ib:ie,jb:je) :: zs
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: zh
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: zf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: th0,prs0,pi0,rho0,qv0
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: u0
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: v0
      real, intent(inout), dimension(ib:ie,jb:je,nrain) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, intent(inout), dimension(ib:ie,jb:je) :: tsk,znt,ust,cd,ch,cq,u1,v1,s1,xland,psfc,thflux,qvflux
      real, intent(inout), dimension(jb:je,kb:ke) :: radbcw,radbce
      real, intent(inout), dimension(ib:ie,kb:ke) :: radbcs,radbcn
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: rho,prs
      real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: ppi,tha
      real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa
      real, intent(inout), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea
      real, intent(inout), dimension(ibr:ier,jbr:jer,kbr:ker) :: swten,lwten,effc,effi,effs,effr,effg,effis
      real, intent(inout), dimension(ni,nj) :: radsw,rnflx,radswnet,radlwin
      real, intent(inout), dimension(ni,nj,nrad2d) :: rad2d
      integer, intent(inout), dimension(ibl:iel,jbl:jel) :: lu_index
      integer, intent(inout), dimension(ibl:iel,jbl:jel) :: kpbl2d
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: u10,v10,s10,hfx,qfx, &
                                      hpbl,wspd,psim,psih,gz1oz0,br,          &
                                      CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,          &
                                      MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,   &
                                      CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,   &
                                      gsw,glw,chklowq,capg,snowc,fm,fh
      real, intent(inout), dimension(ibl:iel,jbl:jel,num_soil_layers) :: tslb
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml
      real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem) :: qpten,qtten,qvten,qcten
      real, intent(inout), dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta
      real, intent(inout), dimension(nparcels,npvals) :: pdata
      real, intent(inout), dimension(nparcels,3) :: ploc
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: ppx
      real, intent(inout), dimension(ibph:ieph,jbph:jeph,kbph:keph) :: phi1,phi2
      real, intent(in   ) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
      real, intent(in   ) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
      integer, intent(inout) :: icenter,jcenter
      real, intent(inout) :: xcenter,ycenter
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1
      real, intent(inout), dimension(ni+1,nj+1) :: dat1
      real, intent(inout), dimension(d2i,d2j) :: dat2
      real, intent(inout), dimension(d3i,d3j,d3n) :: dat3
      integer, intent(inout), dimension(d3t) :: reqt
      logical, intent(in) :: restarted
      logical, intent(inout) :: restart_prcl

      character(len=80) fname
      character(len=8) :: text1
      character(len=6) :: aname
      integer :: i,j,k,n,np,nvar,nread,reqs,orecs,orecu,orecv,orecw,ndum
      integer :: ncid,time_index,old_format
      double precision, dimension(nbudget,0:numprocs-1) :: sbudget
      double precision, dimension(numq,0:numprocs-1) :: csq,dsq
      real, dimension(:,:), allocatable :: pfoo
      real, dimension(:), allocatable :: dumx,dumy
#ifdef MPI
      integer :: proc,index,count,req1,req2,req3,reqp
#endif
#ifdef NETCDF
      integer :: varid,ncstatus
#endif

!-----------------------------------------------------------------------

  IF( restart_format.eq.1 )THEN
    ! unformatted direct-access (grads) format:

  IF( restart_filetype.eq.1 )THEN

    !------------------
    ! one restart file (per stagger type):
    IF(myid.eq.nodemaster)THEN
      fname = '                                                                                '
    if(strlen.gt.0)then
      fname(1:strlen) = output_path(1:strlen)
    endif
      fname(strlen+1:strlen+baselen) = output_basename(1:baselen)

      fname(totlen+1:totlen+1+10) = '_rst_x.dat'

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  Reading from restart file!'
      if(dowr) write(outfile,*) '  fname=',fname

      if( myid.eq.0 )  &
      open(unit=50,file=fname,form='unformatted',status='old',err=778)

      fname(totlen+1:totlen+1+10) = '_rst_s.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=51,file=fname,form='unformatted',access='direct',recl=4*nx*ny,status='old',err=778)
      orecs = 1

      fname(totlen+1:totlen+1+10) = '_rst_u.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=52,file=fname,form='unformatted',access='direct',recl=4*(nx+1)*ny,status='old',err=778)
      orecu = 1

      fname(totlen+1:totlen+1+10) = '_rst_v.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=53,file=fname,form='unformatted',access='direct',recl=4*nx*(ny+1),status='old',err=778)
      orecv = 1

      fname(totlen+1:totlen+1+10) = '_rst_w.dat'
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=54,file=fname,form='unformatted',access='direct',recl=4*nx*ny,status='old',err=778)
      orecw = 1

      if(dowr) write(outfile,*)
    ENDIF

  ELSEIF( restart_filetype.eq.2 )THEN

    !------------------
    ! one restart file (per restart time):
    IF(myid.eq.nodemaster)THEN
      fname = '                                                                                '
    if(strlen.gt.0)then
      fname(1:strlen) = output_path(1:strlen)
    endif
      fname(strlen+1:strlen+baselen) = output_basename(1:baselen)

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_x.dat'
      write(fname(totlen+ 6:totlen+11),101) rstnum
101   format(i6.6)

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  Reading from restart file!'
      if(dowr) write(outfile,*) '  fname=',fname

      if( myid.eq.0 )  &
      open(unit=50,file=fname,form='unformatted',status='old',err=778)

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_s.dat'
      write(fname(totlen+ 6:totlen+11),101) rstnum
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=51,file=fname,form='unformatted',access='direct',recl=4*nx*ny,status='old',err=778)
      orecs = 1

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_u.dat'
      write(fname(totlen+ 6:totlen+11),101) rstnum
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=52,file=fname,form='unformatted',access='direct',recl=4*(nx+1)*ny,status='old',err=778)
      orecu = 1

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_v.dat'
      write(fname(totlen+ 6:totlen+11),101) rstnum
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=53,file=fname,form='unformatted',access='direct',recl=4*nx*(ny+1),status='old',err=778)
      orecv = 1

      fname(totlen+1:totlen+1+17) = '_rst_XXXXXX_w.dat'
      write(fname(totlen+ 6:totlen+11),101) rstnum
      if(dowr) write(outfile,*) '  fname=',fname
      open(unit=54,file=fname,form='unformatted',access='direct',recl=4*nx*ny,status='old',err=778)
      orecw = 1

      if(dowr) write(outfile,*)
    ENDIF

  ELSEIF( restart_filetype.eq.3 )THEN

    !------------------
    ! one restart file per node (cm1r17 format):
    IF(myid.eq.nodemaster)THEN
      fname = '                                                                                '
    if(strlen.gt.0)then
      fname(1:strlen) = output_path(1:strlen)
    endif
      fname(strlen+1:strlen+baselen) = output_basename(1:baselen)
      fname(totlen+1:totlen+1+22) = '_rst_XXXXXX_YYYYYY.dat'

      write(fname(totlen+ 6:totlen+11),102) mynode
      write(fname(totlen+13:totlen+18),102) rstnum
102   format(i6.6)

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  Reading from restart file!'
      if(dowr) write(outfile,*) '  fname=',fname
      if(dowr) write(outfile,*)

      open(unit=50,file=fname,form='unformatted',status='old')
    ENDIF
  ELSE
    stop 12389
  ENDIF

#ifdef NETCDF
  ELSEIF( restart_format.eq.2 )THEN
    ! netcdf format:

    if( myid.eq.0 )then

    IF(     restart_filetype.eq.1 )THEN
      string(totlen+1:totlen+22) = '_rst.nc               '
      time_index = rstnum
    ELSEIF( restart_filetype.eq.2 )THEN
      string(totlen+1:totlen+22) = '_rst_XXXXXX.nc        '
      write(string(totlen+6:totlen+11),100) rstnum
100   format(i6.6)
      time_index = 1
    ENDIF
      if(myid.eq.0) print *,'  string = ',string

      call disp_err( nf90_open( path=string , mode=nf90_nowrite , ncid=ncid ) , .true. )

    endif

#endif
  ELSE

    if( myid.eq.0 )then
      print *
      print *,'  unrecognized value for restart_format '
      print *
      print *,'      restart_format = ',restart_format
      print *
    endif
#ifdef MPI
    call MPI_BARRIER (MPI_COMM_WORLD,ierr)
#endif
    call stopcm1

  ENDIF

!---------------------------------------------------------------
! metadata:

  IF( restart_format.eq.1 )THEN
    IF(myid.eq.0)THEN
      ! only processor 0 has these variables:
      read(50) nstep
      read(50) srec
      read(50) sirec
      read(50) urec
      read(50) vrec
      read(50) wrec
      read(50) nrec
      read(50) prec
      read(50) trecs
      read(50) trecw
      read(50) arecs
      read(50) arecw
      read(50) nwrite
      read(50) nwritet
      read(50) nwritea
      read(50) nrst
      read(50) ndt
      read(50) icenter
      read(50) jcenter
      read(50) old_format
      read(50) dt
      read(50) dtlast
      read(50) xcenter
      read(50) ycenter
      read(50) cflmax
      read(50) mtime
      read(50) stattim
      read(50) taptim
      read(50) rsttim
      read(50) radtim
      read(50) prcltim
      read(50) adt
      read(50) acfl
      read(50) dbldt
      read(50) mass1
    ENDIF
#ifdef NETCDF
  ELSEIF( restart_format.eq.2 )THEN
    IF(myid.eq.0)THEN

      call disp_err( nf90_inq_varid(ncid,"nstep",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nstep,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"srec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,srec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"sirec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,sirec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"urec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,urec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"vrec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,vrec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"wrec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,wrec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nrec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nrec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"prec",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,prec,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"trecs",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,trecs,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"trecw",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,trecw,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"arecs",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,arecs,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"arecw",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,arecw,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwrite",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nwrite,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwritet",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nwritet,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwritea",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nwritea,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nwriteh",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nwriteh,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"nrst",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,nrst,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"ndt",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,ndt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"icenter",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,icenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"jcenter",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,jcenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"old_format",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,old_format,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"dt",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,dt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"dtlast",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,dtlast,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"xcenter",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,xcenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"ycenter",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,ycenter,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"cflmax",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,cflmax,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"mtime",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,mtime,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"stattim",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,stattim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"taptim",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,taptim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"rsttim",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,rsttim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"radtim",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,radtim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"prcltim",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,prcltim,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"adt",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,adt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"acfl",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,acfl,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"dbldt",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,dbldt,(/time_index/)) , .true. )

      call disp_err( nf90_inq_varid(ncid,"mass1",varid) , .true. )
      call disp_err( nf90_get_var(ncid,varid,mass1,(/time_index/)) , .true. )

    ENDIF
#endif
  ENDIF

#ifdef MPI
      ! communicate to all other processors:
      call MPI_BCAST(nstep  ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(srec   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(sirec  ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(urec   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(vrec   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(wrec   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(nrec   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(prec   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(trecs  ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(trecw  ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(arecs  ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(arecw  ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(nwrite ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(nwritet,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(nwritea,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(nrst   ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(ndt    ,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(icenter,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(jcenter,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(old_format,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(dt     ,1,MPI_REAL            ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(dtlast ,1,MPI_REAL            ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(xcenter,1,MPI_REAL            ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(ycenter,1,MPI_REAL            ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(cflmax ,1,MPI_REAL            ,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(mtime  ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(stattim,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(taptim ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(rsttim ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(radtim ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(prcltim,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(adt    ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(acfl   ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(dbldt  ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(mass1  ,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,ierr)
#endif

!---------------------------------------------------------------
! budget variables:

    IF( myid.eq.0 )THEN

      IF( restart_format.eq.1 )THEN
        read(50) qbudget
        read(50) asq
        read(50) bsq
#ifdef NETCDF
      ELSEIF( restart_format.eq.2 )THEN
        call disp_err( nf90_inq_varid(ncid,"qbudget",varid) , .true. )
        call disp_err( nf90_get_var(ncid,varid,qbudget,(/1,time_index/),(/nbudget,1/)) , .true. )
        call disp_err( nf90_inq_varid(ncid,"asq",varid) , .true. )
        call disp_err( nf90_get_var(ncid,varid,asq,(/1,time_index/),(/numq,1/)) , .true. )
        call disp_err( nf90_inq_varid(ncid,"bsq",varid) , .true. )
        call disp_err( nf90_get_var(ncid,varid,bsq,(/1,time_index/),(/numq,1/)) , .true. )
#endif
      ENDIF

    ELSE

      qbudget = 0.0
      asq = 0.0
      bsq = 0.0

    ENDIF

!---------------------------------------------------------------
! standard 2D:

      n = 1
      call  readr(ni,nj,1,1,nx,ny,rain(ib,jb,n),'rain    ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sws(ib,jb,n),'sws     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,svs(ib,jb,n),'svs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sps(ib,jb,n),'sps     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,srs(ib,jb,n),'srs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sgs(ib,jb,n),'sgs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sus(ib,jb,n),'sus     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,shs(ib,jb,n),'shs     ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    if( nrain.eq.2 )then
      n = 2
      call  readr(ni,nj,1,1,nx,ny,rain(ib,jb,n),'rain2   ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sws(ib,jb,n),'sws2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,svs(ib,jb,n),'svs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sps(ib,jb,n),'sps2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,srs(ib,jb,n),'srs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sgs(ib,jb,n),'sgs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,sus(ib,jb,n),'sus2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,1,nx,ny,shs(ib,jb,n),'shs2    ',         &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif
      call  readr(ni,nj,1,1,nx,ny,tsk(ib,jb),'tsk     ',           &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)

!---------------------------------------------------------------
! standard 3D:

      call  readr(ni,nj,1,nk,nx,ny,rho(ib,jb,1),'rho     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,prs(ib,jb,1),'prs     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni+1,nj,1,nk,nx+1,ny,ua(ib,jb,1),'ua      ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecu,52,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2iu,d2ju,d3iu,d3ju)
      call  readr(ni,nj+1,1,nk,nx,ny+1,va(ib,jb,1),'va      ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecv,53,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2iv,d2jv,d3iv,d3jv)
      call  readr(ni,nj,1,nk+1,nx,ny,wa(ib,jb,1),'wa      ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecw,54,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,ppi(ib,jb,1),'ppi     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,tha(ib,jb,1),'tha     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,ppx(ib,jb,1),'ppx     ',        &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    if( psolver.eq.6 )then
      call  readr(ni,nj,1,nk,nx,ny,phi1(ib,jb,1),'phi1    ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,phi2(ib,jb,1),'phi2    ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif
    IF(imoist.eq.1)THEN
    do n=1,numq
      text1 = '        '
      write(text1(1:3),156) qname(n)
156   format(a3)
      call  readr(ni,nj,1,nk,nx,ny,qa(ib,jb,1,n),text1     ,       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    enddo
    ENDIF
    if(imoist.eq.1.and.eqtset.eq.2)then
      call  readr(ni,nj,1,nk,nx,ny,qpten(ib,jb,1),'qpten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,qtten(ib,jb,1),'qtten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,qvten(ib,jb,1),'qvten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      call  readr(ni,nj,1,nk,nx,ny,qcten(ib,jb,1),'qcten   ',      &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif
    if(sgsmodel.eq.1)then
      call  readr(ni,nj,1,nk+1,nx,ny,tkea(ib,jb,1),'tkea    ',     &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecw,54,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
    endif

!---------------------------------------------------------------
!  radiation:

      if(radopt.ge.1)then
        call  readr(ni,nj,1,nk,nx,ny,lwten(ib,jb,1),'lwten   ',      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,nk,nx,ny,swten(ib,jb,1),'swten   ',      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'radsw   ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          radsw(i,j) = dum1(i,j,1)
        enddo
        enddo
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'rnflx   ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          rnflx(i,j) = dum1(i,j,1)
        enddo
        enddo
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'radswnet',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          radswnet(i,j) = dum1(i,j,1)
        enddo
        enddo
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'radlwin ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          radlwin(i,j) = dum1(i,j,1)
        enddo
        enddo
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
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),text1,             &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          rad2d(i,j,n) = dum1(i,j,1)
        enddo
        enddo
        enddo
      endif
      if( radopt.ge.1 .and. ptype.eq.5 )then
        call  readr(ni,nj,1,nk,nx,ny,effc(ib,jb,1),'effc    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,nk,nx,ny,effi(ib,jb,1),'effi    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,nk,nx,ny,effs(ib,jb,1),'effs    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,nk,nx,ny,effr(ib,jb,1),'effr    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,nk,nx,ny,effg(ib,jb,1),'effg    ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,nk,nx,ny,effis(ib,jb,1),'effis   ',      &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      endif

!---------------------------------------------------------------
!  surface:
!     I don't know how many of these are really needed in restart
!     files, but let's include them all for now ... just to be safe

      if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
        !---- (1) ----!
      if(sfcmodel.ge.1)then
        call  readr(ni,nj,1,1,nx,ny,ust(ib,jb),'ust     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,znt(ib,jb),'znt     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,cd(ib,jb),'cd      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,ch(ib,jb),'ch      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,cq(ib,jb),'cq      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,u1(ib,jb),'u1      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,v1(ib,jb),'v1      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,s1(ib,jb),'s1      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,u10(ib,jb),'u10     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,v10(ib,jb),'v10     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,s10(ib,jb),'s10     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,xland(ib,jb),'xland   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,thflux(ib,jb),'thflux  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,qvflux(ib,jb),'qvflux  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,psfc(ib,jb),'psfc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      endif


      if(sfcmodel.ge.1)then
        !---- (2) ----!
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'lu_index',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          lu_index(i,j) = nint(dum1(i,j,1))
        enddo
        enddo
        call  readr(ni,nj,1,1,nx,ny,dum1(ib,jb,1),'kpbl2d  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
!$omp parallel do default(shared)  &
!$omp private(i,j)
        do j=1,nj
        do i=1,ni
          kpbl2d(i,j) = nint(dum1(i,j,1))
        enddo
        enddo
        call  readr(ni,nj,1,1,nx,ny,hfx(ib,jb),'hfx     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,qfx(ib,jb),'qfx     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,hpbl(ib,jb),'hpbl    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,wspd(ib,jb),'wspd    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,psim(ib,jb),'psim    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,psih(ib,jb),'psih    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,gz1oz0(ib,jb),'gz1oz0  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,br(ib,jb),'br      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CHS(ib,jb),'chs     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CHS2(ib,jb),'chs2    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CQS2(ib,jb),'cqs2    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CPMM(ib,jb),'cpmm    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,ZOL(ib,jb),'zol     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,MAVAIL(ib,jb),'mavail  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,MOL(ib,jb),'mol     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,RMOL(ib,jb),'rmol    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,REGIME(ib,jb),'regime  ',        &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,LH(ib,jb),'lh      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,tmn(ib,jb),'tmn     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,FLHC(ib,jb),'flhc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,FLQC(ib,jb),'flqc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,QGH(ib,jb),'qgh     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CK(ib,jb),'ck      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CKA(ib,jb),'cka     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,CDA(ib,jb),'cda     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,USTM(ib,jb),'ustm    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,QSFC(ib,jb),'qsfc    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,T2(ib,jb),'t2      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,Q2(ib,jb),'q2      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,TH2(ib,jb),'th2     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,EMISS(ib,jb),'emiss   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,THC(ib,jb),'thc     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,ALBD(ib,jb),'albd    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,gsw(ib,jb),'gsw     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,glw(ib,jb),'glw     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,chklowq(ib,jb),'chklowq ',       &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,capg(ib,jb),'capg    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,snowc(ib,jb),'snowc   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,fm(ib,jb),'fm      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,fh(ib,jb),'fh      ',            &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
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
        call  readr(ni,nj,1,1,nx,ny,tslb(ib,jb,n),text1,             &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        enddo
      endif
      endif

      if(oceanmodel.eq.2)then
        call  readr(ni,nj,1,1,nx,ny,tml(ib,jb),'tml     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,t0ml(ib,jb),'t0ml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,hml(ib,jb),'hml     ',           &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,h0ml(ib,jb),'h0ml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,huml(ib,jb),'huml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,hvml(ib,jb),'hvml    ',          &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
        call  readr(ni,nj,1,1,nx,ny,tmoml(ib,jb),'tmoml   ',         &
                    ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                    ncid,time_index,restart_format,restart_filetype, &
                    dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      endif

!---------------------------------------------------------------
!  passive tracers:

      if( myid.eq.0 )then
        if( restart_format.eq.1 )then
          read(50) nvar
#ifdef NETCDF
        elseif( restart_format.eq.2 )then
          call disp_err( nf90_inq_varid(ncid,"npt",varid) , .true. )
          call disp_err( nf90_get_var(ncid,varid,nvar,(/time_index/)) , .true. )
          if( iptra.eq.0 ) nvar = 0
#endif
        endif
        print *,'  nvar_npt = ',nvar
      endif

#ifdef MPI
      call MPI_BCAST(nvar,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
#endif

      if( iptra.eq.1 .or. nvar.gt.0 )then
        if( nvar.gt.0 )then
          nread = 0
          if( iptra.eq.1 )then
            do n=1,min(nvar,npt)
              if( n.lt.10 )then
                text1 = 'ptX     '
                write(text1(3:3),161) n
161             format(i1.1)
              elseif( n.lt.100 )then
                text1 = 'ptXX    '
                write(text1(3:4),162) n
162             format(i2.2)
              else
                stop 11512
              endif
              call  readr(ni,nj,1,nk,nx,ny,pta(ib,jb,1,n),text1,           &
                          ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                          ncid,time_index,restart_format,restart_filetype, &
                          dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
              nread = nread+1
            enddo
          endif
          if( nread .lt. nvar )then
            ! need to read more data ....
            do n=nread+1,nvar
              if( n.lt.10 )then
                text1 = 'ptX     '
                write(text1(3:3),161) n
              elseif( n.lt.100 )then
                text1 = 'ptXX    '
                write(text1(3:4),162) n
              else
                stop 11513
              endif
              call  readr(ni,nj,1,nk,nx,ny,dum1(ib,jb,1),text1,            &
                          ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                          ncid,time_index,restart_format,restart_filetype, &
                          dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
            enddo
          endif
        else
          if( myid.eq.0 ) print *
          if( myid.eq.0 ) print *,'  Note:  no passive tracer data in the restart file '
          if( myid.eq.0 ) print *
        endif
      endif

!---------------------------------------------------------------
!  parcels:

      if( myid.eq.0 )then
        if( restart_format.eq.1 )then
          read(50) nvar
#ifdef NETCDF
        elseif( restart_format.eq.2 )then
          call disp_err( nf90_inq_varid(ncid,"numparcels",varid) , .true. )
          call disp_err( nf90_get_var(ncid,varid,nvar,(/time_index/)) , .true. )
          if( iprcl.eq.0 ) nvar = 0
#endif
        endif
        print *,'  nvar_parcels = ',nvar
      endif

#ifdef MPI
      call MPI_BCAST(nvar,1,MPI_INTEGER,0,MPI_COMM_WORLD,ierr)
#endif

      if( iprcl.eq.1 .or. nvar.gt.0 )then
        if( nvar.gt.0 )then
          ! only read position info:
          if( myid.eq.0 )then
            IF( nvar.eq.nparcels )THEN
              ! easy:  restart file matches current config
              if( restart_format.eq.1 )then
                read(50) ploc
#ifdef NETCDF
              elseif( restart_format.eq.2 )then
                call disp_err( nf90_inq_varid(ncid,"ploc",varid) , .true. )
                n = 3
                call disp_err( nf90_get_var(ncid,varid,ploc,(/1,1,time_index/),(/nparcels,n,1/)) , .true. )
#endif
              endif
            ELSE
              ! annoying:  restart file has different nparcels than current config
              IF( iprcl.eq.1 )THEN
                if( .not. terrain_flag )then
                  do np=1,nparcels
                    ploc(np,1) = pdata(np,prx)
                    ploc(np,2) = pdata(np,pry)
                    ploc(np,3) = pdata(np,prz)
                  enddo
                else
                  do np=1,nparcels
                    ploc(np,1) = pdata(np,prx)
                    ploc(np,2) = pdata(np,pry)
                    ploc(np,3) = pdata(np,prsig)
                  enddo
                endif
              ENDIF
              if( myid.eq.0 ) print *,'  start pfoo ' 
              allocate( pfoo(nvar,3) )
              if( restart_format.eq.1 )then
                read(50) pfoo
#ifdef NETCDF
              elseif( restart_format.eq.2 )then
                call disp_err( nf90_inq_varid(ncid,"ploc",varid) , .true. )
                n = 3
                call disp_err( nf90_get_var(ncid,varid,pfoo,(/1,1,time_index/),(/nvar,n,1/)) , .true. )
#endif
              endif
              IF( iprcl.eq.1 )THEN
                do n=1,3
                do np=1,min(nvar,nparcels)
                  ploc(np,n) = pfoo(np,n)
                enddo
                enddo
              ENDIF
              deallocate( pfoo )
              if( myid.eq.0 ) print *,'  end pfoo ' 
            ENDIF
          endif
          IF( iprcl.eq.1 )THEN
#ifdef MPI
            call MPI_BCAST(ploc,3*nparcels,MPI_REAL,0,MPI_COMM_WORLD,ierr)
#endif
            if( .not. terrain_flag )then
              DO np=1,nparcels
                pdata(np,prx)=ploc(np,1)
                pdata(np,pry)=ploc(np,2)
                pdata(np,prz)=ploc(np,3)
              ENDDO
            else
              DO np=1,nparcels
                pdata(np,prx)=ploc(np,1)
                pdata(np,pry)=ploc(np,2)
                pdata(np,prsig)=ploc(np,3)
              ENDDO
            endif
            restart_prcl = .true.
          ENDIF
        else
          if( myid.eq.0 ) print *
          if( myid.eq.0 ) print *,'  Note:  no parcel data in the restart file '
          if( myid.eq.0 ) print *
          restart_prcl = .false.
        endif
      endif

!---------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!---------------------------------------------------------------
!  open bc:

      if(irbc.eq.4)then
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
        if(myid.eq.0)then
          ndum = ny
        else
          ndum = 1
        endif
        allocate( dumy(ndum) )
        !----------------------
      if( wbc.eq.2 )then
        aname = 'radbcw'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in readrbcwe, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              read(50) dumy
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_get_var(ncid,varid,dumy,(/1,k,time_index/),(/ny,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in readrbcwe, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
          call readrbcwe(radbcw,aname,ndum,dumy,ibw,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,restart_format,myid,k)
        enddo
      endif
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
      if( ebc.eq.2 )then
        aname = 'radbce'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in readrbcwe, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              read(50) dumy
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_get_var(ncid,varid,dumy,(/1,k,time_index/),(/ny,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in readrbcwe, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
          call readrbcwe(radbce,aname,ndum,dumy,ibe,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,restart_format,myid,k)
        enddo
      endif
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
        deallocate( dumy )
        if(myid.eq.0)then
          ndum = nx
        else
          ndum = 1
        endif
        allocate( dumx(ndum) )
        !----------------------
      if( sbc.eq.2 )then
        aname = 'radbcs'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in readrbcsn, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              read(50) dumx
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_get_var(ncid,varid,dumx,(/1,k,time_index/),(/nx,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in readrbcsn, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
          call readrbcsn(radbcs,aname,ndum,dumx,ibs,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,restart_format,myid,k)
        enddo
      endif
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
      if( nbc.eq.2 )then
        aname = 'radbcn'
#ifdef NETCDF
        if( restart_format.eq.2 .and. myid.eq.0 )then
          ncstatus = nf90_inq_varid(ncid,aname,varid)
          if(ncstatus.ne.nf90_noerr)then
            print *,'  Error1 in readrbcsn, aname = ',aname
            print *,nf90_strerror(ncstatus)
            call stopcm1
          endif
        endif
#endif
        do k=1,nk
          if( myid.eq.0 )then
            if( restart_format.eq.1 )then
              read(50) dumx
#ifdef NETCDF
            elseif( restart_format.eq.2 )then
              ncstatus = nf90_get_var(ncid,varid,dumx,(/1,k,time_index/),(/nx,1,1/))
              if(ncstatus.ne.nf90_noerr)then
                print *,'  Error2 in readrbcsn, aname = ',aname
                print *,nf90_strerror(ncstatus)
                call stopcm1
              endif
#endif
            endif
          endif
          call readrbcsn(radbcn,aname,ndum,dumx,ibn,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,restart_format,myid,k)
        enddo
      endif
        !----------------------
        deallocate( dumx )
        !----------------------
        !cccccccccccccccccccccc
        !----------------------
      endif

!---------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!---------------------------------------------------------------
!  151001:  use theta  (over-rides perturbation value that was read-in above)


    IF( restart_use_theta )THEN
      call  readr(ni,nj,1,nk,nx,ny,dum1(ib,jb,1),'theta   ',       &
                  ni,nj,ngxy,myid,numprocs,nodex,nodey,orecs,51,   &
                  ncid,time_index,restart_format,restart_filetype, &
                  dat1(1,1),dat2(1,1),dat3(1,1,1),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2is,d2js,d3is,d3js)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        tha(i,j,k) = dum1(i,j,k)-th0(i,j,k)
      enddo
      enddo
      enddo
    ENDIF

!---------------------------------------------------------------
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!---------------------------------------------------------------

      ! cm1r19.7 fix !
      if( myid.eq.0 )then
        read(50) nwriteh
      endif
#ifdef MPI
      call MPI_BCAST(nwriteh,1,MPI_INTEGER         ,0,MPI_COMM_WORLD,ierr)
#endif

    IF( restart_format.eq.1 )THEN
      IF(myid.eq.0) close(unit=50)
      IF(myid.eq.nodemaster) close(unit=51)
      IF(myid.eq.nodemaster) close(unit=52)
      IF(myid.eq.nodemaster) close(unit=53)
      IF(myid.eq.nodemaster) close(unit=54)
#ifdef NETCDF
    ELSEIF( restart_format.eq.2 )THEN
      if( myid.eq.0 )then
        call disp_err( nf90_close(ncid) , .true. )
      endif
#endif
    ENDIF

    if( restarted ) nrst = nrst+1

!---------

      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '  From restart file: '
      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '   mtime   = ',mtime
      if(dowr) write(outfile,*) '   stattim = ',stattim
      if(dowr) write(outfile,*) '   taptim  = ',taptim
      if(dowr) write(outfile,*) '   rsttim  = ',rsttim
      if(dowr) write(outfile,*) '   radtim  = ',radtim
      if(dowr) write(outfile,*) '   prcltim = ',prcltim
      if(dowr) write(outfile,*)
      if(dowr) write(outfile,*) '   nstep   = ',nstep
      if(dowr) write(outfile,*) '   srec    = ',srec
      if(dowr) write(outfile,*) '   sirec   = ',sirec
      if(dowr) write(outfile,*) '   urec    = ',urec
      if(dowr) write(outfile,*) '   vrec    = ',vrec
      if(dowr) write(outfile,*) '   wrec    = ',wrec
      if(dowr) write(outfile,*) '   nrec    = ',nrec
      if(dowr) write(outfile,*) '   prec    = ',prec
      if(dowr) write(outfile,*) '   nwrite  = ',nwrite
      if(dowr) write(outfile,*) '   nrst    = ',nrst
      if( doturbdiag )then
      if(dowr) write(outfile,*) '   trecs   = ',trecs
      if(dowr) write(outfile,*) '   trecw   = ',trecw
      if(dowr) write(outfile,*) '   nwritet = ',nwritet
      endif
      if( doazimavg )then
      if(dowr) write(outfile,*) '   arecs   = ',arecs
      if(dowr) write(outfile,*) '   arecw   = ',arecw
      if(dowr) write(outfile,*) '   nwritea = ',nwritea
      endif
      if( dohifrq )then
      if(dowr) write(outfile,*) '   nwriteh = ',nwriteh
      endif
      if(dowr) write(outfile,*)

!---------

      if( adapt_dt.eq.0 ) dt = dtl

      ! this is needed for stats files:
      nrec=nrec-1

      IF( output_format .ne. old_format )THEN
        srec = 1
        sirec = 1
        urec = 1
        vrec = 1
        wrec = 1
        nrec = 1
        nwrite = 1
        prec = 1
      ENDIF

!---------

#ifdef MPI
      if(timestats.ge.1)then
        ! this is needed for proper accounting of timing:
        call MPI_BARRIER (MPI_COMM_WORLD,ierr)
      endif
#endif

      return

778   print *,'  error opening restart file '
      print *,'    ... stopping cm1 ... '
      call stopcm1

      end subroutine read_restart


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine writerbcwe(radbc,aname,ndum,dumy,ibndy,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,restart_format,myid,k)
#ifdef MPI
      use mpi
#endif
      implicit none

      integer, intent(in) :: ndum,ibndy,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,k
      real, intent(in), dimension(jb:je,kb:ke) :: radbc
      character(len=6), intent(in) :: aname
      real, intent(inout), dimension(ndum) :: dumy
      integer, intent(in) :: restart_format,myid

      integer :: j,j1,j2
#ifdef MPI
      integer :: fooi,fooj,proc,reqs,ierr
#endif

#ifndef MPI
      do j=1,ny
        dumy(j) = radbc(j,k)
      enddo
#else
      IF(myid.ne.0)THEN
        if( ibndy.eq.1 )then
          call MPI_ISEND(radbc(1,k),nj,MPI_REAL,0,31,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        endif
      ELSE
        if( (aname.eq.'radbcw') .or. (aname.eq.'radbce' .and. nodex.eq.1) )then
          do j=1,nj
            dumy(j) = radbc(j,k)
          enddo
          j1 = 2
          j2 = nodey
        else
          j1 = 1
          j2 = nodey
        endif
        do j=j1,j2
          if( aname.eq.'radbcw' )then
            proc = (j-1)*nodex
          else
            proc = (j-1)*nodex + (nodex-1)
          endif
          fooj = proc / nodex + 1
          fooi = proc - (fooj-1)*nodex  + 1
          call MPI_IRECV(dumy((fooj-1)*nj+1),nj,MPI_REAL,proc,31,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        enddo
      ENDIF
#endif

      end subroutine writerbcwe


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine writerbcsn(radbc,aname,ndum,dumx,ibndy,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,restart_format,myid,k)
#ifdef MPI
      use mpi
#endif
      implicit none

      integer, intent(in) :: ndum,ibndy,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,k
      real, intent(in), dimension(ib:ie,kb:ke) :: radbc
      character(len=6), intent(in) :: aname
      real, intent(inout), dimension(ndum) :: dumx
      integer, intent(in) :: restart_format,myid

      integer :: i,i1,i2
#ifdef MPI
      integer :: fooi,fooj,proc,reqs,ierr
#endif

#ifndef MPI
      do i=1,nx
        dumx(i) = radbc(i,k)
      enddo
#else
      IF(myid.ne.0)THEN
        if( ibndy.eq.1 )then
          call MPI_ISEND(radbc(1,k),ni,MPI_REAL,0,32,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        endif
      ELSE
        if( (aname.eq.'radbcs') .or. (aname.eq.'radbcn' .and. nodey.eq.1) )then
          do i=1,ni
            dumx(i) = radbc(i,k)
          enddo
          i1 = 2
          i2 = nodex
        else
          i1 = 1
          i2 = nodex
        endif
        do i=i1,i2
          if( aname.eq.'radbcs' )then
            proc = (i-1)
          else
            proc = (i-1) + nodex*(nodey-1)
          endif
          fooj = proc / nodex + 1
          fooi = proc - (fooj-1)*nodex  + 1
          call MPI_IRECV(dumx((fooi-1)*ni+1),ni,MPI_REAL,proc,32,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        enddo
      ENDIF
#endif

      end subroutine writerbcsn


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine  readrbcwe(radbc,aname,ndum,dumy,ibndy,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,restart_format,myid,k)
#ifdef MPI
      use mpi
#endif
      implicit none

      integer, intent(in) :: ndum,ibndy,jb,je,kb,ke,ny,ni,nj,nk,nodex,nodey,k
      real, intent(inout), dimension(jb:je,kb:ke) :: radbc
      character(len=6), intent(in) :: aname
      real, intent(inout), dimension(ndum) :: dumy
      integer, intent(in) :: restart_format,myid

      integer :: j,j1,j2
#ifdef MPI
      integer :: fooi,fooj,proc,reqs,ierr
#endif

#ifndef MPI
      do j=1,ny
        radbc(j,k) = dumy(j)
      enddo
#else
      IF(myid.ne.0)THEN
        if( ibndy.eq.1 )then
          call MPI_IRECV(radbc(1,k),nj,MPI_REAL,0,33,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        endif
      ELSE
        if( (aname.eq.'radbcw') .or. (aname.eq.'radbce' .and. nodex.eq.1) )then
          do j=1,nj
            radbc(j,k) = dumy(j)
          enddo
          j1 = 2
          j2 = nodey
        else
          j1 = 1
          j2 = nodey
        endif
        do j=j1,j2
          if( aname.eq.'radbcw' )then
            proc = (j-1)*nodex
          else
            proc = (j-1)*nodex + (nodex-1)
          endif
          fooj = proc / nodex + 1
          fooi = proc - (fooj-1)*nodex  + 1
          call MPI_ISEND(dumy((fooj-1)*nj+1),nj,MPI_REAL,proc,33,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        enddo
      ENDIF
#endif

      end subroutine  readrbcwe


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      subroutine  readrbcsn(radbc,aname,ndum,dumx,ibndy,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,restart_format,myid,k)
#ifdef MPI
      use mpi
#endif
      implicit none

      integer, intent(in) :: ndum,ibndy,ib,ie,kb,ke,nx,ni,nj,nk,nodex,nodey,k
      real, intent(inout), dimension(ib:ie,kb:ke) :: radbc
      character(len=6), intent(in) :: aname
      real, intent(inout), dimension(ndum) :: dumx
      integer, intent(in) :: restart_format,myid

      integer :: i,i1,i2
#ifdef MPI
      integer :: fooi,fooj,proc,reqs,ierr
#endif

#ifndef MPI
      do i=1,nx
        radbc(i,k) = dumx(i)
      enddo
#else
      IF(myid.ne.0)THEN
        if( ibndy.eq.1 )then
          call MPI_IRECV(radbc(1,k),ni,MPI_REAL,0,34,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        endif
      ELSE
        if( (aname.eq.'radbcs') .or. (aname.eq.'radbcn' .and. nodey.eq.1) )then
          do i=1,ni
            radbc(i,k) = dumx(i)
          enddo
          i1 = 2
          i2 = nodex
        else
          i1 = 1
          i2 = nodex
        endif
        do i=i1,i2
          if( aname.eq.'radbcs' )then
            proc = (i-1)
          else
            proc = (i-1) + nodex*(nodey-1)
          endif
          fooj = proc / nodex + 1
          fooi = proc - (fooj-1)*nodex  + 1
          call MPI_ISEND(dumx((fooi-1)*ni+1),ni,MPI_REAL,proc,34,MPI_COMM_WORLD,reqs,ierr)
          call MPI_WAIT(reqs,mpi_status_ignore,ierr)
        enddo
      ENDIF
#endif

      end subroutine  readrbcsn


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine writer(numi,numj,numk1,numk2,nxr,nyr,var,aname,           &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orec,nfile,   &
                      ncid,time_index,restart_format,restart_filetype,   &
                      dat1,dat2,dat3,reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)
#ifdef MPI
    use mpi
#endif
#ifdef NETCDF
    use netcdf
#endif
    implicit none

    !-------------------------------------------------------------------
    ! This subroutine collects data (from other processors if this is a
    ! MPI run) and does the actual writing of restart files.
    !-------------------------------------------------------------------

    integer, intent(in) :: numi,numj,numk1,numk2,nxr,nyr
    integer, intent(in) :: ppnode,d3n,d3t,d2i,d2j,d3i,d3j
    real, intent(in   ), dimension(1-ngxy:numi+ngxy,1-ngxy:numj+ngxy,numk1:numk2) :: var
    character(len=8), intent(in) :: aname
    integer, intent(in) :: ni,nj,ngxy,myid,numprocs,nodex,nodey
    integer, intent(inout) :: orec,ncid
    integer, intent(in) :: time_index,restart_format,restart_filetype
    real, intent(inout), dimension(numi,numj) :: dat1
    real, intent(inout), dimension(d2i,d2j) :: dat2
    real, intent(inout), dimension(d3i,d3j,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, intent(in) :: mynode,nodemaster,nodes,nfile

    integer :: i,j,k,msk
#ifdef MPI
    integer :: reqs,index,index2,n,nn,nnn,fooi,fooj,proc,ierr,ntot,n1,n2,tag
    logical :: recv1,recv2
#endif
#ifdef NETCDF
    integer :: varid,status
#endif

!-------------------------------------------------------------------------------

    rf1:  IF( restart_filetype.eq.1 .or. restart_filetype.eq.2 )THEN

    msk = 0

#ifdef MPI
    !----------------- MPI section -----------------!
    recv1 = .true.
    recv2 = .true.
    tag = 1
#endif

    kloop:  DO k=numk1,numk2

#ifndef MPI
      !-------------------- non-MPI section --------------------!
!$omp parallel do default(shared)   &
!$omp private(i,j)
      do j=1,numj
      do i=1,numi
        dat2(i,j)=var(i,j,k)
      enddo
      enddo
#ifdef NETCDF
      if( restart_format.eq.2 )then
        status = nf90_inq_varid(ncid,aname,varid)
        if(status.ne.nf90_noerr)then
          print *,'  Error1 in writer, aname = ',aname
          print *,nf90_strerror(status)
          call stopcm1
        endif
      endif
#endif
#else
      iamnodemaster:  IF(myid.ne.nodemaster)THEN
        ! ordinary processor ... send data to nodemaster:
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          dat1(i,j)=var(i,j,k)
        enddo
        enddo
        call MPI_ISEND(dat1(1,1),numi*numj,MPI_REAL,nodemaster,tag,MPI_COMM_WORLD,reqs,ierr)
        call MPI_WAIT(reqs,MPI_STATUS_IGNORE,ierr)
        ! DONE, ordinary processors
      ELSE
        ! begin nodemaster section:
        if( recv1 )then
          ! start receives from all other processors on a node:
          do proc=myid+1,myid+(ppnode-1)
            call MPI_IRECV(dat3(1,1,proc),numi*numj,MPI_REAL,proc,tag,MPI_COMM_WORLD,reqt(proc-myid),ierr)
          enddo
        endif
        iammsk:  IF(myid.ne.msk)THEN
          ! nodemaster, not proc msk:
!$omp parallel do default(shared)  &
!$omp private(i,j)
          do j=1,numj
          do i=1,numi
            dat3(i,j,myid)=var(i,j,k)
          enddo
          enddo
          ! wait for receives to finish:
          call mpi_waitall(ppnode-1,reqt(1:ppnode-1),MPI_STATUS_IGNORE,ierr)
          ! send data to processor msk:
          call MPI_ISEND(dat3(1,1,myid),numi*numj*ppnode,MPI_REAL,msk,tag+1,MPI_COMM_WORLD,reqs,ierr)
          ! wait for send to finish:
          call MPI_WAIT(reqs,MPI_STATUS_IGNORE,ierr)
          recv1 = .true.
          ! DONE, nodemaster (not proc msk)
        ELSE
          ! proc msk:
          if( recv2 )then
            ! start receives from other nodemasters:
            do n = 1,(nodes-1)
              if( n.le.mynode )then
                proc = (n-1)*ppnode
              else
                proc = n*ppnode
              endif
              call MPI_IRECV(dat3(1,1,proc),numi*numj*ppnode,MPI_REAL,proc,tag+1,MPI_COMM_WORLD,reqt(ppnode-1+n),ierr)
            enddo
          endif
#ifdef NETCDF
          if( restart_format.eq.2 .and. k.eq.numk1 )then
            status = nf90_inq_varid(ncid,aname,varid)
            if(status.ne.nf90_noerr)then
              print *,'  Error1 in writer, aname = ',aname
              print *,nf90_strerror(status)
              call stopcm1
            endif
          endif
#endif
          ! my data:
          if( myid.eq.0 )then
!$omp parallel do default(shared)  &
!$omp private(i,j)
            do j=1,numj
            do i=1,numi
              dat2(i,j)=var(i,j,k)
            enddo
            enddo
          else
            fooj = myid / nodex + 1
            fooi = myid - (fooj-1)*nodex  + 1
            fooi = (fooi-1)*ni
            fooj = (fooj-1)*nj
!$omp parallel do default(shared)  &
!$omp private(i,j)
            do j=1,numj
            do i=1,numi
              dat2(fooi+i,fooj+j)=var(i,j,k)
            enddo
            enddo
          endif
          ! wait for data to arrive:
          ntot = ppnode-1 + nodes-1
          do nn=1,ntot
            call mpi_waitany(ntot,reqt(1:ntot),index,MPI_STATUS_IGNORE,ierr)
            if( index.le.(ppnode-1) )then
              ! data from ordinary procs on node:
              proc = myid+index
              fooj = proc / nodex + 1
              fooi = proc - (fooj-1)*nodex  + 1
              fooi = (fooi-1)*ni
              fooj = (fooj-1)*nj
!$omp parallel do default(shared)  &
!$omp private(i,j)
              do j=1,numj
              do i=1,numi
                dat2(fooi+i,fooj+j) = dat3(i,j,proc)
              enddo
              enddo
            else
              ! data from other nodemasters:
              index2 = index-(ppnode-1)
              if( index2.le.mynode )then
                index2 = index2-1
              endif
              n1 = index2*ppnode
              n2 = (index2+1)*ppnode-1
              do nnn = n1,n2
                proc = nnn
                fooj = proc / nodex + 1
                fooi = proc - (fooj-1)*nodex  + 1
                fooi = (fooi-1)*ni
                fooj = (fooj-1)*nj
!$omp parallel do default(shared)  &
!$omp private(i,j)
                do j=1,numj
                do i=1,numi
                  dat2(fooi+i,fooj+j) = dat3(i,j,proc)
                enddo
                enddo
              enddo
            endif
          enddo
          ! DONE, proc msk
          ! processor is ready to write.
          IF( k.lt.numk2 )THEN
            ! start receives for next level:
            do proc=myid+1,myid+(ppnode-1)
              call MPI_IRECV(dat3(1,1,proc),numi*numj,MPI_REAL,proc,tag+2,MPI_COMM_WORLD,reqt(proc-myid),ierr)
            enddo
            recv1 = .false.
!!!#ifdef NETCDF
!!!            IF( restart_format.eq.2 )THEN
              do n = 1,(nodes-1)
                proc = n*ppnode
                call MPI_IRECV(dat3(1,1,proc),numi*numj*ppnode,MPI_REAL,proc,tag+3,MPI_COMM_WORLD,reqt(ppnode-1+n),ierr)
              enddo
              recv2 = .false.
!!!            ENDIF
!!!#endif
          ENDIF
        ENDIF  iammsk
      ENDIF  iamnodemaster
#endif

        ! WRITE DATA:
        IF( myid.eq.msk )THEN
          !---   write data   ------------------!
          IF( restart_format.eq.1 )THEN
            write(nfile,rec=orec) ((dat2(i,j),i=1,nxr),j=1,nyr)
#ifdef NETCDF
          ELSEIF( restart_format.eq.2 )THEN
            ! ----- netcdf format -----
            if(numk1.eq.numk2)then
              status = nf90_put_var(ncid,varid,dat2,(/1,1,time_index/),(/nxr,nyr,1/))
            else
              status = nf90_put_var(ncid,varid,dat2,(/1,1,k,time_index/),(/nxr,nyr,1,1/))
            endif
            if(status.ne.nf90_noerr)then
              print *,'  Error2 in writer, aname = ',aname
              print *,nf90_strerror(status)
              call stopcm1
            endif
#endif
          ENDIF
        ENDIF

      !---  prepare for next level   -------!
      IF( restart_format.eq.1 )THEN
        orec = orec+1
!!!#ifdef MPI
!!!        msk = msk+ppnode
!!!        if( msk.ge.numprocs ) msk = msk-numprocs
!!!#endif
      ENDIF
#ifdef MPI
      tag = tag+2
#endif
      !---  done with this level   ---------!
    ENDDO  kloop

    ENDIF  rf1

!-------------------------------------------------------------------------------

#ifdef MPI
    rf2:  IF( restart_filetype.eq.3 )THEN

      call    writer2(numi,numj,numk1,numk2,nxr,nyr,var,aname,           &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orec,nfile,   &
                      ncid,time_index,restart_format,restart_filetype,   &
                      dat1(1,1),dat2(1,1),dat3(1,1,0),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)

    ENDIF  rf2
#endif

!-------------------------------------------------------------------------------
!ccccc  done  cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!-------------------------------------------------------------------------------

!!!#ifdef MPI
!!!    ! helps with memory:
!!!    call MPI_BARRIER (MPI_COMM_WORLD,ierr)
!!!    !----------------- end MPI section -----------------!
!!!#endif

    return
    end subroutine writer


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    subroutine  readr(numi,numj,numk1,numk2,nxr,nyr,var,aname,           &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orec,nfile,   &
                      ncid,time_index,restart_format,restart_filetype,   &
                      dat1,dat2,dat3,reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)
#ifdef MPI
    use mpi
#endif
#ifdef NETCDF
    use netcdf
#endif
    implicit none

    !-------------------------------------------------------------------
    ! This subroutine reads restart files and then passes data 
    ! to other processors if this is a MPI run. 
    !-------------------------------------------------------------------

    integer, intent(in) :: numi,numj,numk1,numk2,nxr,nyr
    integer, intent(in) :: ppnode,d3n,d3t,d2i,d2j,d3i,d3j
    real, intent(inout), dimension(1-ngxy:numi+ngxy,1-ngxy:numj+ngxy,numk1:numk2) :: var
    character(len=8), intent(in) :: aname
    integer, intent(in) :: ni,nj,ngxy,myid,numprocs,nodex,nodey
    integer, intent(inout) :: orec,ncid
    integer, intent(in) :: time_index,restart_format,restart_filetype
    real, intent(inout), dimension(numi,numj) :: dat1
    real, intent(inout), dimension(d2i,d2j) :: dat2
    real, intent(inout), dimension(d3i,d3j,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, intent(in) :: mynode,nodemaster,nodes,nfile

    integer :: i,j,k,msk
#ifdef MPI
    integer :: reqs,index,index2,n,nn,nnn,fooi,fooj,proc,ierr,ntot,n1,n2
    integer :: tag
#endif
#ifdef NETCDF
    integer :: varid,status
#endif

!-------------------------------------------------------------------------------

    rf1:  IF( restart_filetype.eq.1 .or. restart_filetype.eq.2 )THEN

    msk = 0

#ifdef MPI
    !----------------- MPI section -----------------!
    tag = 1
#endif
#ifdef NETCDF
    if( myid.eq.0 )then
      if( restart_format.eq.2 )then
        status = nf90_inq_varid(ncid,aname,varid)
        if(status.ne.nf90_noerr)then
          print *,'  Error1 in  readr, aname = ',aname
          print *,nf90_strerror(status)
          call stopcm1
        endif
      endif
    endif
#endif

    kloop:  DO k=numk1,numk2

#ifdef MPI
      IF(myid.ne.nodemaster)THEN
        ! ordinary processor ... recv data from nodemaster:
        call MPI_IRECV(dat1(1,1),numi*numj,MPI_REAL,nodemaster,tag,MPI_COMM_WORLD,reqs,ierr)
        call MPI_WAIT(reqs,MPI_STATUS_IGNORE,ierr)
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          var(i,j,k)=dat1(i,j)
        enddo
        enddo
        ! DONE, ordinary processors
      ELSE
        ! begin nodemaster section:
        IF(myid.ne.msk)THEN
          ! nodemaster, not proc msk:
          ! get data from msk:
          call MPI_IRECV(dat3(1,1,myid),numi*numj*ppnode,MPI_REAL,msk,tag+1,MPI_COMM_WORLD,reqs,ierr)
          ! wait for data to arrive:
          call MPI_WAIT(reqs,MPI_STATUS_IGNORE,ierr)
          ! start sends to other processors on a node:
          do proc=myid+1,myid+(ppnode-1)
            call MPI_ISEND(dat3(1,1,proc),numi*numj,MPI_REAL,proc,tag,MPI_COMM_WORLD,reqt(proc-myid),ierr)
          enddo
          ! my data:
!$omp parallel do default(shared)  &
!$omp private(i,j)
          do j=1,numj
          do i=1,numi
            var(i,j,k)=dat3(i,j,myid)
          enddo
          enddo
          ! wait for sends to finish:
          call mpi_waitall(ppnode-1,reqt(1:ppnode-1),MPI_STATUS_IGNORE,ierr)
          ! DONE, nodemaster (not proc msk)
        ELSE
          ! proc msk:
          ! read data:
#endif

          IF( restart_format.eq.1 )THEN
            read(nfile,rec=orec) ((dat2(i,j),i=1,nxr),j=1,nyr)
#ifdef NETCDF
          ELSEIF( restart_format.eq.2 )THEN
            ! ----- netcdf format -----
            if(numk1.eq.numk2)then
              status = nf90_get_var(ncid,varid,dat2,(/1,1,time_index/),(/nxr,nyr,1/))
            else
              status = nf90_get_var(ncid,varid,dat2,(/1,1,k,time_index/),(/nxr,nyr,1,1/))
            endif
            if(status.ne.nf90_noerr)then
              print *,'  Error2 in  readr, aname = ',aname
              print *,nf90_strerror(status)
              call stopcm1
            endif
#endif
          ENDIF

#ifndef MPI
!$omp parallel do default(shared)   &
!$omp private(i,j)
          do j=1,numj
          do i=1,numi
            var(i,j,k)=dat2(i,j)
          enddo
          enddo
#else
          ! send data:
          do nn=1,( nodes-1 )
              ! send data to other nodemasters:
              index2 = nn
              if( index2.le.mynode )then
                index2 = index2-1
              endif
              n1 = index2*ppnode
              n2 = (index2+1)*ppnode-1
              do nnn=n1,n2
                proc = nnn
                fooj = proc / nodex + 1
                fooi = proc - (fooj-1)*nodex  + 1
                fooi = (fooi-1)*ni
                fooj = (fooj-1)*nj
!$omp parallel do default(shared)  &
!$omp private(i,j)
                do j=1,numj
                do i=1,numi
                  dat3(i,j,proc) = dat2(fooi+i,fooj+j)
                enddo
                enddo
              enddo
              proc = index2*ppnode
              call MPI_ISEND(dat3(1,1,proc),numi*numj*ppnode,MPI_REAL,proc,tag+1,MPI_COMM_WORLD,reqt(ppnode-1+nn),ierr)
          enddo
          do nn=1,( ppnode-1 )
              ! send data to ordinary procs on this node:
              proc = myid+nn
              fooj = proc / nodex + 1
              fooi = proc - (fooj-1)*nodex  + 1
              fooi = (fooi-1)*ni
              fooj = (fooj-1)*nj
!$omp parallel do default(shared)  &
!$omp private(i,j)
              do j=1,numj
              do i=1,numi
                dat3(i,j,proc) = dat2(fooi+i,fooj+j)
              enddo
              enddo
              call MPI_ISEND(dat3(1,1,proc),numi*numj,MPI_REAL,proc,tag,MPI_COMM_WORLD,reqt(nn),ierr)
          enddo
          ! my data:
          if( myid.eq.0 )then
!$omp parallel do default(shared)  &
!$omp private(i,j)
            do j=1,numj
            do i=1,numi
              var(i,j,k) = dat2(i,j)
            enddo
            enddo
          else
            fooj = myid / nodex + 1
            fooi = myid - (fooj-1)*nodex  + 1
            fooi = (fooi-1)*ni
            fooj = (fooj-1)*nj
!$omp parallel do default(shared)  &
!$omp private(i,j)
            do j=1,numj
            do i=1,numi
              var(i,j,k) = dat2(fooi+i,fooj+j)
            enddo
            enddo
          endif
          ntot = ppnode-1 + nodes-1
          call mpi_waitall(ntot,reqt(1:ntot),MPI_STATUS_IGNORE,ierr)
        ENDIF
      ENDIF
#endif
      !---  prepare for next level   -------!
      IF( restart_format.eq.1 )THEN
        orec = orec+1
!!!#ifdef MPI
!!!        msk = msk+ppnode
!!!        if( msk.ge.numprocs ) msk = msk-numprocs
!!!#endif
      ENDIF
#ifdef MPI
      tag = tag+2
#endif
      !---  done with this level   ---------!
    ENDDO  kloop

    ENDIF  rf1

!-------------------------------------------------------------------------------

#ifdef MPI
    rf2:  IF( restart_filetype.eq.3 )THEN

      call     readr2(numi,numj,numk1,numk2,nxr,nyr,var,aname,           &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orec,nfile,   &
                      ncid,time_index,restart_format,restart_filetype,   &
                      dat1(1,1),dat2(1,1),dat3(1,1,0),reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)

    ENDIF  rf2
#endif

!-------------------------------------------------------------------------------
!ccccc  done  cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!-------------------------------------------------------------------------------

!!!#ifdef MPI
!!!    ! helps with memory:
!!!    call MPI_BARRIER (MPI_COMM_WORLD,ierr)
!!!    !----------------- end MPI section -----------------!
!!!#endif

    return
    end subroutine  readr


#ifdef MPI
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    ! cm1r17-format restart files !
    subroutine writer2(numi,numj,numk1,numk2,nxr,nyr,var,aname,          &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orec,nfile,   &
                      ncid,time_index,restart_format,restart_filetype,   &
                      dat1,dat2,dat3,reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)
    use mpi
    implicit none

    !-------------------------------------------------------------------
    ! This subroutine collects data (from other processors if this is a
    ! MPI run) and does the actual writing of restart files.
    !-------------------------------------------------------------------

    integer, intent(in) :: numi,numj,numk1,numk2,nxr,nyr
    integer, intent(in) :: ppnode,d3n,d3t,d2i,d2j,d3i,d3j
    real, intent(in   ), dimension(1-ngxy:numi+ngxy,1-ngxy:numj+ngxy,numk1:numk2) :: var
    character(len=8), intent(in) :: aname
    integer, intent(in) :: ni,nj,ngxy,myid,numprocs,nodex,nodey
    integer, intent(inout) :: orec,ncid
    integer, intent(in) :: time_index,restart_format,restart_filetype
    real, intent(inout), dimension(numi,numj) :: dat1
    real, intent(inout), dimension(d3i*ppnode,d3j) :: dat2
    real, intent(inout), dimension(d3i,d3j,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, intent(in) :: mynode,nodemaster,nodes,nfile

    integer :: i,j,k,msk
    integer :: reqs,index,index2,n,nn,nnn,fooi,fooj,proc,ierr,ntot,n1,n2,tag
    logical :: recv1,recv2

    DO k=numk1,numk2
      IF(myid.ne.nodemaster)THEN
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          dat1(i,j) = var(i,j,k)
        enddo
        enddo
        call MPI_ISEND(dat1,numi*numj,MPI_REAL,nodemaster,k,MPI_COMM_WORLD,reqs,ierr)
        call MPI_WAIT(reqs,mpi_status_ignore,ierr)
      ELSE
        do proc=myid+1,myid+(ppnode-1)
          call MPI_IRECV(dat3(1,1,proc),numi*numj,MPI_REAL,proc,k,MPI_COMM_WORLD,reqt(proc-myid),ierr)
        enddo
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          dat2(i,j)=var(i,j,k)
        enddo
        enddo
        nn = 1
        do while( nn.le.(ppnode-1) )
          nn = nn + 1
          call mpi_waitany(ppnode-1,reqt(1:ppnode-1),index,MPI_STATUS_IGNORE,ierr)
          fooi = numi*index
!$omp parallel do default(shared)   &
!$omp private(i,j)
          do j=1,numj
          do i=1,numi
            dat2(fooi+i,j)=dat3(i,j,nodemaster+index)
          enddo
          enddo
        enddo
        write(50) dat2
      ENDIF
    ENDDO

    return
    end subroutine writer2


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


    ! cm1r17-format restart files !
    subroutine  readr2(numi,numj,numk1,numk2,nxr,nyr,var,aname,          &
                      ni,nj,ngxy,myid,numprocs,nodex,nodey,orec,nfile,   &
                      ncid,time_index,restart_format,restart_filetype,   &
                      dat1,dat2,dat3,reqt,ppnode,d3n,d3t,mynode,nodemaster,nodes,d2i,d2j,d3i,d3j)
    use mpi
    implicit none

    !-------------------------------------------------------------------
    ! This subroutine reads restart files and then passes data 
    ! to other processors if this is a MPI run. 
    !-------------------------------------------------------------------

    integer, intent(in) :: numi,numj,numk1,numk2,nxr,nyr
    integer, intent(in) :: ppnode,d3n,d3t,d2i,d2j,d3i,d3j
    real, intent(inout), dimension(1-ngxy:numi+ngxy,1-ngxy:numj+ngxy,numk1:numk2) :: var
    character(len=8), intent(in) :: aname
    integer, intent(in) :: ni,nj,ngxy,myid,numprocs,nodex,nodey
    integer, intent(inout) :: orec,ncid
    integer, intent(in) :: time_index,restart_format,restart_filetype
    real, intent(inout), dimension(numi,numj) :: dat1
    real, intent(inout), dimension(d3i*ppnode,d3j) :: dat2
    real, intent(inout), dimension(d3i,d3j,0:d3n-1) :: dat3
    integer, intent(inout), dimension(d3t) :: reqt
    integer, intent(in) :: mynode,nodemaster,nodes,nfile

    integer :: i,j,k,msk
    integer :: reqs,index,index2,n,nn,nnn,fooi,fooj,proc,ierr,ntot,n1,n2
    integer :: tag

    DO k=numk1,numk2
      IF(myid.ne.nodemaster)THEN
        call MPI_IRECV(dat1,numi*numj,MPI_REAL,nodemaster,k,MPI_COMM_WORLD,reqs,ierr)
        call MPI_WAIT(reqs,mpi_status_ignore,ierr)
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          var(i,j,k) = dat1(i,j)
        enddo
        enddo
      ELSE
        read(50) dat2
        do proc=myid+1,myid+(ppnode-1)
          fooi = numi*(proc-myid)
!$omp parallel do default(shared)   &
!$omp private(i,j)
          do j=1,numj
          do i=1,numi
            dat3(i,j,proc)=dat2(fooi+i,j)
          enddo
          enddo
          call MPI_ISEND(dat3(1,1,proc),numi*numj,MPI_REAL,proc,k,MPI_COMM_WORLD,reqt(proc-myid),ierr)
        enddo
!$omp parallel do default(shared)   &
!$omp private(i,j)
        do j=1,numj
        do i=1,numi
          var(i,j,k)=dat2(i,j)
        enddo
        enddo
        call mpi_waitall(ppnode-1,reqt(1:ppnode-1),MPI_STATUS_IGNORE,ierr)
      ENDIF
    ENDDO

    return
    end subroutine  readr2
#endif

  END MODULE restart_module
