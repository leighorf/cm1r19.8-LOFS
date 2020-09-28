! ORF 2018-11-16
! Note, restarts are not working with all options of CM1 that work with the
! default version of CM1! Among other thigns radiation is not saved, and
! sfcmodel and oceanmodel stuff > 1 isn't saved, etc. Maybe someday.
! But, beware! Also, the budget stuff is currently not right when running from
! restarts.
! TODO: Make restarts more better!

#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

#define read_1d_array_restart(var,artype) \
varname='var'; \
arshp1 = shape(var); \
dims(1)=arshp1(1); \
call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr); \
call h5dread_f(dset_id,artype,var,dims,ierr); check_err(ierr)

#define read_2d_array_restart(var,artype) \
varname='var'; \
arshp2 = shape(var); \
dims(1)=arshp2(1);dims(2)=arshp2(2); \
call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr); \
call h5dread_f(dset_id,artype,var,dims,ierr); check_err(ierr)

#define read_3d_array_restart(var,artype) \
varname='var'; \
arshp3 = shape(var); \
dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3); \
call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr); \
call h5dread_f(dset_id,artype,var,dims,ierr); check_err(ierr)

#define read_4d_array_restart(var,artype) \
varname='var'; \
arshp4 = shape(var); \
dims(1)=arshp4(1);dims(2)=arshp4(2);dims(3)=arshp4(3);dims(4)=arshp4(4);\
call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr); \
call h5dread_f(dset_id,artype,var,dims,ierr); check_err(ierr)

subroutine write_val_restart(f_id,dspace_id,dset_id,dims,intval,floatval,doubleval)
    implicit none
    integer, intent(in), optional :: intval
    real, intent(in), optional :: floatval
    double precision, intent(in), optional :: doubleval
    integer(HID_T) ::  f_id,dspace_id,dset_id
    integer(HSIZE_T), intent(in),  DIMENSION(4) :: dims
    logical is_integer,is_float,is_double

    is_integer = present(intval)
    is_float = present(floatval)
    is_double = present(doubleval)

    call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
    if (is_integer) then
        call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
        call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, intval, dims, ierr); check_err(ierr) ! dims ignored for scalar
    else if (is_float) then
        call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr); check_err(ierr)
        call h5dwrite_f(dset_id, H5T_NATIVE_REAL, floatval, dims, ierr); check_err(ierr)
    else if (is_double) then
        call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
        call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, doubleval, dims, ierr); check_err(ierr)
    endif
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    call h5sclose_f(dspace_id,ierr); check_err(ierr)
    return
end subroutine write_val_restart

subroutine read_val_restart(f_id,dset_id,dims,intval,floatval,doubleval)
    implicit none
    integer, intent(inout), optional :: intval
    real, intent(inout), optional :: floatval
    double precision, intent(inout), optional :: doubleval
    integer(HID_T) ::  f_id,dspace_id,dset_id
    integer(HSIZE_T), intent(inout),  DIMENSION(4) :: dims
    logical is_integer,is_float,is_double

    is_integer = present(intval)
    is_float = present(floatval)
    is_double = present(doubleval)

    call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
    if (is_integer) then
        call h5dread_f(dset_id, H5T_NATIVE_INTEGER, intval, dims, ierr); check_err(ierr) ! dims ignored for scalar
    else if (is_float) then
        call h5dread_f(dset_id, H5T_NATIVE_REAL, floatval, dims, ierr); check_err(ierr)
    else if (is_double) then
        call h5dread_f(dset_id, H5T_NATIVE_DOUBLE, doubleval, dims, ierr); check_err(ierr)
    endif
    call h5dclose_f(dset_id,ierr); check_err(ierr)
    return
end subroutine read_val_restart

    subroutine write_restart_hdf5_r19(wr3dindex,nstep,nrec,prec,nwrite,nrst, &
                         dt,dtlast,mtime,ndt,adt,acfl,dbldt,                 &
                         stattim,taptim,rsttim,radtim,prcltim,               &
                         qbudget,asq,bsq,                                    &
                         rain,sws,svs,sps,srs,sgs,sus,shs,                   &
                         tsk,znt,ust,cd,u1,v1,thflux,qvflux,                 &
                         radbcw,radbce,radbcs,radbcn,                        &
                         rho,prs,ua,va,wa,ppi,tha,qa,tkea,                   &
                         psfc,u10,v10,xland,                                 &
                         qpten,qtten,qvten,qcten,pta,pdata,                  &
                         arecs,arecw,icenter,jcenter,mass1,nwritea,nwritet,  &
                         srec,trecs,trecw,urec,vrec,wrec,xcenter,ycenter,    &
                         phi1,phi2,ch,cq,ppx,s1,s10)
                         
      implicit none


!ORF: New since r16, at least for me
      integer, intent(in) :: arecs,arecw,icenter,jcenter,nwritea,nwritet
      integer, intent(in) :: srec,trecs,trecw,urec,vrec,wrec
      real, intent(in) :: xcenter,ycenter
      double precision, intent (in) :: mass1
      real, intent(in),    dimension(ibph:ieph,jbph:jeph,kbph:keph) :: phi1,phi2
      real, intent(in), dimension(ib:ie,jb:je) :: ch,cq
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: ppx
      real, intent(in), dimension(ib:ie,jb:je) :: s1
      real, intent(in), dimension(ibl:iel,jbl:jel) :: s10

!Old stuff follows
      integer, intent(in) :: wr3dindex,nstep,nrec,prec,nwrite,nrst
      real, intent(in) :: dt,dtlast
      integer, intent(in) :: ndt
      double precision, intent(in) :: adt,acfl,dbldt
      double precision, intent(in) :: prcltim
      double precision, intent(in) :: mtime,stattim,taptim,rsttim,radtim
      double precision, intent(inout), dimension(nbudget) :: qbudget
      double precision, intent(inout), dimension(numq) :: asq,bsq
      real, intent(in), dimension(ib:ie,jb:je,nrain) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, intent(in), dimension(ib:ie,jb:je) :: tsk,znt,ust,cd,u1,v1,xland,psfc,thflux,qvflux
      real, intent(in), dimension(jb:je,kb:ke) :: radbcw,radbce
      real, intent(in), dimension(ib:ie,kb:ke) :: radbcs,radbcn
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rho,prs
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: ppi,tha
      real, intent(in), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa
      real, intent(in), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea
      real, intent(in), dimension(ibl:iel,jbl:jel) :: u10,v10
      real, intent(in), dimension(ibm:iem,jbm:jem,kbm:kem) :: qpten,qtten,qvten,qcten
      real, intent(in), dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta
      real, intent(in), dimension(npvals,nparcels) :: pdata

      character*80 fname
      character*8 :: text1
      character*6 :: aname

      integer :: i,j,k,n,np,nvar,reqs,orecs,orecu,orecv,orecw,ndum
      integer :: ncid,time_index
      real, dimension(:), allocatable :: dumx,dumy
      integer :: proc,index,count,req1,req2,req3,reqp
      double precision, dimension(nbudget) :: cfoo
      double precision, dimension(numq) :: afoo,bfoo

!some orfmod stuff
      integer(HID_T) f_id,dspace_id,dset_id,plist_id,fcpl_id
      integer(HSIZE_T), DIMENSION(4) :: dims
      integer, dimension(1):: arshp1
      integer, dimension(2):: arshp2
      integer, dimension(3):: arshp3
      integer, dimension(4):: arshp4
      integer :: itime

!ORF NEWHIST use iotime, which is double precision
      itime = int(iotime+1.0d-5)

      !ORF TEST
      if(dowr)write(outfile,"('Starting restart cycle...')")
      call FFLUSH(6)

! Going to do integer math on restarts, we never need to save a restart on some
! weird fraction of a second.

!     call h5_file_op(op_mkrestartfilename,iotime)
      call h5_file_op_int(op_mkrestartfilename,itime)

      call h5pcreate_f(H5P_FILE_CREATE_F,fcpl_id,ierr);check_err(ierr)
      call h5Pset_userblock_f(fcpl_id,userblock_size,ierr);check_err(ierr)
!     print *, "FILENAME :  ",filename
      call h5fcreate_f(filename,H5F_ACC_TRUNC_F,f_id,ierr,creation_prp=fcpl_id); check_err(ierr)

      varname='wr3dindex';      call write_val_restart(f_id,dspace_id,dset_id,dims,intval=wr3dindex)
      varname='nstep';          call write_val_restart(f_id,dspace_id,dset_id,dims,intval=nstep)
      varname='nrec';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=nrec)
      varname='srec';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=srec)
      varname='urec';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=urec)
      varname='vrec';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=vrec)
      varname='wrec';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=wrec)
      varname='prec';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=prec)
      varname='trecs';          call write_val_restart(f_id,dspace_id,dset_id,dims,intval=trecs)
      varname='trecw';          call write_val_restart(f_id,dspace_id,dset_id,dims,intval=trecw)
      varname='arecs';          call write_val_restart(f_id,dspace_id,dset_id,dims,intval=arecs)
      varname='arecw';          call write_val_restart(f_id,dspace_id,dset_id,dims,intval=arecw)
      varname='nwrite';         call write_val_restart(f_id,dspace_id,dset_id,dims,intval=nwrite)
      varname='nwritet';        call write_val_restart(f_id,dspace_id,dset_id,dims,intval=nwritet)
      varname='nwritea';        call write_val_restart(f_id,dspace_id,dset_id,dims,intval=nwritea)
      varname='nrst';           call write_val_restart(f_id,dspace_id,dset_id,dims,intval=nrst)
      varname='ndt';            call write_val_restart(f_id,dspace_id,dset_id,dims,intval=ndt)
      varname='icenter';        call write_val_restart(f_id,dspace_id,dset_id,dims,intval=icenter)
      varname='jcenter';        call write_val_restart(f_id,dspace_id,dset_id,dims,intval=jcenter)
      varname='output_format';  call write_val_restart(f_id,dspace_id,dset_id,dims,intval=output_format)
      varname='dt';             call write_val_restart(f_id,dspace_id,dset_id,dims,floatval=dt)
      varname='dtlast';         call write_val_restart(f_id,dspace_id,dset_id,dims,floatval=dtlast)
      varname='xcenter';        call write_val_restart(f_id,dspace_id,dset_id,dims,floatval=xcenter)
      varname='ycenter';        call write_val_restart(f_id,dspace_id,dset_id,dims,floatval=ycenter)
      varname='cflmax';         call write_val_restart(f_id,dspace_id,dset_id,dims,floatval=cflmax)
      varname='mtime';          call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=mtime)
      varname='stattim';        call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=stattim)
      varname='taptim';         call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=taptim)
      varname='rsttim';         call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=rsttim)
      varname='radtim';         call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=radtim)
      varname='prcltim';        call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=prcltim)
      varname='adt';            call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=adt)
      varname='acfl';           call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=acfl)
      varname='dbldt';          call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=dbldt)
      varname='mass1';          call write_val_restart(f_id,dspace_id,dset_id,dims,doubleval=mass1)

! ORF 2016-10-20

! Much of the complexity in the r18+ restart code is due to the fact
! that George now allows for several different restart output types,
! whereas I offer only one (the simplest, one file per MPI rank and
! just dump the arrays with the ghost zones). Perhaps at some time in
! the future I can create new options (one file per save, one file per
! node, etc.) 

      cfoo = 0.0
      call MPI_REDUCE(qbudget(1),cfoo(1),nbudget,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
                      MPI_COMM_CM1,ierr)
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
                        MPI_COMM_CM1,ierr)
        if( myid.eq.0 )then
          do n=1,numq
            asq(n)=afoo(n)
          enddo
        else
          asq = 0.0
        endif
        bfoo = 0.0
        call MPI_REDUCE(bsq(1),bfoo(1),numq,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
                        MPI_COMM_CM1,ierr)
        if( myid.eq.0 )then
          do n=1,numq
            bsq(n)=bfoo(n)
          enddo
        else
          bsq = 0.0
        endif
      endif

      varname='qbudget'; arshp1 = shape(qbudget); call wr1dsimpled (f_id,qbudget,arshp1(1))
      varname='asq';         arshp1 = shape(asq); call wr1dsimpled (f_id,asq,arshp1(1))
      varname='bsq';         arshp1 = shape(bsq); call wr1dsimpled (f_id,bsq,arshp1(1))

! "Standard 2D"
      varname='rain';        arshp3 = shape(rain); call wr3dsimpler (f_id,rain,arshp3(1),arshp3(2),arshp3(3))
      varname='sws';         arshp3 = shape(sws);  call wr3dsimpler (f_id,sws,arshp3(1),arshp3(2),arshp3(3))
      varname='svs';         arshp3 = shape(svs);  call wr3dsimpler (f_id,svs,arshp3(1),arshp3(2),arshp3(3))
      varname='sps';         arshp3 = shape(sps);  call wr3dsimpler (f_id,sps,arshp3(1),arshp3(2),arshp3(3))
      varname='srs';         arshp3 = shape(srs);  call wr3dsimpler (f_id,srs,arshp3(1),arshp3(2),arshp3(3))
      varname='sgs';         arshp3 = shape(sgs);  call wr3dsimpler (f_id,sgs,arshp3(1),arshp3(2),arshp3(3))
      varname='sus';         arshp3 = shape(sus);  call wr3dsimpler (f_id,sus,arshp3(1),arshp3(2),arshp3(3))
      varname='shs';         arshp3 = shape(shs);  call wr3dsimpler (f_id,shs,arshp3(1),arshp3(2),arshp3(3))
      varname='lofs_swaths'; arshp4 = shape(lofs_swaths); call wr4dsimpler (f_id,lofs_swaths,arshp4(1),arshp4(2),arshp4(3),arshp4(4))
      varname='tsk';         arshp2 = shape(tsk);  call wr2dsimpler (f_id,tsk,arshp2(1),arshp2(2))

! "Standard 3D"

      varname='rho'; arshp3 = shape(rho); call wr3dsimpler (f_id,rho,arshp3(1),arshp3(2),arshp3(3))
      varname='prs'; arshp3 = shape(prs); call wr3dsimpler (f_id,prs,arshp3(1),arshp3(2),arshp3(3))
      varname='ua';  arshp3 = shape(ua);  call wr3dsimpler (f_id,ua,arshp3(1),arshp3(2),arshp3(3))
      varname='va';  arshp3 = shape(va);  call wr3dsimpler (f_id,va,arshp3(1),arshp3(2),arshp3(3))
      varname='wa';  arshp3 = shape(wa);  call wr3dsimpler (f_id,wa,arshp3(1),arshp3(2),arshp3(3))
      varname='ppi'; arshp3 = shape(ppi); call wr3dsimpler (f_id,ppi,arshp3(1),arshp3(2),arshp3(3))
      varname='tha'; arshp3 = shape(tha); call wr3dsimpler (f_id,tha,arshp3(1),arshp3(2),arshp3(3))
      varname='ppx'; arshp3 = shape(ppx); call wr3dsimpler (f_id,ppx,arshp3(1),arshp3(2),arshp3(3))

      if (psolver.eq.6)then
          varname='phi1'; arshp3 = shape(phi1); call wr3dsimpler (f_id,phi1,arshp3(1),arshp3(2),arshp3(3))
          varname='phi2'; arshp3 = shape(phi2); call wr3dsimpler (f_id,phi2,arshp3(1),arshp3(2),arshp3(3))
      endif


! Note, George writes a 3d array per microphysics variable. We stick to 4d array dump.

      if(imoist.eq.1) then
            varname='qa'; arshp4 = shape(qa); call wr4dsimpler (f_id,qa,arshp4(1),arshp4(2),arshp4(3),arshp4(4))
      endif

      if(imoist.eq.1.and.eqtset.eq.2)then
            varname='qpten'; arshp3 = shape(qpten); call wr3dsimpler (f_id,qpten,arshp3(1),arshp3(2),arshp3(3))
            varname='qtten'; arshp3 = shape(qtten); call wr3dsimpler (f_id,qtten,arshp3(1),arshp3(2),arshp3(3))
            varname='qvten'; arshp3 = shape(qvten); call wr3dsimpler (f_id,qvten,arshp3(1),arshp3(2),arshp3(3))
            varname='qcten'; arshp3 = shape(qcten); call wr3dsimpler (f_id,qcten,arshp3(1),arshp3(2),arshp3(3))
      endif

      if(sgsmodel.eq.1) then
            varname='tkea'; arshp3 = shape(tkea); call wr3dsimpler (f_id,tkea,arshp3(1),arshp3(2),arshp3(3))
      endif

! Not saving radiation. Maybe someone else can do this if they need it...?

! For "free slip" we can set sfcmodel to 0
! For "partial slip" we must set sfcmodel to 1

      if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
          if(sfcmodel.ge.1)then
              varname='ust'; arshp2 = shape(ust); call wr2dsimpler (f_id,ust,arshp2(1),arshp2(2))
              varname='znt'; arshp2 = shape(znt); call wr2dsimpler (f_id,znt,arshp2(1),arshp2(2))
              varname='cd'; arshp2 = shape(cd); call wr2dsimpler (f_id,cd,arshp2(1),arshp2(2))
              varname='ch'; arshp2 = shape(ch); call wr2dsimpler (f_id,ch,arshp2(1),arshp2(2))
              varname='cq'; arshp2 = shape(cq); call wr2dsimpler (f_id,cq,arshp2(1),arshp2(2))
              varname='u1'; arshp2 = shape(u1); call wr2dsimpler (f_id,u1,arshp2(1),arshp2(2))
              varname='v1'; arshp2 = shape(v1); call wr2dsimpler (f_id,v1,arshp2(1),arshp2(2))
              varname='s1'; arshp2 = shape(s1); call wr2dsimpler (f_id,s1,arshp2(1),arshp2(2))
              varname='u10'; arshp2 = shape(u10); call wr2dsimpler (f_id,u10,arshp2(1),arshp2(2))
              varname='v10'; arshp2 = shape(v10); call wr2dsimpler (f_id,v10,arshp2(1),arshp2(2))
              varname='s10'; arshp2 = shape(s10); call wr2dsimpler (f_id,s10,arshp2(1),arshp2(2))
              varname='xland'; arshp2 = shape(xland); call wr2dsimpler (f_id,xland,arshp2(1),arshp2(2))
              varname='thflux'; arshp2 = shape(thflux); call wr2dsimpler (f_id,thflux,arshp2(1),arshp2(2))
              varname='qvflux'; arshp2 = shape(qvflux); call wr2dsimpler (f_id,qvflux,arshp2(1),arshp2(2))
              varname='psfc'; arshp2 = shape(psfc); call wr2dsimpler (f_id,psfc,arshp2(1),arshp2(2))
! Not handling sfcmodel.eq.2.or.sfcmodel.eq.3.
            endif
      endif

!Not saving oceanmodel.eq.2

! George writes these as single 3D arrays, just save the lot in one fell swoop.
      if(iptra.eq.1) then
            varname='pta'; arshp4 = shape(pta); call wr4dsimpler (f_id,pta,arshp4(1),arshp4(2),arshp4(3),arshp4(4))
      endif

! NOTE SEE GEORGE CODE ONLY WRITES POSITION DATA
! He also writes these differently than he used to. When we start doing parcels we'll have to test this.
! ORF 3/19: Since we are doing trajectories offline, let's worry about this later
! Kelton 9/28: I'm tired of having to run these parcels from t == 0 :|
     if(iprcl.eq.1)then
           varname='pdata'; arshp2 = shape(pdata); call wr2dsimpler (f_id,pdata,arshp2(1),arshp2(2))
     endif

! No longer saved in a straightforward manner in default code due to
! different restart options, we save stuff the old simple way.

      if(irbc.eq.4.and.ibw.eq.1) then
            varname='radbcw'; arshp2 = shape(radbcw); call wr2dsimpler (f_id,radbcw,arshp2(1),arshp2(2))
      endif

      if(irbc.eq.4.and.ibe.eq.1)then
            varname='radbce'; arshp2 = shape(radbce); call wr2dsimpler (f_id,radbce,arshp2(1),arshp2(2))
      endif

      if(irbc.eq.4.and.ibs.eq.1)then
            varname='radbcs'; arshp2 = shape(radbcs); call wr2dsimpler (f_id,radbcs,arshp2(1),arshp2(2))
      endif

      if(irbc.eq.4.and.ibn.eq.1)then
            varname='radbcn'; arshp2 = shape(radbcn); call wr2dsimpler (f_id,radbcn,arshp2(1),arshp2(2))
      endif

      ! SKIP OPTIONAL VARIABLES
      ! SKIP restart_file_diags

      call h5fclose_f(f_id,ierr); check_err(ierr)
      if(dowr)write(outfile,"('Closed restart file on root node.')")
      call FFLUSH(6)
      call mpi_barrier(MPI_COMM_CM1,ierr);check_err(ierr)
      if(dowr)write(outfile,"('Closed restart files on all nodes.')")
      call FFLUSH(6)

! ORF 2018-11-16
! Write a small text file with the last restart time. This can be used to
! recover from a hardware failure during a long integration. PBS script must be
! written to loop until job is finished. So the script must restart CM1 from
! restart files that were just written. This only works when you reserve more
! nodes than required to run the job, because when a node fails it's no longer
! in the pool. This approach is necessary once you start running jobs that span
! 1/3 or so of the machine and take dozens of hours. Since PBS scripts are
! typically stashed in the history/restart files look there for examples.

      if(myid.eq.0) then
            open(unit=1000,file="last_restart",status='unknown')
            write(1000,"(i6)") itime
            close(unit=1000)
      endif

      return
      end subroutine write_restart_hdf5_r19


    subroutine read_restart_hdf5_r19(wr3dindex,nstep,nrec,prec,nwrite,nrst, &
                         dt,dtlast,mtime,ndt,adt,acfl,dbldt,                  &
                         stattim,taptim,rsttim,radtim,prcltim,                &
                         qbudget,asq,bsq,                               &
                         rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                         tsk,znt,ust,cd,u1,v1,thflux,qvflux,         &
                         radbcw,radbce,radbcs,radbcn,                         &
                         rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                         psfc,u10,v10,xland,      &
                         qpten,qtten,qvten,qcten,pta,pdata, &
                         arecs,arecw,icenter,jcenter,mass1,nwritea,nwritet,  &
                         srec,trecs,trecw,urec,vrec,wrec,xcenter,ycenter,    &
                         phi1,phi2,ch,cq,ppx,s1,s10)

      implicit none

      integer, intent(inout) :: wr3dindex,nstep,nrec,prec,nwrite,nrst
      real, intent(inout) :: dt,dtlast
      integer, intent(inout) :: ndt
      double precision, intent(inout) :: adt,acfl,dbldt
      double precision, intent(inout) :: mtime,stattim,taptim,rsttim,radtim
      double precision, intent(inout) :: prcltim
      double precision, intent(inout), dimension(nbudget) :: qbudget
      double precision, intent(inout), dimension(numq) :: asq,bsq
      real, intent(inout), dimension(ib:ie,jb:je,nrain) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, intent(inout), dimension(ib:ie,jb:je) :: tsk,znt,ust,cd,u1,v1,xland,psfc,thflux,qvflux
      real, intent(inout), dimension(jb:je,kb:ke) :: radbcw,radbce
      real, intent(inout), dimension(ib:ie,kb:ke) :: radbcs,radbcn
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: rho,prs
      real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: ua
      real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: va
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: wa
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: ppi,tha
      real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa
      real, intent(inout), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: u10,v10
      real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem) :: qpten,qtten,qvten,qcten
      real, intent(inout), dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta
      real, intent(inout), dimension(npvals,nparcels) :: pdata
!New
      integer, intent(inout) :: arecs,arecw,icenter,jcenter,nwritea,nwritet
      integer, intent(inout) :: srec,trecs,trecw,urec,vrec,wrec
      real, intent(inout) :: xcenter,ycenter
      double precision, intent (inout) :: mass1
      real, intent(inout),    dimension(ibph:ieph,jbph:jeph,kbph:keph) :: phi1,phi2
      real, intent(inout), dimension(ib:ie,jb:je) :: ch,cq
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: ppx
      real, intent(inout), dimension(ib:ie,jb:je) :: s1
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: s10

!ORF stuff begins here

      integer(HID_T) f_id,dspace_id,dset_id
      integer(HSIZE_T), DIMENSION(4) :: dims
      integer :: rank

      integer, dimension(1):: arshp1
      integer, dimension(2):: arshp2
      integer, dimension(3):: arshp3
      integer, dimension(4):: arshp4

! rstnum is the time in (double precision) seconds

      call h5_file_op_int(op_mkrestartfilename,rstnum)
      call h5fopen_f(filename,H5F_ACC_RDONLY_F,f_id,ierr); check_err(ierr)
      if(ierr.ge.0.and.myid.eq.0)print*, "read_restart_hdf: opened ",trim(filename)

      dims(1)=1

      varname='wr3dindex';      call read_val_restart(f_id,dset_id,dims,intval=wr3dindex)
      varname='nstep';          call read_val_restart(f_id,dset_id,dims,intval=nstep)
      varname='nrec';           call read_val_restart(f_id,dset_id,dims,intval=nrec)
      varname='srec';           call read_val_restart(f_id,dset_id,dims,intval=srec)
      varname='urec';           call read_val_restart(f_id,dset_id,dims,intval=urec)
      varname='vrec';           call read_val_restart(f_id,dset_id,dims,intval=vrec)
      varname='wrec';           call read_val_restart(f_id,dset_id,dims,intval=wrec)
      varname='prec';           call read_val_restart(f_id,dset_id,dims,intval=prec)
      varname='trecs';          call read_val_restart(f_id,dset_id,dims,intval=trecs)
      varname='trecw';          call read_val_restart(f_id,dset_id,dims,intval=trecw)
      varname='arecs';          call read_val_restart(f_id,dset_id,dims,intval=arecs)
      varname='arecw';          call read_val_restart(f_id,dset_id,dims,intval=arecw)
      varname='nwrite';         call read_val_restart(f_id,dset_id,dims,intval=nwrite)
      varname='nwritet';        call read_val_restart(f_id,dset_id,dims,intval=nwritet)
      varname='nwritea';        call read_val_restart(f_id,dset_id,dims,intval=nwritea)
      varname='nrst';           call read_val_restart(f_id,dset_id,dims,intval=nrst)
      varname='ndt';            call read_val_restart(f_id,dset_id,dims,intval=ndt)
      varname='icenter';        call read_val_restart(f_id,dset_id,dims,intval=icenter)
      varname='jcenter';        call read_val_restart(f_id,dset_id,dims,intval=jcenter)
      varname='output_format';  call read_val_restart(f_id,dset_id,dims,intval=output_format)
      varname='dt';             call read_val_restart(f_id,dset_id,dims,floatval=dt)
      varname='dtlast';         call read_val_restart(f_id,dset_id,dims,floatval=dtlast)
      varname='xcenter';        call read_val_restart(f_id,dset_id,dims,floatval=xcenter)
      varname='ycenter';        call read_val_restart(f_id,dset_id,dims,floatval=ycenter)
      varname='cflmax';         call read_val_restart(f_id,dset_id,dims,floatval=cflmax)
      varname='mtime';          call read_val_restart(f_id,dset_id,dims,doubleval=mtime)
      varname='stattim';        call read_val_restart(f_id,dset_id,dims,doubleval=stattim)
      varname='taptim';         call read_val_restart(f_id,dset_id,dims,doubleval=taptim)
      varname='rsttim';         call read_val_restart(f_id,dset_id,dims,doubleval=rsttim)
      varname='radtim';         call read_val_restart(f_id,dset_id,dims,doubleval=radtim)
      varname='prcltim';        call read_val_restart(f_id,dset_id,dims,doubleval=prcltim)
      varname='adt';            call read_val_restart(f_id,dset_id,dims,doubleval=adt)
      varname='acfl';           call read_val_restart(f_id,dset_id,dims,doubleval=acfl)
      varname='dbldt';          call read_val_restart(f_id,dset_id,dims,doubleval=dbldt)
      varname='mass1';          call read_val_restart(f_id,dset_id,dims,doubleval=mass1)


! ORF These were reduced to rank 0.

if (myid.eq.0) then
      read_1d_array_restart(qbudget,H5T_NATIVE_DOUBLE)
      read_1d_array_restart(asq,H5T_NATIVE_DOUBLE)
      read_1d_array_restart(bsq,H5T_NATIVE_DOUBLE)
else
      qbudget = 0.0
      asq = 0.0
      bsq = 0.0
endif

! ORF 2018-11-16

! The budget stuff is wrong when run from restarts! I never use it but at some
! point needs to fixed ... so beware those who use the budget data in the stats,
! etc.

!See macros above, this seems to be the cleanest way to do this.

      read_3d_array_restart(rain,H5T_NATIVE_REAL)
      read_3d_array_restart(sws,H5T_NATIVE_REAL)
      read_3d_array_restart(svs,H5T_NATIVE_REAL)
      read_3d_array_restart(sps,H5T_NATIVE_REAL)
      read_3d_array_restart(srs,H5T_NATIVE_REAL)
      read_3d_array_restart(sgs,H5T_NATIVE_REAL)
      read_3d_array_restart(sus,H5T_NATIVE_REAL)
      read_3d_array_restart(shs,H5T_NATIVE_REAL)
      read_4d_array_restart(lofs_swaths,H5T_NATIVE_REAL)
      read_2d_array_restart(tsk,H5T_NATIVE_REAL)
      read_3d_array_restart(rho,H5T_NATIVE_REAL)
      read_3d_array_restart(prs,H5T_NATIVE_REAL)
      read_3d_array_restart(ua,H5T_NATIVE_REAL)
      read_3d_array_restart(va,H5T_NATIVE_REAL)
      read_3d_array_restart(wa,H5T_NATIVE_REAL)
      read_3d_array_restart(ppi,H5T_NATIVE_REAL)
      read_3d_array_restart(tha,H5T_NATIVE_REAL)
      read_3d_array_restart(ppx,H5T_NATIVE_REAL)

!Adjusting the box speed from restarts is now an option in the namelist file
if (adjust_box_speed_from_restart) then
    write(outfile,"('****We are adjusting the box speed from a restart file****')")
    write(outfile,"('****u_adjust = ',f12.8)") u_adjust
    write(outfile,"('****v_adjust = ',f12.8)") v_adjust
    ua = ua + u_adjust
    va = va + v_adjust
endif

      if (imoist.eq.1) then
      read_4d_array_restart(qa,H5T_NATIVE_REAL)
      endif

      if(imoist.eq.1.and.eqtset.eq.2)then
            read_3d_array_restart(qpten,H5T_NATIVE_REAL)
            read_3d_array_restart(qtten,H5T_NATIVE_REAL)
            read_3d_array_restart(qvten,H5T_NATIVE_REAL)
            read_3d_array_restart(qcten,H5T_NATIVE_REAL)
      endif

      if (sgsmodel.eq.1) then
            read_3d_array_restart(tkea,H5T_NATIVE_REAL)
      endif

! Not saving radiation

! Only saving sfcmodel.eq.1, really.

      if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
          if(sfcmodel.ge.1)then
                read_2d_array_restart(ust,H5T_NATIVE_REAL)
                read_2d_array_restart(znt,H5T_NATIVE_REAL)
                read_2d_array_restart(cd,H5T_NATIVE_REAL)
                read_2d_array_restart(ch,H5T_NATIVE_REAL)
                read_2d_array_restart(cq,H5T_NATIVE_REAL)
                read_2d_array_restart(u1,H5T_NATIVE_REAL)
                read_2d_array_restart(v1,H5T_NATIVE_REAL)
                read_2d_array_restart(s1,H5T_NATIVE_REAL)
                read_2d_array_restart(u10,H5T_NATIVE_REAL)
                read_2d_array_restart(v10,H5T_NATIVE_REAL)
                read_2d_array_restart(s10,H5T_NATIVE_REAL)
                read_2d_array_restart(xland,H5T_NATIVE_REAL)
                read_2d_array_restart(thflux,H5T_NATIVE_REAL)
                read_2d_array_restart(qvflux,H5T_NATIVE_REAL)
                read_2d_array_restart(psfc,H5T_NATIVE_REAL)
        endif
! ORF not handling (sfcmodel .eq. 2 .or. sfcmodel .eq. 3)
      endif

! NOTE george only writes parts of traj dat (position)

      if (iptra.eq.1) then
            read_4d_array_restart(pta,H5T_NATIVE_REAL)
      endif

      if (iprcl.eq.1) then
            read_2d_array_restart(pdata,H5T_NATIVE_REAL)
      endif

      if (irbc.eq.4.and.ibw.eq.1) then
            read_2d_array_restart(radbcw,H5T_NATIVE_REAL)
      endif

      if (irbc.eq.4.and.ibe.eq.1) then
            read_2d_array_restart(radbce,H5T_NATIVE_REAL)
      endif

      if (irbc.eq.4.and.ibs.eq.1) then
            read_2d_array_restart(radbcs,H5T_NATIVE_REAL)
      endif

      if (irbc.eq.4.and.ibn.eq.1) then
            read_2d_array_restart(radbcn,H5T_NATIVE_REAL)
      endif

      call h5fclose_f (f_id,ierr); check_err(ierr)


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
      if(dowr) write(outfile,*) '   nrec    = ',nrec
      if(dowr) write(outfile,*) '   prec    = ',prec
      if(dowr) write(outfile,*) '   nwrite  = ',nwrite
      if(dowr) write(outfile,*) '   nrst    = ',nrst
      if(dowr) write(outfile,*) '   dtl     = ',dtl
      if(dowr) write(outfile,*) '   dtlast  = ',dtlast
      if(dowr) write(outfile,*)

!---------

      if( adapt_dt.eq.0 ) dt = dtl

      if(dowr) write(outfile,*) '   dt  = ',dt

!---------

#ifdef MPI
      if(timestats.ge.1)then
        ! this is needed for proper accounting of timing:
        call MPI_BARRIER (MPI_COMM_CM1,ierr)
      endif
#endif

      return
end subroutine read_restart_hdf5_r19

