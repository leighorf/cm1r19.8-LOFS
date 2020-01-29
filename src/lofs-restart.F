#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr


    subroutine write_restart_hdf5(wr3dindex,nstep,nrec,prec,nwrite,nrst, &
                         dt,dtlast,mtime,ndt,adt,acfl,dbldt,                  &
                         stattim,taptim,rsttim,radtim,prcltim,                &
                         qbudget,asq,bsq,                               &
                         rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                         tsk,znt,ust,cd,u1,v1,thflux,qvflux,         &
                         radbcw,radbce,radbcs,radbcn,                         &
                         rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                         psfc,u10,v10,xland,      &
                         qpten,qtten,qvten,qcten,pta,pdata)
 
  implicit none
  include 'radcst.incl'


      !----------------------------------------------------------
      ! This subroutine organizes the writing of restart files
      !----------------------------------------------------------

      integer, intent(in) :: wr3dindex,nstep,nrec,prec,nwrite,nrst
      real, intent(in) :: dt,dtlast
      integer, intent(in) :: ndt
      double precision, intent(in) :: adt,acfl,dbldt
      real, intent(in) :: prcltim
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

      if(iprintinfo)write(outfile,"('Starting restart cycle...')")
      call FFLUSH(6)

! Going to do integer math on restarts, we never need to save a restart on some
! weird fraction of a second.

!     call h5_file_op(op_mkrestartfilename,iotime)
      call h5_file_op_int(op_mkrestartfilename,itime)

      !ORF new way to deal with restarts... only write them if they aren't
      !already there. So for going back and doing 1s runs or whatever, we just
      !keep rstfrq the same and if we fail we still update the last_restart
      !file

!FUCKBAGS
!     inquire(file=filename,exist=restart_file_exists)

!rsfile_exists:  if (.not. restart_file_exists) then

      call h5pcreate_f(H5P_FILE_CREATE_F,fcpl_id,ierr);check_err(ierr)
      call h5Pset_userblock_f(fcpl_id,userblock_size,ierr);check_err(ierr) !ORF we will stick namelist.input and other useful things here
!     print *, "FILENAME :  ",filename
      call h5fcreate_f(filename,H5F_ACC_TRUNC_F,f_id,ierr,creation_prp=fcpl_id); check_err(ierr)
! ORF STOPPED HERE it is creating the t=0 restart file OH MY FUCKING SHIT CRAP FUCK

      varname='wr3dindex'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, wr3dindex, dims, ierr); check_err(ierr) ! dims ignored for scalar
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='nstep'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, nstep, dims, ierr); check_err(ierr) ! dims ignored for scalar
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='nrec'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, nrec, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='prec'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, prec, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='nwrite'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, nwrite, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='nrst'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, nrst, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

!     varname='num_soil_layers'
!     call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
!     call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
!     call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, num_soil_layers, dims, ierr); check_err(ierr)
!     call h5dclose_f(dset_id,ierr); check_err(ierr)
!     call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='dt'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_REAL, dt, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='dtlast'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_REAL, dtlast, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='mtime'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, mtime, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='ndt'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_INTEGER,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_INTEGER, ndt, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='adt'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, adt, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='acfl'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, acfl, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='dbldt'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, dbldt, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='stattim'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, stattim, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='taptim'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, taptim, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='tapfrq_save'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_REAL,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_REAL, tapfrq, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='rsttim'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, rsttim, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='radtim'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, radtim, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

      varname='prcltim'
      call h5screate_f(H5S_SCALAR_F,dspace_id,ierr); check_err(ierr)
      call h5dcreate_f(f_id,trim(varname),H5T_NATIVE_DOUBLE,dspace_id,dset_id,ierr); check_err(ierr)
      call h5dwrite_f(dset_id, H5T_NATIVE_DOUBLE, prcltim, dims, ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5sclose_f(dspace_id,ierr); check_err(ierr)

! ORF 2016-10-20

! Much of the complexity in the r18 restart code is due to the fact that
! George now allows for several different restart output types, whereas
! I offer only one (the simplest). Perhaps at some time in the future I
! can create new options (one file per save, one file pernode, etc.)
! The biggest reason I could see this becoming an option is with data assimilation.
! It would be easiest to open one file and apply magic thusly.
! However my middleware code makes this moot EXCEPT I have yet to get
! it to work with restart files (since the saved format is different).
! I also believe George no longer saves ghost data in the history arrays
! Worry about this later, history files currently have only one purpose for me
! and the old way works very well.

! ORF 2019-11-15 if we stagger restarts we can't do any MPI stuff here.
! I'm failry certain the budget stuff is wrong anyway so just set these
! to zero.

!      cfoo = 0.0
!      call MPI_REDUCE(qbudget(1),cfoo(1),nbudget,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
!                      MPI_COMM_CM1,ierr)
!      if( myid.eq.0 )then
!        do n=1,nbudget
!          qbudget(n)=cfoo(n)
!        enddo
!      else
!        qbudget = 0.0
!      endif
!      if( imoist.eq.1 )then
!        afoo = 0.0
!        call MPI_REDUCE(asq(1),afoo(1),numq,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
!                        MPI_COMM_CM1,ierr)
!        if( myid.eq.0 )then
!          do n=1,numq
!            asq(n)=afoo(n)
!          enddo
!        else
!          asq = 0.0
!        endif
!        bfoo = 0.0
!        call MPI_REDUCE(bsq(1),bfoo(1),numq,MPI_DOUBLE_PRECISION,MPI_SUM,0,  &
!                        MPI_COMM_CM1,ierr)
!        if( myid.eq.0 )then
!          do n=1,numq
!            bsq(n)=bfoo(n)
!          enddo
!        else
!          bsq = 0.0
!        endif
!      endif
      qbudget=0
      asq=0
      bsq=0

      varname='qbudget'; arshp1 = shape(qbudget); call wr1dsimpled (f_id,qbudget,arshp1(1))
      varname='asq';         arshp1 = shape(asq); call wr1dsimpled (f_id,asq,arshp1(1))
      varname='bsq';         arshp1 = shape(bsq); call wr1dsimpled (f_id,bsq,arshp1(1))

      varname='rain';           arshp3 = shape(rain); call wr3dsimpler (f_id,rain,arshp3(1),arshp3(2),arshp3(3))
      varname='sws';             arshp3 = shape(sws); call wr3dsimpler (f_id,sws,arshp3(1),arshp3(2),arshp3(3))
      varname='svs'; arshp3 = shape(svs); call wr3dsimpler (f_id,svs,arshp3(1),arshp3(2),arshp3(3))
      varname='sps'; arshp3 = shape(sps); call wr3dsimpler (f_id,sps,arshp3(1),arshp3(2),arshp3(3))
      varname='srs'; arshp3 = shape(srs); call wr3dsimpler (f_id,srs,arshp3(1),arshp3(2),arshp3(3))
      varname='sgs'; arshp3 = shape(sgs); call wr3dsimpler (f_id,sgs,arshp3(1),arshp3(2),arshp3(3))
      varname='sus'; arshp3 = shape(sus); call wr3dsimpler (f_id,sus,arshp3(1),arshp3(2),arshp3(3))
      varname='shs'; arshp3 = shape(shs); call wr3dsimpler (f_id,shs,arshp3(1),arshp3(2),arshp3(3))
      varname='orfswaths'; arshp4 = shape(orfswaths); call wr4dsimpler (f_id,orfswaths,arshp4(1),arshp4(2),arshp4(3),arshp4(4))
#ifdef CDORF
! Looks like George saves 2D CD data so we probably don't need this anymore
!     varname='cdorf'; arshp2 = shape(cdorf); call wr2dsimpler (f_id,varname,cdorf,arshp2(1),arshp2(2))
#endif
      varname='tsk'; arshp2 = shape(tsk); call wr2dsimpler (f_id,tsk,arshp2(1),arshp2(2))

! "Standard 3D"

      varname='rho'; arshp3 = shape(rho); call wr3dsimpler (f_id,rho,arshp3(1),arshp3(2),arshp3(3))
      varname='prs'; arshp3 = shape(prs); call wr3dsimpler (f_id,prs,arshp3(1),arshp3(2),arshp3(3))
      varname='ua';  arshp3 = shape(ua);  call wr3dsimpler (f_id,ua,arshp3(1),arshp3(2),arshp3(3))
      varname='va';  arshp3 = shape(va);  call wr3dsimpler (f_id,va,arshp3(1),arshp3(2),arshp3(3))
      varname='wa';  arshp3 = shape(wa);  call wr3dsimpler (f_id,wa,arshp3(1),arshp3(2),arshp3(3))
      varname='ppi'; arshp3 = shape(ppi); call wr3dsimpler (f_id,ppi,arshp3(1),arshp3(2),arshp3(3))
      varname='tha'; arshp3 = shape(tha); call wr3dsimpler (f_id,tha,arshp3(1),arshp3(2),arshp3(3))
!     varname='ppx'; arshp3 = shape(ppx); call wr3dsimpler (f_id,ppx,arshp3(1),arshp3(2),arshp3(3))
! Hae no idea what ppx is about...


! Note, George writes a 3d array per microphysics variable. We stick to 4d array dump.

      if(imoist.eq.1) then
            varname='qa'; arshp4 = shape(qa); call wr4dsimpler (f_id,qa,arshp4(1),arshp4(2),arshp4(3),arshp4(4))
      endif

!     if(imoist.eq.1.and.eqtset.eq.2)then
      if(imoist.eq.1.and.neweqts.ge.1)then
            varname='qpten'; arshp3 = shape(qpten); call wr3dsimpler (f_id,qpten,arshp3(1),arshp3(2),arshp3(3))
            varname='qtten'; arshp3 = shape(qtten); call wr3dsimpler (f_id,qtten,arshp3(1),arshp3(2),arshp3(3))
            varname='qvten'; arshp3 = shape(qvten); call wr3dsimpler (f_id,qvten,arshp3(1),arshp3(2),arshp3(3))
            varname='qcten'; arshp3 = shape(qcten); call wr3dsimpler (f_id,qcten,arshp3(1),arshp3(2),arshp3(3))
      endif

      if(iturb.eq.1) then
            varname='tkea'; arshp3 = shape(tkea); call wr3dsimpler (f_id,tkea,arshp3(1),arshp3(2),arshp3(3))
      endif

! Not saving radiation

! sfcmodel.eq.1 in our simulations so that's the only thing that really
! needs to be checked unless we eventually adapt to save all this extra
! stuff.

      if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
          if(sfcmodel.ge.1)then
              varname='ust'; arshp2 = shape(ust); call wr2dsimpler (f_id,ust,arshp2(1),arshp2(2))
              varname='znt'; arshp2 = shape(znt); call wr2dsimpler (f_id,znt,arshp2(1),arshp2(2))
              varname='cd'; arshp2 = shape(cd); call wr2dsimpler (f_id,cd,arshp2(1),arshp2(2))
!             varname='ch'; arshp2 = shape(ch); call wr2dsimpler (f_id,ch,arshp2(1),arshp2(2))
!             varname='cq'; arshp2 = shape(cq); call wr2dsimpler (f_id,cq,arshp2(1),arshp2(2))
              varname='u1'; arshp2 = shape(u1); call wr2dsimpler (f_id,u1,arshp2(1),arshp2(2))
              varname='v1'; arshp2 = shape(v1); call wr2dsimpler (f_id,v1,arshp2(1),arshp2(2))
!             varname='s1'; arshp2 = shape(s1); call wr2dsimpler (f_id,s1,arshp2(1),arshp2(2))
              varname='u10'; arshp2 = shape(u10); call wr2dsimpler (f_id,u10,arshp2(1),arshp2(2))
              varname='v10'; arshp2 = shape(v10); call wr2dsimpler (f_id,v10,arshp2(1),arshp2(2))
!             varname='s10'; arshp2 = shape(s10); call wr2dsimpler (f_id,s10,arshp2(1),arshp2(2))
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
!     if(dowr)write(outfile,"('Closed restart file on root node.')")
!     call FFLUSH(6)
!     call mpi_barrier(MPI_COMM_CM1,ierr);check_err(ierr)
!     if(dowr)write(outfile,"('Closed restart files on all nodes.')")
!     call FFLUSH(6)

!endif rsfile_exists
!ORF If the restart file already exists, just jump to here, write the "fake"
!last_restart file and get the fuck out of here!

      !ORF HERE IS WHERE WE WRITE THE INTEGER RESTART TIME so we can use
      !sed/awk to create a new namelist file on the fly (from within
      !the PBS script) with the last good restart time, since huge runs
      !tend to die after a couple of fucking hours due to just failing
      !hardware, fuck! So that 28 hour run time you finally got is
      !almost totally wasted unless you can get the model to restart
      !following the failure. The PBS file will either run within a
      !while true loop or I will just do a bunch of apruns manually.

      !itime is the integer value of the restart file time. Restarts
      !always land on integer times (I make sure of that... by choosing
      !a time step that is 1/N seconds where N is an integer.)

      !Move this to solve

!     if(myid.eq.0) then
!           open(unit=1000,file="last_restart",status='unknown')
!           write(1000,"(i6)") itime
!           close(unit=1000)
!     endif

      return
      end subroutine write_restart_hdf5


    subroutine read_restart_hdf5(wr3dindex,nstep,nrec,prec,nwrite,nrst, &
                         dt,dtlast,mtime,ndt,adt,acfl,dbldt,                  &
                         stattim,taptim,rsttim,radtim,prcltim,                &
                         qbudget,asq,bsq,                               &
                         rain,sws,svs,sps,srs,sgs,sus,shs,                    &
                         tsk,znt,ust,cd,u1,v1,thflux,qvflux,         &
                         radbcw,radbce,radbcs,radbcn,                         &
                         rho,prs,ua,va,wa,ppi,tha,qa,tkea,                    &
                         psfc,u10,v10,xland,      &
                         qpten,qtten,qvten,qcten,pta,pdata)

      implicit none
      include 'radcst.incl'

      integer, intent(inout) :: wr3dindex,nstep,nrec,prec,nwrite,nrst
      real, intent(inout) :: dt,dtlast
      integer, intent(inout) :: ndt
      double precision, intent(inout) :: adt,acfl,dbldt
      double precision, intent(inout) :: mtime,stattim,taptim,rsttim,radtim
      real, intent(inout) :: prcltim
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

!ORF stuff begins here

      integer(HID_T) f_id,dspace_id,dset_id
      integer(HSIZE_T), DIMENSION(4) :: dims
      integer :: rank
      integer abort_model

      integer, dimension(1):: arshp1
      integer, dimension(2):: arshp2
      integer, dimension(3):: arshp3
      integer, dimension(4):: arshp4

! Be careful, we no longer hardwire 'restart' in the running directory to
! be the restart top level directory. Command line needs to take care of this.

! rstnum is the time in (double precision) seconds

      abort_model=0
      call h5_file_op_int(op_mkrestartfilename,rstnum)
      call h5fopen_f(filename,H5F_ACC_RDONLY_F,f_id,ierr); check_err(ierr)
      if(ierr.lt.0) then
            print*, "COULD NOT OPEN FILE=",trim(filename)
            abort_model=1
      endif
      if(ierr.ge.0.and.myid.eq.0)print*, "read_restart_hdf: opened ",trim(filename)

      dims(1)=1

      call h5dopen_f(f_id,'wr3dindex',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,wr3dindex,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'nstep',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,nstep,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'nrec',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,nrec,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'prec',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,prec,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'nwrite',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,nwrite,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'nrst',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,nrst,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'dt',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,dt,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'dtlast',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,dtlast,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'mtime',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,mtime,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'ndt',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_INTEGER,ndt,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'adt',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,adt,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'acfl',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,acfl,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'dbldt',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,dbldt,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'stattim',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,stattim,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'taptim',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,taptim,dims,ierr); check_err(ierr)

!ORF 2019-12-15 let's just reset taptim to mtime+tapfrq This really
!isn't that important other than it will make history directory names
!end in zeroes more often! In other words we won't carry the legacy of previous
!simulations. Functionally this does nothing new as LOFS just parses directory
!names as times and it's 32 bit floating point arithmatic under the hood.

      taptim = mtime + tapfrq
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'tapfrq_save',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,tapfrq_save,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'rsttim',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,rsttim,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)
      call h5dopen_f(f_id,'prcltim',dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,prcltim,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

! ORF These were saved differently, I don't use them but we should make
! sure qbudget, asq and bsq aren't garbage

      varname='qbudget'; arshp1 = shape(qbudget); dims(1)=arshp1(1);
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,qbudget,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='asq'; arshp1 = shape(asq); dims(1)=arshp1(1);
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,asq,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='bsq'; arshp1 = shape(bsq); dims(1)=arshp1(1);
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_DOUBLE,bsq,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='rain'; arshp3 = shape(rain); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,rain,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='sws'; arshp3 = shape(sws); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,sws,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='svs'; arshp3 = shape(svs); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,svs,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='sps'; arshp3 = shape(sps); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,sps,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='srs'; arshp3 = shape(srs); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,srs,dims,ierr); check_err(ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='sgs'; arshp3 = shape(sgs); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,sgs,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='sus'; arshp3 = shape(sus); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,sus,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='shs'; arshp3 = shape(shs); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,shs,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='orfswaths'; arshp4 = shape(orfswaths); dims(1)=arshp4(1);dims(2)=arshp4(2);dims(3)=arshp4(3);dims(4)=arshp4(4)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,orfswaths,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

#ifdef CDORF
! Note, cd is now stored as a 2D array anyway, look into this later
!     varname='cdorf'; arshp2 = shape(cdorf); dims(1)=arshp2(1);dims(2)=arshp2(2)
!     call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
!     call h5dread_f(dset_id,H5T_NATIVE_REAL,cdorf,dims,ierr); check_err(ierr)
!     call h5dclose_f(dset_id,ierr); check_err(ierr)
#endif

      varname='tsk'; arshp2 = shape(tsk); dims(1)=arshp2(1);dims(2)=arshp2(2)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,tsk,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

! "Standard 3D"

      varname='rho'; arshp3 = shape(rho); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,rho,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='prs'; arshp3 = shape(prs); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,prs,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='ua'; arshp3 = shape(ua); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,ua,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

! Consider changebox boolean, and then if .true. add on uadjust, vadjust

!    ua = ua - 3.1719

      varname='va'; arshp3 = shape(va); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,va,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

!    va = va + 3.9219

      if(adjust_box_speed_from_restart)ua=ua+uadjust
      if(adjust_box_speed_from_restart)va=va+vadjust
1010  format("Adjusted box speed from restart by uadjust = ",f10.5," vadjust = ",f10.5)
      if (myid.eq.0.and.adjust_box_speed_from_restart) then
            write(*,1010) uadjust,vadjust
      endif

      varname='wa'; arshp3 = shape(wa); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,wa,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='ppi'; arshp3 = shape(ppi); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,ppi,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

      varname='tha'; arshp3 = shape(tha); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
      call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
      call h5dread_f(dset_id,H5T_NATIVE_REAL,tha,dims,ierr); check_err(ierr)
      call h5dclose_f(dset_id,ierr); check_err(ierr)

!     varname='ppx'; arshp3 = shape(ppx); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
!     call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
!     call h5dread_f(dset_id,H5T_NATIVE_REAL,ppx,dims,ierr); check_err(ierr)
!     call h5dclose_f(dset_id,ierr); check_err(ierr)

      if (imoist.eq.1) then
            varname='qa'; arshp4 = shape(qa); dims(1)=arshp4(1);dims(2)=arshp4(2);dims(3)=arshp4(3);dims(4)=arshp4(4)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,qa,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

!     if(imoist.eq.1.and.eqtset.eq.2)then
      if(imoist.eq.1.and.neweqts.ge.1)then

            varname='qpten'; arshp3 = shape(qpten); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,qpten,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='qtten'; arshp3 = shape(qtten); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,qtten,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='qvten'; arshp3 = shape(qvten); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,qvten,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='qcten'; arshp3 = shape(qcten); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,qcten,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

      endif

      if (iturb.eq.1) then
            varname='tkea'; arshp3 = shape(tkea); dims(1)=arshp3(1);dims(2)=arshp3(2);dims(3)=arshp3(3)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,tkea,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

! Not saving radiation

! Only saving sfcmodel.eq.1, really.

      if((oceanmodel.eq.2).or.(ipbl.eq.1).or.(sfcmodel.ge.1))then
          if(sfcmodel.ge.1)then

            varname='ust'; arshp2 = shape(ust); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,ust,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='znt'; arshp2 = shape(znt); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,znt,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='cd'; arshp2 = shape(cd); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,cd,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

!           varname='ch'; arshp2 = shape(ch); dims(1)=arshp2(1);dims(2)=arshp2(2)
!           call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
!           call h5dread_f(dset_id,H5T_NATIVE_REAL,ch,dims,ierr); check_err(ierr)
!           call h5dclose_f(dset_id,ierr); check_err(ierr)
 
!           varname='cq'; arshp2 = shape(cq); dims(1)=arshp2(1);dims(2)=arshp2(2)
!           call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
!           call h5dread_f(dset_id,H5T_NATIVE_REAL,cq,dims,ierr); check_err(ierr)
!           call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='u1'; arshp2 = shape(u1); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,u1,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='v1'; arshp2 = shape(v1); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,v1,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='u10'; arshp2 = shape(u10); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,u10,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

!           varname='s10'; arshp2 = shape(s10); dims(1)=arshp2(1);dims(2)=arshp2(2)
!           call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
!           call h5dread_f(dset_id,H5T_NATIVE_REAL,s10,dims,ierr); check_err(ierr)
!           call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='xland'; arshp2 = shape(xland); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,xland,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='thflux'; arshp2 = shape(thflux); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,thflux,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='qvflux'; arshp2 = shape(qvflux); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,qvflux,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)

            varname='psfc'; arshp2 = shape(psfc); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,psfc,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
        endif
! ORF not handling (sfcmodel .eq. 2 .or. sfcmodel .eq. 3)
      endif

! NOTE george only writes parts of traj dat (position)

      if (iptra.eq.1) then
            varname='pta'; arshp4 = shape(pta); dims(1)=arshp4(1);dims(2)=arshp4(2);dims(3)=arshp4(3);dims(4)=arshp4(4)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,pta,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

      if (iprcl.eq.1) then
            varname='pdata'; arshp2 = shape(pdata); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,pdata,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

      if (irbc.eq.4.and.ibw.eq.1) then
            varname='radbcw'; arshp2 = shape(radbcw); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,radbcw,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

      if (irbc.eq.4.and.ibe.eq.1) then
            varname='radbce'; arshp2 = shape(radbce); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,radbce,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

      if (irbc.eq.4.and.ibs.eq.1) then
            varname='radbcs'; arshp2 = shape(radbcs); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,trim(varname),dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,radbcs,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
      endif

      if (irbc.eq.4.and.ibn.eq.1) then
            varname='radbcn'; arshp2 = shape(radbcn); dims(1)=arshp2(1);dims(2)=arshp2(2)
            call h5dopen_f(f_id,'radbcn',dset_id,ierr); check_err(ierr)
            call h5dread_f(dset_id,H5T_NATIVE_REAL,radbcn,dims,ierr); check_err(ierr)
            call h5dclose_f(dset_id,ierr); check_err(ierr)
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
      if(dowr) write(outfile,*)

!---------

      if( adapt_dt.eq.0 ) dt = dtl

!ORF blargh. <--------------FUCK YOU DUDE YOU DIPSHIT

!YEAH MOTHERFUCKING BLARGH THIS KICKED MY ASS FOR YEARS

! I should not have been setting nwrite to 1 below, bitches. By doing so
! I forced my off by one issue... because I set nwrite to 0 in cm1.F (It
! was 1 in original CM1). I had not realized how important nwrite was
! as I mod it with num_time_levels_per_hist_file. So by going from even
! to odd when I should have stayed even caused the off by one. I could
! not for the life of me figure out why the 1st history save following
! a run from a restart only had num_time_levels_per_hist_file-1 levels
! in it always!! Now I just respect the value of nwrite that is saved
! in the restart files. I should NEVER EVER have the off by one problem
! again. Whenever there is a restart save, I flush the history data
! of that time to disk. This (probably always) means I will have a
! standaline single time that matches the restart time, which is kind of
! convenient. Then, when running from a restart file (which always is a nice
! even number like 50 or 100) the first history directory/file will be named
! that nice even number PLUS TAPFRQ. So, for our 10 meter run, it's 100.20000
! since I am saving every 0.2 seconds.

!     IF( output_format .ne. old_format )THEN FUCKING KILL YOURSELF ASSHOLE
!       nrec = 1
!       nwrite = 1
!       prec = 1
!     ENDIF FUCKING KILLING YOURSELF ASSHOLE

!---------

#ifdef MPI
      if(timestats.ge.1)then
        ! this is needed for proper accounting of timing:
        call MPI_BARRIER (MPI_COMM_CM1,ierr)
      endif
#endif

! ORF if any of our restart files could not be read in successfully bail
      if(abort_model.eq.1) call stopcm1

      return
end subroutine read_restart_hdf5

