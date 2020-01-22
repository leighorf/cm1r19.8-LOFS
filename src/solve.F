  MODULE solve_module

!-----------------------------------------------------------------------------
!
!  CM1 Numerical Model, Release 19.8  (cm1r19.8)
!  31 March 2019
!  http://www2.mmm.ucar.edu/people/bryan/cm1/
!
!  (c)2019 - University Corporation for Atmospheric Research 
!
!-----------------------------------------------------------------------------
!  Quick Index:
!    ua/u3d     = velocity in x-direction (m/s)  (grid-relative)
!    va/v3d     = velocity in y-direction (m/s)  (grid-relative)
!       Note: when imove=1, ground-relative winds are umove+ua, umove+u3d,
!                                                     vmove+va, vmove+v3d.
!    wa/w3d     = velocity in z-direction (m/s)
!    tha/th3d   = perturbation potential temperature (K)
!    ppi/pp3d   = perturbation nondimensional pressure ("Exner function")
!    qa/q3d     = mixing ratios of moisture (kg/kg)
!    tkea/tke3d = SUBGRID turbulence kinetic energy (m^2/s^2)
!    kmh/kmv    = turbulent diffusion coefficients for momentum (m^2/s)
!    khh/khv    = turbulent diffusion coefficients for scalars (m^2/s)
!                 (h = horizontal, v = vertical)
!    prs        = pressure (Pa)
!    rho        = density (kg/m^3)
!
!    th0,pi0,prs0,etc = base-state arrays
!
!    xh         = x (m) at scalar points
!    xf         = x (m) at u points
!    yh         = y (m) at scalar points
!    yf         = y (m) at v points
!    zh         = z (m above sea level) of scalar points (aka, "half levels")
!    zf         = z (m above sea level) of w points (aka, "full levels")
!
!    For the axisymmetric model (axisymm=1), xh and xf are radius (m).
!
!  See "The governing equations for CM1" for more details:
!        http://www2.mmm.ucar.edu/people/bryan/cm1/cm1_equations.pdf
!-----------------------------------------------------------------------------
!  Some notes:
!
!  - Upon entering solve, the arrays ending in "a" (eg, ua,wa,tha,qa,etc)
!    are equivalent to the arrays ending in "3d" (eg, u3d,w3d,th3d,q3d,etc).
!  - The purpose of solve is to update the variables from time "t" to time
!    "t+dt".  Values at time "t+dt" are stored in the "3d" arrays.
!  - The "ghost zones" (boundaries beyond the computational subdomain) are
!    filled out completely (3 rows/columns) for the "3d" arrays.  To save 
!    unnecessary computations, starting with cm1r15 the "ghost zones" of 
!    the "a" arrays are only filled out to 1 row/column.  Hence, if you 
!    need to do calculations that use a large stencil, you must use the 
!    "3d" arrays (not the "a") arrays.
!  - Arrays named "ten" store tendencies.  Those ending "ten1" store
!    pre-RK tendencies that are calculated once and then held fixed during
!    the RK (Runge-Kutta) sub-steps. 
!  - CM1 uses a low-storage three-step Runge-Kutta scheme.  See Wicker
!    and Skamarock (2002, MWR, p 2088) for more information.
!  - CM1 uses a staggered C grid.  Hence, u arrays have one more grid point
!    in the i direction, v arrays have one more grid point in the j 
!    direction, and w arrays have one more grid point in the k direction
!    (compared to scalar arrays).
!  - CM1 assumes the subgrid turbulence parameters (tke,km,kh) are located
!    at the w points. 
!-----------------------------------------------------------------------------

  implicit none

  private
  public :: solve

  CONTAINS

      subroutine solve(nstep,rbufsz,num_soil_layers,                  &
                   dt,dtlast,mtime,dbldt,mass1,mass2,                 &
                   dosfcflx,cloudvar,rhovar,bud,bud2,qbudget,asq,bsq, &
                   xh,rxh,arh1,arh2,uh,ruh,xf,rxf,arf1,arf2,uf,ruf,   &
                   yh,vh,rvh,yf,vf,rvf,                               &
                   xfref,yfref,dumk1,dumk2,rds,sigma,rdsf,sigmaf,    &
                   tauh,taus,zh,mh,rmh,c1,c2,tauf,zf,mf,rmf,         &
                   rho0s,pi0s,prs0s,rth0s,                           &
                   wprof,ufrc,vfrc,thfrc,qvfrc,ug,vg,dvdr,           &
                   uavg,vavg,thavg,pavg,qavg,cavg,                   &
                   pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0,              &
                   qi0,rr0,rf0,rrf0,thrd,                            &
                   zs,gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy,gx,gxu,gy,gyv, &
                   rain,sws,svs,sps,srs,sgs,sus,shs,                 &
                   tsk,thflux,qvflux,cd,ch,cq,u1,v1,s1,tlh,f2d,prate, &
                   radbcw,radbce,radbcs,radbcn,                      &
                   dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,          &
                   divx,rho,rr,rf,prs,                               &
                   t11,t12,t13,t22,t23,t33,                          &
                   u0,rru,ua,u3d,uten,uten1,                         &
                   v0,rrv,va,v3d,vten,vten1,                         &
                   rrw,wa,w3d,wten,wten1,                            &
                   ppi,pp3d,ppten,sten,sadv,ppx,phi1,phi2,           &
                   tha,th3d,thten,thten1,thterm,                     &
                   qpten,qtten,qvten,qcten,qa,q3d,qten,              &
                   kmh,kmv,khh,khv,tkea,tke3d,tketen,                &
                   nm,defv,defh,dissten,                             &
                   thpten,qvpten,qcpten,qipten,upten,vpten,o30,zir,  &
                   swten,lwten,effc,effi,effs,effr,effg,effis,       &
                   lu_index,kpbl2d,psfc,u10,v10,s10,hfx,qfx,xland,znt,ust,  &
                   hpbl,wspd,psim,psih,gz1oz0,br,                    &
                   CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,                    &
                   MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,                 &
                   CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,    &
                   gsw,glw,chklowq,capg,snowc,dsxy,wstar,delta,fm,fh,  &
                   mznt,smois,taux,tauy,hpbl2d,evap2d,heat2d,rc2d,   &
                   slab_zs,slab_dzs,tslb,tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml,       &
                   pta,pt3d,ptten,pdata,                             &
                   cfb,cfa,cfc,ad1,ad2,pdt,lgbth,lgbph,rhs,trans,flag,  &
                   reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,               &
                   reqs_x,reqs_y,reqs_z,reqs_tk,reqs_q,reqs_t,       &
                   nw1,nw2,ne1,ne2,sw1,sw2,se1,se2,                  &
                   n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2,          &
                   ww1,ww2,we1,we2,ws1,ws2,wn1,wn2,                  &
                   pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,                  &
                   vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,                  &
                   zw1,zw2,ze1,ze2,zs1,zs2,zn1,zn2,                  &
                   uw31,uw32,ue31,ue32,us31,us32,un31,un32,          &
                   vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,          &
                   ww31,ww32,we31,we32,ws31,ws32,wn31,wn32,          &
                   sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,          &
                   rw31,rw32,re31,re32,rs31,rs32,rn31,rn32,          &
                   qw31,qw32,qe31,qe32,qs31,qs32,qn31,qn32,          &
                   tkw1,tkw2,tke1,tke2,tks1,tks2,tkn1,tkn2,          &
                   kw1,kw2,ke1,ke2,ks1,ks2,kn1,kn2,                  &
                   tw1,tw2,te1,te2,ts1,ts2,tn1,tn2,                  &
                   dat1,dat2,dat3,reqt,                              &
                   tdiag,qdiag,udiag,vdiag,wdiag,kdiag,pdiag,        &
                   out2d,out3d,                                      &
                   dowriteout,dorad,getdbz,getvt,dotdwrite,          &
                   doazimwrite,dorestart)
        ! end_solve
      use input
      use constants
      use bc_module
      use comm_module
      use adv_module
      use adv_routines , only : movesfc
      use diff2_module
      use turb_module
      use sound_module
      use sounde_module
      use soundns_module
      use soundcb_module
      use anelp_module
      use misclibs
      use kessler_module
      use module_mp_thompson , only : mp_gt_driver
      use module_mp_graupel , only : mp_graupel
      use module_mp_nssl_2mom, only : zscale, nssl_2mom_driver
      use goddard_module, only : goddard,satadj_ice,consat2
      use lfoice_module, only : lfo_ice_drive,lfoice_init
      use simple_phys_module, only : testcase_simple_phys,get_avg_uvt
      use parcel_module, only : parcel_driver
      use pdcomp_module, only : pidcomp
#ifdef MPI
      use mpi
#endif
      implicit none

!-----------------------------------------------------------------------
! Arrays and variables passed into solve

      integer, intent(in) :: nstep
      integer, intent(in) :: rbufsz,num_soil_layers
      real, intent(inout) :: dt,dtlast
      double precision, intent(in   ) :: mtime
      double precision, intent(inout) :: dbldt
      double precision, intent(in   ) :: mass1
      double precision, intent(inout) :: mass2
      logical, intent(in) :: dosfcflx
      logical, intent(in), dimension(maxq) :: cloudvar,rhovar
      double precision, intent(inout), dimension(nk) :: bud
      double precision, intent(inout), dimension(nj) :: bud2
      double precision, intent(inout), dimension(nbudget) :: qbudget
      double precision, intent(inout), dimension(numq) :: asq,bsq
      real, intent(in), dimension(ib:ie) :: xh,rxh,arh1,arh2,uh,ruh
      real, intent(in), dimension(ib:ie+1) :: xf,rxf,arf1,arf2,uf,ruf
      real, intent(in), dimension(jb:je) :: yh,vh,rvh
      real, intent(in), dimension(jb:je+1) :: yf,vf,rvf
      real, intent(in), dimension(1-ngxy:nx+ngxy+1) :: xfref
      real, intent(in), dimension(1-ngxy:ny+ngxy+1) :: yfref
      double precision, intent(inout), dimension(kb:ke) :: dumk1,dumk2
      real, intent(in), dimension(kb:ke) :: rds,sigma
      real, intent(in), dimension(kb:ke+1) :: rdsf,sigmaf
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: tauh,taus,zh,mh,rmh,c1,c2
      real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: tauf,zf,mf,rmf
      real, intent(in), dimension(ib:ie,jb:je) :: rho0s,pi0s,prs0s,rth0s
      real, intent(in),    dimension(kb:ke) :: wprof
      real, intent(inout), dimension(kb:ke) :: ufrc,vfrc,thfrc,qvfrc,ug,vg,dvdr,  &
                                               uavg,vavg,thavg,pavg
      real, intent(inout), dimension(kb:ke,numq) :: qavg
      double precision, intent(inout), dimension(kb:ke,3+numq) :: cavg
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: pi0,rho0,prs0,thv0,th0,rth0,qv0,qc0
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: qi0,rr0,rf0,rrf0
      real, intent(in), dimension(ibb2:ibe2,jbb2:jbe2,kbb2:kbe2) :: thrd
      real, intent(in), dimension(ib:ie,jb:je) :: zs
      real, intent(in), dimension(itb:ite,jtb:jte) :: gz,rgz,gzu,rgzu,gzv,rgzv,dzdx,dzdy
      real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gx,gxu,gy,gyv
      real, intent(inout), dimension(ib:ie,jb:je,nrain) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, intent(inout), dimension(ib:ie,jb:je) :: tsk,znt,ust,thflux,qvflux,cd,ch,cq,u1,v1,s1,psfc,tlh
      real, intent(in),    dimension(ib:ie,jb:je) :: xland,f2d
      real, intent(inout), dimension(ib:ie,jb:je) :: prate
      real, intent(inout), dimension(jb:je,kb:ke) :: radbcw,radbce
      real, intent(inout), dimension(ib:ie,kb:ke) :: radbcs,radbcn
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: divx,rho,rr,rf,prs
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: t11,t12,t13,t22,t23,t33
      real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: u0
      real, intent(inout), dimension(ib:ie+1,jb:je,kb:ke) :: rru,ua,u3d,uten,uten1
      real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: v0
      real, intent(inout), dimension(ib:ie,jb:je+1,kb:ke) :: rrv,va,v3d,vten,vten1
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: rrw,wa,w3d,wten,wten1
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: ppi,pp3d,ppten,sten,sadv,ppx
      real, intent(inout), dimension(ibph:ieph,jbph:jeph,kbph:keph) :: phi1,phi2
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: tha,th3d,thten,thten1,thterm
      real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem) :: qpten,qtten,qvten,qcten
      real, intent(inout), dimension(ibm:iem,jbm:jem,kbm:kem,numq) :: qa,q3d,qten
      real, intent(inout), dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv
      real, intent(inout), dimension(ibt:iet,jbt:jet,kbt:ket) :: tkea,tke3d,tketen
      real, intent(inout), dimension(ib:ie,jb:je,kb:ke+1) :: nm,defv,defh,dissten
      real, intent(inout), dimension(ibb:ieb,jbb:jeb,kbb:keb) :: thpten,qvpten,qcpten,qipten,upten,vpten
      real, intent(inout), dimension(ibr:ier,jbr:jer,kbr:ker) :: o30
      real, intent(inout), dimension(ibr:ier,jbr:jer) :: zir
      real, intent(inout), dimension(ibr:ier,jbr:jer,kbr:ker) :: swten,lwten
      real, intent(inout), dimension(ibr:ier,jbr:jer,kbr:ker) :: effc,effi,effs,effr,effg,effis
      integer, intent(inout), dimension(ibl:iel,jbl:jel) :: lu_index
      integer, intent(inout), dimension(ibl:iel,jbl:jel) :: kpbl2d
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: u10,v10,s10,hfx,qfx, &
                                      hpbl,wspd,psim,psih,gz1oz0,br,          &
                                      CHS,CHS2,CQS2,CPMM,ZOL,MAVAIL,          &
                                      MOL,RMOL,REGIME,LH,FLHC,FLQC,QGH,       &
                                      CK,CKA,CDA,USTM,QSFC,T2,Q2,TH2,EMISS,THC,ALBD,   &
                                      gsw,glw,chklowq,capg,snowc,dsxy,wstar,delta,fm,fh
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: mznt,smois,taux,tauy,hpbl2d,evap2d,heat2d,rc2d
      real, intent(in), dimension(num_soil_layers) :: slab_zs,slab_dzs
      real, intent(inout), dimension(ibl:iel,jbl:jel,num_soil_layers) :: tslb
      real, intent(inout), dimension(ibl:iel,jbl:jel) :: tmn,tml,t0ml,hml,h0ml,huml,hvml,tmoml
      real, intent(inout), dimension(ibp:iep,jbp:jep,kbp:kep,npt) :: pta,pt3d,ptten
      real, intent(inout), dimension(nparcels,npvals) :: pdata
      real, intent(in), dimension(ipb:ipe,jpb:jpe,kpb:kpe) :: cfb
      real, intent(in), dimension(kpb:kpe) :: cfa,cfc,ad1,ad2
      complex, intent(inout), dimension(ipb:ipe,jpb:jpe,kpb:kpe) :: pdt,lgbth,lgbph
      complex, intent(inout), dimension(ipb:ipe,jpb:jpe) :: rhs,trans
      logical, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: flag
      integer, intent(inout), dimension(rmp) :: reqs_u,reqs_v,reqs_w,reqs_s,reqs_p,reqs_x,reqs_y,reqs_z,reqs_tk
      integer, intent(inout), dimension(rmp,numq) :: reqs_q
      integer, intent(inout), dimension(rmp,npt) :: reqs_t
      real, intent(inout), dimension(kmt) :: nw1,nw2,ne1,ne2,sw1,sw2,se1,se2
      real, intent(inout), dimension(cmp,cmp,kmt+1) :: n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2
      real, intent(inout), dimension(jmp,kmp-1) :: ww1,ww2,we1,we2
      real, intent(inout), dimension(imp,kmp-1) :: ws1,ws2,wn1,wn2
      real, intent(inout), dimension(jmp,kmp) :: pw1,pw2,pe1,pe2
      real, intent(inout), dimension(imp,kmp) :: ps1,ps2,pn1,pn2
      real, intent(inout), dimension(jmp,kmp) :: vw1,vw2,ve1,ve2
      real, intent(inout), dimension(imp,kmp) :: vs1,vs2,vn1,vn2
      real, intent(inout), dimension(jmp,kmp) :: zw1,zw2,ze1,ze2
      real, intent(inout), dimension(imp,kmp) :: zs1,zs2,zn1,zn2
      real, intent(inout), dimension(cmp,jmp,kmp)   :: uw31,uw32,ue31,ue32
      real, intent(inout), dimension(imp+1,cmp,kmp) :: us31,us32,un31,un32
      real, intent(inout), dimension(cmp,jmp+1,kmp) :: vw31,vw32,ve31,ve32
      real, intent(inout), dimension(imp,cmp,kmp)   :: vs31,vs32,vn31,vn32
      real, intent(inout), dimension(cmp,jmp,kmp-1) :: ww31,ww32,we31,we32
      real, intent(inout), dimension(imp,cmp,kmp-1) :: ws31,ws32,wn31,wn32
      real, intent(inout), dimension(cmp,jmp,kmp)   :: sw31,sw32,se31,se32
      real, intent(inout), dimension(imp,cmp,kmp)   :: ss31,ss32,sn31,sn32
      real, intent(inout), dimension(cmp,jmp,kmp)   :: rw31,rw32,re31,re32
      real, intent(inout), dimension(imp,cmp,kmp)   :: rs31,rs32,rn31,rn32
      real, intent(inout), dimension(cmp,jmp,kmp,numq) :: qw31,qw32,qe31,qe32
      real, intent(inout), dimension(imp,cmp,kmp,numq) :: qs31,qs32,qn31,qn32
      real, intent(inout), dimension(cmp,jmp,kmt)   :: tkw1,tkw2,tke1,tke2
      real, intent(inout), dimension(imp,cmp,kmt)   :: tks1,tks2,tkn1,tkn2
      real, intent(inout), dimension(jmp,kmt,4)     :: kw1,kw2,ke1,ke2
      real, intent(inout), dimension(imp,kmt,4)     :: ks1,ks2,kn1,kn2
      real, intent(inout), dimension(cmp,jmp,kmp,npt) :: tw1,tw2,te1,te2
      real, intent(inout), dimension(imp,cmp,kmp,npt) :: ts1,ts2,tn1,tn2
      real, intent(inout), dimension(ni+1,nj+1) :: dat1
      real, intent(inout), dimension(d2i,d2j) :: dat2
      real, intent(inout), dimension(d3i,d3j,d3n) :: dat3
      integer, intent(inout), dimension(d3t) :: reqt
      real, intent(inout) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
      real, intent(inout) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
      real, intent(inout) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nudiag) :: udiag
      real, intent(inout) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nvdiag) :: vdiag
      real, intent(inout) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nwdiag) :: wdiag
      real, intent(inout) , dimension(ibdk:iedk,jbdk:jedk,kbdk:kedk,nkdiag) :: kdiag
      real, intent(inout) , dimension(ibdp:iedp,jbdp:jedp,kbdp:kedp,npdiag) :: pdiag
      real, intent(inout) , dimension(ib2d:ie2d,jb2d:je2d,nout2d) :: out2d
      real, intent(inout) , dimension(ib3d:ie3d,jb3d:je3d,kb3d:ke3d,nout3d) :: out3d
      logical, intent(in) :: dowriteout,dorad,dotdwrite,doazimwrite,dorestart
      logical, intent(inout) :: getdbz,getvt

!-----------------------------------------------------------------------
! Arrays and variables defined inside solve

      integer :: i,j,k,n,nrk,bflag,pdef,diffit,k1
      integer :: has_reqc,has_reqi,has_reqs,do_radar_ref

      real :: delqv,delpi,delth,delt,fac,epsd,dheat,dz1,xs
      real :: foo1,foo2
      real :: dttmp,rtime,rdt,tem,tem0,tem1,tem2,thrad,prad
      real :: cpm,cvm
      real :: r1,r2,tnew,pnew,pinew,thnew,qvnew
      real :: gamm,aiu
      real :: qmax

      double precision :: weps,afoo,bfoo,p0,p2

      logical :: get_time_avg,dotbud,doqbud,doubud,dovbud,dowbud

!--------------------------------------------------------------------

#ifdef MPI
      nf=0
      nu=0
      nv=0
      nw=0
#endif

      afoo=0.0d0
      bfoo=0.0d0

      dotbud = .false.
      doqbud = .false.
      doubud = .false.
      dovbud = .false.
      dowbud = .false.

      IF( dowriteout .or. dotdwrite )THEN
        if( output_thbudget.eq.1 .or. doturbdiag )THEN
          dotbud = .true.
          if(myid.eq.0) print *,'  dotbud = ',dotbud
        endif
        if( output_qvbudget.eq.1 .or. doturbdiag )THEN
          doqbud = .true.
          if(myid.eq.0) print *,'  doqbud = ',doqbud
        endif
        if( output_ubudget.eq.1 .or. doturbdiag )THEN
          doubud = .true.
          if(myid.eq.0) print *,'  doubud = ',doubud
        endif
        if( output_vbudget.eq.1 .or. doturbdiag )THEN
          dovbud = .true.
          if(myid.eq.0) print *,'  dovbud = ',dovbud
        endif
        if( output_wbudget.eq.1 .or. doturbdiag )THEN
          dowbud = .true.
          if(myid.eq.0) print *,'  dowbud = ',dowbud
        endif
      ENDIF


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!cc   subgrid turbulence schemes  cccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!--------------------------------------------------------------------
!  get RHS for tke scheme:

      IF(sgsmodel.eq.1)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        DO k=2,nk
          !  Buoyancy, Dissipation, and Shear terms:
          do j=1,nj
          do i=1,ni
            tketen(i,j,k) = -khv(i,j,k)*nm(i,j,k)  &
                            -dissten(i,j,k)
          enddo
          enddo
          ! Shear term 
          IF(tconfig.eq.1)THEN
            do j=1,nj
            do i=1,ni
              tketen(i,j,k)=tketen(i,j,k)+kmv(i,j,k)*max(0.0,(defv(i,j,k)+defh(i,j,k)))
            enddo
            enddo
          ELSEIF(tconfig.eq.2)THEN
            do j=1,nj
            do i=1,ni
              tketen(i,j,k)=tketen(i,j,k)+kmv(i,j,k)*max(0.0,defv(i,j,k))   &
                                         +kmh(i,j,k)*max(0.0,defh(i,j,k))
            enddo
            enddo
          ENDIF
        ENDDO
        if(timestats.ge.1) time_turb=time_turb+mytime()

        if( dotdwrite .and. kd_turb.ge.1 )then
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk+1
          do j=1,nj
          do i=1,ni
            kdiag(i,j,k,kd_turb) = tketen(i,j,k)
          enddo
          enddo
          enddo
        endif

        call turbt(dt,xh,rxh,uh,xf,uf,vh,vf,mh,mf,rho,rr,rf,  &
                   rds,sigma,gz,rgz,gzu,rgzu,gzv,rgzv,        &
                   dum1,dum2,dum3,dum4,dum5,sten,tkea,tketen,kmh,kmv)

        if( dotdwrite .and. kd_turb.ge.1 )then
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk+1
          do j=1,nj
          do i=1,ni
            kdiag(i,j,k,kd_turb) = tketen(i,j,k)-kdiag(i,j,k,kd_turb)
          enddo
          enddo
          enddo
        endif

      ENDIF


!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CC   Pre-RK calculations   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      IF( irdamp.eq.2 .or. hrdamp.eq.2 )THEN

        call     get_avg_uvt(uavg,vavg,thavg,cavg,th0,ua,va,tha,ruh,ruf,rvh,rvf)

      ENDIF

!--------------------------------------------------------------------
!  radbc
 
      if(irbc.eq.1)then

        if(ibw.eq.1 .or. ibe.eq.1) call radbcew(radbcw,radbce,ua)
 
        if(ibs.eq.1 .or. ibn.eq.1) call radbcns(radbcs,radbcn,va)

      endif

!--------------------------------------------------------------------
!  U-equation

      IF( irdamp.eq.1 .or. hrdamp.eq.1 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          uten1(i,j,k) = -rdalpha*0.5*(tauh(i-1,j,k)+tauh(i,j,k))*(ua(i,j,k)-u0(i,j,k))
        enddo
        enddo
        enddo
      ELSEIF( irdamp.eq.2 .or. hrdamp.eq.2 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          uten1(i,j,k) = -rdalpha*0.5*(tauh(i-1,j,k)+tauh(i,j,k))*(ua(i,j,k)-uavg(k))
        enddo
        enddo
        enddo
      ELSE
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          uten1(i,j,k) = 0.0
        enddo
        enddo
        enddo
      ENDIF
      if( doubud .and. ud_rdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          udiag(i,j,k,ud_rdamp) = uten1(i,j,k)
        enddo
        enddo
        enddo
      endif
      if(timestats.ge.1) time_rdamp=time_rdamp+mytime()


      IF( lspgrad.ge.1 )THEN
        ! Include a large-scale pressure gradient:
        if(     lspgrad.eq.1 )then
          !---------------------------------------------------------------!
          ! Large-scale pressure gradient based on geostropic balance,
          ! using base-state wind profiles:
          !---------------------------------------------------------------!
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni+1
            ! 170728 bug fix:  account for grid staggering:
            ! 180618:  when imove=1, need to add vmove to base state
            uten1(i,j,k) = uten1(i,j,k)-fcor*( 0.25*( (v0(i  ,j,k)+v0(i  ,j+1,k))   &
                                                     +(v0(i-1,j,k)+v0(i-1,j+1,k)) ) + vmove )
          enddo
          enddo
          enddo
        elseif( lspgrad.eq.2 )then
          !---------------------------------------------------------------!
          ! Large-scale pressure gradient based on geostropic balance,
          ! using ug,vg arrays:
          !---------------------------------------------------------------!
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni+1
            uten1(i,j,k) = uten1(i,j,k)-fcor*(vg(k)+vmove)
          enddo
          enddo
          enddo
        elseif( lspgrad.eq.3 )then
          !---------------------------------------------------------------!
          ! Large-scale pressure gradient based on gradient-wind balance,
          ! (Bryan et al, 2017, BLM, eqn 10)
          ! using base-state wind profiles:
          !---------------------------------------------------------------!
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,tem)
          do k=1,nk
            tem = -fcor*v0(1,1,k)-v0(1,1,k)*v0(1,1,k)/hurr_rad
            do j=1,nj
            do i=1,ni+1
              uten1(i,j,k) = uten1(i,j,k)+tem
            enddo
            enddo
          enddo
        endif
        if(timestats.ge.1) time_misc=time_misc+mytime()
      ENDIF


      IF( iinit.eq.10 .and. mtime.lt.t2_uforce )THEN
        ! u-forcing for squall-line initialization:
        ! (Morrison et al, 2015, JAS, pg 315)
        gamm = 1.0
        if(mtime.ge.t1_uforce)THEN
          gamm = 1.0+(0.0-1.0)*(mtime-t1_uforce)/(t2_uforce-t1_uforce)
        endif
        if(myid.eq.0) print *,'  mtime,gamm = ',mtime,gamm
!$omp parallel do default(shared)  &
!$omp private(i,j,k,aiu)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          if( abs(xf(i)-xc_uforce).lt.xr_uforce .and. abs(zf(i,j,k)-zs(i,j)).lt.zr_uforce )then
            aiu = alpha_uforce*cos(0.5*pi*(xf(i)-xc_uforce)/xr_uforce)   &
                              *((cosh(2.5*(zf(i,j,k)-zs(i,j))/zr_uforce))**(-2))
            uten1(i,j,k)=uten1(i,j,k)+gamm*aiu
          endif
        enddo
        enddo
        enddo
      ENDIF
      if(timestats.ge.1) time_rdamp=time_rdamp+mytime()

      if(idiff.ge.1)then
        if(difforder.eq.2)then
          call diff2u(rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,mh,mf,  &
                      dum1,dum2,dum3,dum4,uten1,ust,rho,rr,rf,divx,t11,t12,t13, &
                      doubud,udiag)
        endif
      endif

      if( dohturb .or. dovturb )then
        call turbu(dt,xh,ruh,xf,rxf,arf1,arf2,uf,vh,mh,mf,rmf,rho,rf,  &
                   zs,gz,rgz,gzu,gzv,rds,sigma,rdsf,sigmaf,gxu,     &
                   dum1,dum2,dum3,dum4,dum5,dum6,ua,uten1,wa,t11,t12,t13,t22,kmv, &
                   doubud,udiag)
      endif

      if(ipbl.eq.1)then
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          uten1(i,j,k) = uten1(i,j,k) + 0.5*( upten(i-1,j,k)+ upten(i,j,k))
        enddo
        enddo
        enddo
        IF( doubud .and. ud_pbl.ge.1 )then
          !$omp parallel do default(shared)   &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni+1
            udiag(i,j,k,ud_pbl) = 0.5*( upten(i-1,j,k)+ upten(i,j,k))
          enddo
          enddo
          enddo
        ENDIF
        if(timestats.ge.1) time_pbl=time_pbl+mytime()
      endif

!--------------------------------------------------------------------
!  V-equation
 
      IF( irdamp.eq.1 .or. hrdamp.eq.1 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vten1(i,j,k) = -rdalpha*0.5*(tauh(i,j-1,k)+tauh(i,j,k))*(va(i,j,k)-v0(i,j,k))
        enddo
        enddo
        enddo
      ELSEIF( irdamp.eq.2 .or. hrdamp.eq.2 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vten1(i,j,k) = -rdalpha*0.5*(tauh(i,j-1,k)+tauh(i,j,k))*(va(i,j,k)-vavg(k))
        enddo
        enddo
        enddo
      ELSE
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vten1(i,j,k) = 0.0
        enddo
        enddo
        enddo
      ENDIF
      if( dovbud .and. vd_rdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vdiag(i,j,k,vd_rdamp) = vten1(i,j,k)
        enddo
        enddo
        enddo
      endif
      if(timestats.ge.1) time_rdamp=time_rdamp+mytime()


      IF( lspgrad.ge.1 )THEN
        ! Include a large-scale pressure gradient:
        if(     lspgrad.eq.1 )then
          !---------------------------------------------------------------!
          ! Large-scale pressure gradient based on geostropic balance,
          ! using base-state wind profiles:
          !---------------------------------------------------------------!
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj+1
          do i=1,ni
            ! 170728 bug fix:  account for grid staggering:
            ! 180618:  when imove=1, need to add umove to base state
            vten1(i,j,k) = vten1(i,j,k)+fcor*( 0.25*( (u0(i,j  ,k)+u0(i+1,j  ,k))   &
                                                     +(u0(i,j-1,k)+u0(i+1,j-1,k)) ) + umove )
          enddo
          enddo
          enddo
        elseif( lspgrad.eq.2 )then
          !---------------------------------------------------------------!
          ! Large-scale pressure gradient based on geostropic balance,
          ! using ug,vg arrays:
          !---------------------------------------------------------------!
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj+1
          do i=1,ni
            vten1(i,j,k) = vten1(i,j,k)+fcor*(ug(k)+umove)
          enddo
          enddo
          enddo
        endif
        if(timestats.ge.1) time_misc=time_misc+mytime()
      ENDIF


      if(idiff.ge.1)then
        if(difforder.eq.2)then
          call diff2v(xh,arh1,arh2,uh,rxf,arf1,arf2,uf,vh,vf,mh,mf,  &
                      dum1,dum2,dum3,dum4,vten1,ust,rho,rr,rf,divx,t22,t12,t23, &
                      dovbud,vdiag)
        endif
      endif

      if( dohturb .or. dovturb )then
        call turbv(dt,xh,rxh,arh1,arh2,uh,xf,rvh,vf,mh,mf,rho,rr,rf,   &
                   zs,gz,rgz,gzu,gzv,rds,sigma,rdsf,sigmaf,gyv,  &
                   dum1,dum2,dum3,dum4,dum5,dum6,va,vten1,wa,t12,t22,t23,kmv, &
                   dovbud,vdiag)
      endif

      if(ipbl.eq.1)then
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vten1(i,j,k) = vten1(i,j,k) + 0.5*( vpten(i,j-1,k)+ vpten(i,j,k))
        enddo
        enddo
        enddo
        IF( dovbud .and. vd_pbl.ge.1 )then
          !$omp parallel do default(shared)   &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj+1
          do i=1,ni
            vdiag(i,j,k,vd_pbl) = 0.5*( vpten(i,j-1,k)+ vpten(i,j,k))
          enddo
          enddo
          enddo
        ENDIF
        if(timestats.ge.1) time_pbl=time_pbl+mytime()
      endif
 
!--------------------------------------------------------------------
!  W-equation

      IF( irdamp.ge.1 .or. hrdamp.ge.1 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k,xs)
        do k=2,nk
        do j=1,nj
        do i=1,ni
          wten1(i,j,k) = -rdalpha*tauf(i,j,k)*wa(i,j,k)
!!!          ! forcing term from Nolan (2005, JAS):
!!!          xs = sqrt( ((zf(i,j,k)-3000.0)**2)/(2000.0**2) &
!!!                    +(xh(i)**2)/(1000.0**2) )
!!!          if( xs.lt.1.0 ) wten1(i,j,k)=wten1(i,j,k)+1.26*cos(0.5*pi*xs)
        enddo
        enddo
        enddo
      ELSE
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k,xs)
        do k=2,nk
        do j=1,nj
        do i=1,ni
          wten1(i,j,k) = 0.0
!!!          ! forcing term from Nolan (2005, JAS):
!!!          xs = sqrt( ((zf(i,j,k)-3000.0)**2)/(2000.0**2) &
!!!                    +(xh(i)**2)/(1000.0**2) )
!!!          if( xs.lt.1.0 ) wten1(i,j,k)=wten1(i,j,k)+1.26*cos(0.5*pi*xs)
        enddo
        enddo
        enddo
      ENDIF
      if( dowbud .and. wd_rdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk+1
        do j=1,nj
        do i=1,ni
          wdiag(i,j,k,wd_rdamp) = wten1(i,j,k)
        enddo
        enddo
        enddo
      endif
      if(timestats.ge.1) time_rdamp=time_rdamp+mytime()

      if(idiff.ge.1)then
        if(difforder.eq.2)then
          call diff2w(rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,mh,mf,  &
                      dum1,dum2,dum3,dum4,wten1,rho,rr,rf,divx,t33,t13,t23,  &
                      dowbud,wdiag)
        endif
      endif

      if( dohturb .or. dovturb )then
        call turbw(dt,xh,rxh,arh1,arh2,uh,xf,vh,mh,mf,rho,rf,gz,rgzu,rgzv,rds,sigma,   &
                   dum1,dum2,dum3,dum4,dum5,dum6,wa,wten1,t13,t23,t33,t22,kmh,  &
                   dowbud,wdiag)
      endif

!--------------------------------------------------------------------
!  Arrays for vimpl turbs:
!    NOTE:  do not change dum7,dum8 from here to RK loop

      if( doimpl.eq.1 .and. dovturb )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum7(i,j,k) = khv(i,j,k  )*mf(i,j,k  )*rf(i,j,k  )*mh(i,j,k)*rr(i,j,k)
          dum8(i,j,k) = khv(i,j,k+1)*mf(i,j,k+1)*rf(i,j,k+1)*mh(i,j,k)*rr(i,j,k)
        enddo
        enddo
        enddo
      endif

!--------------------------------------------------------------------
!  THETA-equation

      IF( irdamp.eq.1 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          thten1(i,j,k) = -rdalpha*taus(i,j,k)*tha(i,j,k)
        enddo
        enddo
        enddo
      ELSEIF( irdamp.eq.2 )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          thten1(i,j,k) = -rdalpha*taus(i,j,k)*((th0(i,j,k)-thavg(k))+tha(i,j,k))
        enddo
        enddo
        enddo
      ELSE
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          thten1(i,j,k) = 0.0
        enddo
        enddo
        enddo
      ENDIF
      if( dotbud .and. td_rdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          tdiag(i,j,k,td_rdamp) = thten1(i,j,k)
        enddo
        enddo
        enddo
      endif
      if(timestats.ge.1) time_rdamp=time_rdamp+mytime()

      if(idiff.eq.1)then
        if(difforder.eq.2)then
          call diff2s(rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,mh,mf,  &
                      dum1,dum2,dum3,dum4,tha,thten1,rho,rr,rf,  &
                      dotbud,ibdt,iedt,jbdt,jedt,kbdt,kedt,ntdiag,tdiag,td_hediff,td_vediff)
        endif
      endif

      !----- cvm (if needed) -----!

      IF( eqtset.eq.2 .and. imoist.eq.1 .and. (idiss.eq.1.or.rterm.eq.1) )THEN
        ! for energy-conserving moist thermodynamics:
        ! store cvm in dum1:
        ! store ql  in dum2:
        ! store qi  in dum3:
!$omp parallel do default(shared)  &
!$omp private(i,j,k,n)
        DO k=1,nk
          do j=1,nj
          do i=1,ni
            dum2(i,j,k)=qa(i,j,k,nql1)
          enddo
          enddo
          do n=nql1+1,nql2
            do j=1,nj
            do i=1,ni
              dum2(i,j,k)=dum2(i,j,k)+qa(i,j,k,n)
            enddo
            enddo
          enddo
          IF(iice.eq.1)THEN
            do j=1,nj
            do i=1,ni
              dum3(i,j,k)=qa(i,j,k,nqs1)
            enddo
            enddo
            do n=nqs1+1,nqs2
              do j=1,nj
              do i=1,ni
                dum3(i,j,k)=dum3(i,j,k)+qa(i,j,k,n)
              enddo
              enddo
            enddo
          ELSE
            do j=1,nj
            do i=1,ni
              dum3(i,j,k)=0.0
            enddo
            enddo
          ENDIF
          do j=1,nj
          do i=1,ni
            dum1(i,j,k)=cv+cvv*qa(i,j,k,nqv)+cpl*dum2(i,j,k)+cpi*dum3(i,j,k)
          enddo
          enddo
        ENDDO
      ELSE
!$omp parallel do default(shared)  &
!$omp private(i,j,k,n)
        DO k=1,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k)=cv
          enddo
          enddo
        ENDDO
      ENDIF

      !----- store appropriate rho for budget calculations in dum2 -----!

      IF(axisymm.eq.1)THEN
       ! for axisymmetric grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum2(i,j,k) = rho(i,j,k)*pi*(xf(i+1)**2-xf(i)**2)/(dx*dy)
        enddo
        enddo
        enddo
      ELSE
       ! for Cartesian grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          dum2(i,j,k) = rho(i,j,k)
        enddo
        enddo
        enddo
      ENDIF

      !-------------------------------------------------------------

      !  budget calculations:
      if(dosfcflx.and.imoist.eq.1)then
        tem0 = dt*dx*dy*dz
!$omp parallel do default(shared)  &
!$omp private(i,j,k,delpi,delth,delqv,delt,n)
        do j=1,nj
        bud2(j) = 0.0d0
        do i=1,ni
          k = 1
          delth = rf0(i,j,1)*rr0(i,j,1)*rdz*mh(i,j,1)*thflux(i,j)
          delqv = rf0(i,j,1)*rr0(i,j,1)*rdz*mh(i,j,1)*qvflux(i,j)
          delpi = rddcv*(pi0(i,j,1)+ppi(i,j,1))*(           &
                                delqv/(eps+qa(i,j,1,nqv))   &
                               +delth/(th0(i,j,1)+tha(i,j,1))  )
          delt = (pi0(i,j,k)+ppi(i,j,k))*delth   &
                +(th0(i,j,k)+tha(i,j,k))*delpi
          bud2(j) = bud2(j) + dum2(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)*(        &
                  cv*delt                                                   &
                + cvv*qa(i,j,k,nqv)*delt                                    &
                + cvv*(pi0(i,j,k)+ppi(i,j,k))*(th0(i,j,k)+tha(i,j,k))*delqv &
                + g*zh(i,j,k)*delqv   )
          do n=nql1,nql2
            bud2(j) = bud2(j) + dum2(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)*cpl*qa(i,j,k,n)*delt
          enddo
          if(iice.eq.1)then
            do n=nqs1,nqs2
              bud2(j) = bud2(j) + dum2(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)*cpi*qa(i,j,k,n)*delt
            enddo
          endif
        enddo
        enddo
        do j=1,nj
          qbudget(9) = qbudget(9) + tem0*bud2(j)
        enddo
        if(timestats.ge.1) time_misc=time_misc+mytime()
      endif

      !---- Dissipative heating term:

      IF(idiss.eq.1)THEN
        IF( dotbud .and. td_diss.ge.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_diss) = thten1(i,j,k)
          enddo
          enddo
          enddo
        ENDIF
        ! note:  dissten array stores epsilon (dissipation rate) at w points
        if( bbc.eq.3 )then
          k1 = 2
        else
          k1 = 1
        endif
        if(imoist.eq.1.and.eqtset.eq.2)then
          ! moist, new equations:
!$omp parallel do default(shared)  &
!$omp private(i,j,k,epsd,dheat)
          do k=k1,nk
          do j=1,nj
          do i=1,ni
            epsd = 0.5*(dissten(i,j,k)+dissten(i,j,k+1))
            dheat=epsd/( cpdcv*dum1(i,j,k)*(pi0(i,j,k)+ppi(i,j,k)) )
            thten1(i,j,k)=thten1(i,j,k)+dheat
          enddo
          enddo
          enddo
          if( bbc.eq.3 )then
            k = 1
!$omp parallel do default(shared)  &
!$omp private(i,j,dz1,epsd,dheat)
            do j=1,nj
            do i=1,ni
              dz1 = zf(i,j,2)-zf(i,j,1)
              epsd = (ust(i,j)**3)*alog((dz1+znt(i,j))/znt(i,j))/(karman*dz1)
              dheat=epsd/( cpdcv*dum1(i,j,k)*(pi0(i,j,k)+ppi(i,j,k)) )
              thten1(i,j,k)=thten1(i,j,k)+dheat
            enddo
            enddo
          endif
        else
          ! traditional cloud-modeling equations (also dry equations):
!$omp parallel do default(shared)  &
!$omp private(i,j,k,epsd,dheat)
          do k=k1,nk
          do j=1,nj
          do i=1,ni
            epsd = 0.5*(dissten(i,j,k)+dissten(i,j,k+1))
            dheat=epsd/( cp*(pi0(i,j,k)+ppi(i,j,k)) )
            thten1(i,j,k)=thten1(i,j,k)+dheat
          enddo
          enddo
          enddo
          if( bbc.eq.3 )then
            k = 1
!$omp parallel do default(shared)  &
!$omp private(i,j,dz1,epsd,dheat)
            do j=1,nj
            do i=1,ni
              dz1 = zf(i,j,2)-zf(i,j,1)
              epsd = (ust(i,j)**3)*alog((dz1+znt(i,j))/znt(i,j))/(karman*dz1)
              dheat=epsd/( cp*(pi0(i,j,k)+ppi(i,j,k)) )
              thten1(i,j,k)=thten1(i,j,k)+dheat
            enddo
            enddo
          endif
        endif
        IF( dotbud .and. td_diss.ge.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_diss) = thten1(i,j,k)-tdiag(i,j,k,td_diss)
          enddo
          enddo
          enddo
        ENDIF
      ENDIF

      !---- Rotunno-Emanuel "radiation" term
      !---- (currently capped at 2 K/day ... see RE87 p 546)

      IF(rterm.eq.1)THEN
        if( dotbud .and. td_rad.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_rad) = thten1(i,j,k)
          enddo
          enddo
          enddo
        endif
        tem0 = dt*dx*dy*dz
!$omp parallel do default(shared)  &
!$omp private(i,j,k,thrad,prad)
        do k=1,nk
        bud(k)=0.0d0
        do j=1,nj
        do i=1,ni
          ! NOTE:  thrad is a POTENTIAL TEMPERATURE tendency
          thrad = -tha(i,j,k)/(12.0*3600.0)
          if( tha(i,j,k).gt. 1.0 ) thrad = -1.0/(12.0*3600.0)
          if( tha(i,j,k).lt.-1.0 ) thrad =  1.0/(12.0*3600.0)
          thten1(i,j,k)=thten1(i,j,k)+thrad
          ! associated pressure tendency:
          prad = (pi0(i,j,k)+ppi(i,j,k))*rddcv*thrad/(th0(i,j,k)+tha(i,j,k))
          ! budget:
          bud(k) = bud(k) + dum1(i,j,k)*dum2(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)*( &
                            thrad*(pi0(i,j,k)+ppi(i,j,k))    &
                           + prad*(th0(i,j,k)+tha(i,j,k)) )
        enddo
        enddo
        enddo
        do k=1,nk
          qbudget(10) = qbudget(10) + tem0*bud(k)
        enddo
        if( dotbud .and. td_rad.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_rad) = thten1(i,j,k)-tdiag(i,j,k,td_rad)
          enddo
          enddo
          enddo
        endif
      ENDIF
      if(timestats.ge.1) time_misc=time_misc+mytime()

      IF( radopt.ge.1 )THEN
        ! Notes:
        ! use sadv to store total potential temperature:
        ! TEMPERATURE tendencies from radiation scheme
        ! are stored in lwten and swten

        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=0,nj+1
        do i=0,ni+1
          sadv(i,j,k)=th0(i,j,k)+tha(i,j,k)
        enddo
        enddo
        enddo

        if( dotbud .and. td_rad.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_rad) = thten1(i,j,k)
          enddo
          enddo
          enddo
        endif
        IF( eqtset.eq.1 )THEN
          ! traditional equation set:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ! cm1r17:  swten and lwten now store TEMPERATURE tendencies:
            thten1(i,j,k) = thten1(i,j,k) + (swten(i,j,k)+lwten(i,j,k))/(pi0(i,j,k)+ppi(i,j,k))
          enddo
          enddo
          enddo
        ELSEIF( eqtset.eq.2 )THEN
          ! Bryan-Fritsch equation set:
          rdt = 1.0/dt
!$omp parallel do default(shared)  &
!$omp private(i,j,k,tnew,pnew,thnew)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ! cm1r17:  swten and lwten now store TEMPERATURE tendencies:
            ! NOTE:  sadv stores theta (see above)
            tnew = sadv(i,j,k)*(pi0(i,j,k)+ppi(i,j,k)) + dt*(swten(i,j,k)+lwten(i,j,k))
            pnew = rho(i,j,k)*(rd+rv*qa(i,j,k,nqv))*tnew
            thnew = tnew/((pnew*rp00)**rovcp)
            thten1(i,j,k) = thten1(i,j,k) + (thnew-sadv(i,j,k))*rdt
          enddo
          enddo
          enddo
        ENDIF
        if( dotbud .and. td_rad.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_rad) = thten1(i,j,k)-tdiag(i,j,k,td_rad)
          enddo
          enddo
          enddo
        endif
        if(timestats.ge.1) time_rad=time_rad+mytime()
      ENDIF

      IF( ipbl.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          thten1(i,j,k) = thten1(i,j,k) + thpten(i,j,k)
        enddo
        enddo
        enddo
        if( dotbud .and. td_pbl.ge.1 )then
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            tdiag(i,j,k,td_pbl) = thpten(i,j,k)
          enddo
          enddo
          enddo
        endif
        if(timestats.ge.1) time_pbl=time_pbl+mytime()
      ENDIF

      if( dohturb .or. dovturb )then
        ! cm1r18: subtract th0r from theta (as in advection scheme)
        !         (reduces roundoff error)
        IF(.not.terrain_flag)THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k,tem)
          do k=1,nk
          tem = th0(1,1,k)-th0r
          do j=0,nj+1
          do i=0,ni+1
            sadv(i,j,k)=tem+tha(i,j,k)
          enddo
          enddo
          enddo
        ELSE
!$omp parallel do default(shared)  &
!$omp private(i,j,k,tem)
          do k=1,nk
          do j=0,nj+1
          do i=0,ni+1
            sadv(i,j,k)=(th0(i,j,k)-th0r)+tha(i,j,k)
          enddo
          enddo
          enddo
        ENDIF
        call turbs(1,dt,dosfcflx,xh,rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,thflux,   &
                   rds,sigma,rdsf,sigmaf,mh,mf,gz,rgz,gzu,rgzu,gzv,rgzv,gx,gxu,gy,gyv, &
                   dum1,dum2,dum3,dum4,dum5,sten,rho,rr,rf,sadv,thten1,khh,khv,dum7,dum8, &
                   dotbud,ibdt,iedt,jbdt,jedt,kbdt,kedt,ntdiag,tdiag,td_hturb,td_vturb)

      endif

!-------------------------------------------------------------------
!  Passive Tracers

      if(iptra.eq.1)then
        do n=1,npt
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ptten(i,j,k,n)=0.0
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_misc=time_misc+mytime()
          if(idiff.eq.1)then
            if(difforder.eq.2)then
              call diff2s(rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,mh,mf,  &
                          dum1,dum2,dum3,dum4,pta(ib,jb,kb,n),ptten(ib,jb,kb,n),rho,rr,rf,  &
                          .false.,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,1,1)
            endif
          endif
          if( dohturb .or. dovturb )then
            call turbs(0,dt,dosfcflx,xh,rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,qvflux,   &
                       rds,sigma,rdsf,sigmaf,mh,mf,gz,rgz,gzu,rgzu,gzv,rgzv,gx,gxu,gy,gyv, &
                       dum1,dum2,dum3,dum4,dum5,sten,rho,rr,rf,pta(ib,jb,kb,n),ptten(ib,jb,kb,n),khh,khv,dum7,dum8, &
                       .false.,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,1,1)
          endif
        enddo
      endif

!-------------------------------------------------------------------
!  Moisture

      if(imoist.eq.1)then
        DO n=1,numq
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            qten(i,j,k,n)=0.0
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_misc=time_misc+mytime()
!---------------------------
          ! qv:
          if(n.eq.nqv)then
            if(idiff.eq.1)then
              if(difforder.eq.2)then
                call diff2s(rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,mh,mf,  &
                            dum1,dum2,dum3,dum4,qa(ib,jb,kb,n),qten(ib,jb,kb,n),rho,rr,rf,  &
                            doqbud,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,qd_hediff,qd_vediff)
              endif
            endif
            if( dohturb .or. dovturb )then
              call turbs(1,dt,dosfcflx,xh,rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,qvflux,   &
                         rds,sigma,rdsf,sigmaf,mh,mf,gz,rgz,gzu,rgzu,gzv,rgzv,gx,gxu,gy,gyv, &
                         dum1,dum2,dum3,dum4,dum5,sten,rho,rr,rf,qa(ib,jb,kb,n),qten(ib,jb,kb,n),khh,khv,dum7,dum8, &
                         doqbud,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,qd_hturb,qd_vturb)
            endif
            if(ipbl.eq.1)then
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
              do k=1,nk
              do j=1,nj
              do i=1,ni
                qten(i,j,k,nqv) = qten(i,j,k,nqv) + qvpten(i,j,k)
              enddo
              enddo
              enddo
              if( doqbud .and. qd_pbl.ge.1 )then
                !$omp parallel do default(shared)   &
                !$omp private(i,j,k)
                do k=1,nk
                do j=1,nj
                do i=1,ni
                  qdiag(i,j,k,qd_pbl) = qvpten(i,j,k)
                enddo
                enddo
                enddo
              endif
              if(timestats.ge.1) time_pbl=time_pbl+mytime()
            endif
!---------------------------
          ! not qv:
          else
            if(idiff.eq.1)then
              if(difforder.eq.2)then
                call diff2s(rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,mh,mf,  &
                            dum1,dum2,dum3,dum4,qa(ib,jb,kb,n),qten(ib,jb,kb,n),rho,rr,rf,  &
                            .false.,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,1,1)
              endif
            endif
            if( dohturb .or. dovturb )then
              call turbs(0,dt,dosfcflx,xh,rxh,arh1,arh2,uh,xf,arf1,arf2,uf,vh,vf,qvflux,   &
                         rds,sigma,rdsf,sigmaf,mh,mf,gz,rgz,gzu,rgzu,gzv,rgzv,gx,gxu,gy,gyv, &
                         dum1,dum2,dum3,dum4,dum5,sten,rho,rr,rf,qa(ib,jb,kb,n),qten(ib,jb,kb,n),khh,khv,dum7,dum8, &
                         .false.,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,1,1)
            endif
          endif
!---------------------------
        ENDDO
        IF(ipbl.eq.1)THEN
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            if(nqc.ne.0)   &
            qten(i,j,k,nqc) = qten(i,j,k,nqc) + qcpten(i,j,k)
            if(nqi.ne.0)   &
            qten(i,j,k,nqi) = qten(i,j,k,nqi) + qipten(i,j,k)
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_pbl=time_pbl+mytime()
        ENDIF
      endif

!--------------------------------------------------------------------
!  TENDENCIES for pre-configured cases:
!    (new for cm1r19)

      IF( testcase.ge.1 )THEN

        call     testcase_simple_phys(mh,rho0,rr0,rf0,th0,u0,v0,     &
                   zh,zf,dum1,dum2,dum3,dum4,dum5,dum6,              &
                   ufrc,vfrc,thfrc,qvfrc,ug,vg,dvdr,                 &
                   uavg,vavg,thavg,qavg,cavg,                        &
                   ua,va,tha,qa,uten1,vten1,thten1,qten,             &
                   o30 ,zir,ruh,ruf,rvh,rvf)
        if(timestats.ge.1) time_misc=time_misc+mytime()

      ENDIF


!-------------------------------------------------------------------
!    NOTE:  now ok to change dum7,dum8
!-------------------------------------------------------------------
!  contribution to pressure tendency from potential temperature:
!  (for mass conservation)
!  plus, some other stuff:

      IF(eqtset.eq.1)THEN
        ! traditional cloud modeling:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          ppten(i,j,k)=0.0
        enddo
        enddo
        enddo
      ELSE
        ! mass-conserving pressure eqt:  different sections for moist/dry cases:
        rdt = 1.0/dt
        tem = 0.0001*tsmall
        IF(imoist.eq.1)THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k,tnew,pnew,pinew,thnew,qvnew)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            !-----
            ! cm1r17:
            ! note:  nothing in pre-RK section should modify rho
            IF( abs(dt*thten1(i,j,k)).gt.tem .or.  &
                abs(dt*qten(i,j,k,nqv)).gt.qsmall )THEN
              thnew = tha(i,j,k)+dt*thten1(i,j,k)
              qvnew = qa(i,j,k,nqv)+dt*qten(i,j,k,nqv)
              pinew = (rho(i,j,k)*(th0(i,j,k)+thnew)*(rd+rv*qvnew)*rp00)**rddcv - pi0(i,j,k)
              ppten(i,j,k) = (pinew-ppi(i,j,k))*rdt
            ELSE
              ppten(i,j,k) = 0.0
            ENDIF
            !-----
            ! use diabatic tendencies from last timestep as a good estimate:
            ppten(i,j,k)=ppten(i,j,k)+qpten(i,j,k)
            thten1(i,j,k)=thten1(i,j,k)+qtten(i,j,k)
            qten(i,j,k,nqv)=qten(i,j,k,nqv)+qvten(i,j,k)
            qten(i,j,k,nqc)=qten(i,j,k,nqc)+qcten(i,j,k)
          enddo
          enddo
          enddo
        ELSE
!$omp parallel do default(shared)  &
!$omp private(i,j,k,tnew,pnew,pinew,thnew,qvnew)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            !-----
            ! cm1r17:
            ! note:  nothing in pre-RK section should modify rho
            IF( abs(dt*thten1(i,j,k)).gt.tem )THEN
              thnew = tha(i,j,k)+dt*thten1(i,j,k)
              pinew = (rho(i,j,k)*(th0(i,j,k)+thnew)*rd*rp00)**rddcv - pi0(i,j,k)
              ppten(i,j,k) = (pinew-ppi(i,j,k))*rdt
            ELSE
              ppten(i,j,k)=0.0
            ENDIF
            !-----
          enddo
          enddo
          enddo
        ENDIF  ! endif for moist/dry
      ENDIF    ! endif for eqtset 1/2

        if(timestats.ge.1) time_integ=time_integ+mytime()

!--------------------------------------------------------------------


!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CC   Begin RK section   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      ! time at end of full timestep:
      rtime=sngl(mtime+dt)

!--------------------------------------------------------------------
! RK3 begin

      rkloop:  &
      DO NRK=1,nrkmax

        dttmp=dt/float(nrkmax+1-nrk)

!--------------------------------------------------------------------
        IF(nrk.ge.2)THEN
#ifdef MPI
          call comm_3u_end(u3d,uw31,uw32,ue31,ue32,   &
                               us31,us32,un31,un32,reqs_u)
          call comm_3v_end(v3d,vw31,vw32,ve31,ve32,   &
                               vs31,vs32,vn31,vn32,reqs_v)
          call comm_3w_end(w3d,ww31,ww32,we31,we32,   &
                               ws31,ws32,wn31,wn32,reqs_w)
#endif
          if(terrain_flag)then
            call bcwsfc(gz,dzdx,dzdy,u3d,v3d,w3d)
            call bc2d(w3d(ib,jb,1))
          endif
        ENDIF
!--------------------------------------------------------------------
!  Get rru,rrv,rrw,divx
!  (NOTE:  do not change these arrays until after small steps)

    IF(.not.terrain_flag)THEN
      ! without terrain:

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      DO k=1,nk
        do j=0,nj+1
        do i=0,ni+2
          rru(i,j,k)=rho0(1,1,k)*u3d(i,j,k)
        enddo
        enddo
        do j=0,nj+2
        do i=0,ni+1
          rrv(i,j,k)=rho0(1,1,k)*v3d(i,j,k)
        enddo
        enddo
        IF(k.eq.1)THEN
          do j=0,nj+1
          do i=0,ni+1
            rrw(i,j,   1) = 0.0
            rrw(i,j,nk+1) = 0.0
          enddo
          enddo
        ELSE
          do j=0,nj+1
          do i=0,ni+1
            rrw(i,j,k)=rf0(1,1,k)*w3d(i,j,k)
          enddo
          enddo
        ENDIF
      ENDDO

    ELSE
      ! with terrain:

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      DO k=1,nk
        do j=0,nj+1
        do i=0,ni+2
          rru(i,j,k)=0.5*(rho0(i-1,j,k)+rho0(i,j,k))*u3d(i,j,k)*rgzu(i,j)
        enddo
        enddo
        do j=0,nj+2
        do i=0,ni+1
          rrv(i,j,k)=0.5*(rho0(i,j-1,k)+rho0(i,j,k))*v3d(i,j,k)*rgzv(i,j)
        enddo
        enddo
      ENDDO

!$omp parallel do default(shared)  &
!$omp private(i,j,k,r1,r2)
      DO k=1,nk
        IF(k.eq.1)THEN
          do j=0,nj+1
          do i=0,ni+1
            rrw(i,j,   1) = 0.0
            rrw(i,j,nk+1) = 0.0
          enddo
          enddo
        ELSE
          r2 = (sigmaf(k)-sigma(k-1))*rds(k)
          r1 = 1.0-r2
          r1 = 0.5*r1
          r2 = 0.5*r2
          do j=0,nj+1
          do i=0,ni+1
            rrw(i,j,k)=rf0(i,j,k)*w3d(i,j,k)                              &
                      +( ( r2*(rru(i,j,k  )+rru(i+1,j,k  ))               &
                          +r1*(rru(i,j,k-1)+rru(i+1,j,k-1)) )*dzdx(i,j)   &
                        +( r2*(rrv(i,j,k  )+rrv(i,j+1,k  ))               &
                          +r1*(rrv(i,j,k-1)+rrv(i,j+1,k-1)) )*dzdy(i,j)   &
                       )*(sigmaf(k)-zt)*gz(i,j)*rzt
          enddo
          enddo
        ENDIF
      ENDDO

    ENDIF
    if(timestats.ge.1) time_advs=time_advs+mytime()

        IF(terrain_flag)THEN
          call bcw(rrw,0)
#ifdef MPI
          call comm_1w_start(rrw,ww1,ww2,we1,we2,   &
                                 ws1,ws2,wn1,wn2,reqs_w)
          call comm_1w_end(rrw,ww1,ww2,we1,we2,   &
                               ws1,ws2,wn1,wn2,reqs_w)
#endif
        ENDIF

      IF(.not.terrain_flag)THEN
        IF(axisymm.eq.0)THEN
          ! Cartesian without terrain:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=0,nj+1
          do i=0,ni+1
            divx(i,j,k)=( (rru(i+1,j,k)-rru(i,j,k))*rdx*uh(i)        &
                         +(rrv(i,j+1,k)-rrv(i,j,k))*rdy*vh(j) )      &
                         +(rrw(i,j,k+1)-rrw(i,j,k))*rdz*mh(1,1,k)
            if(abs(divx(i,j,k)).lt.smeps) divx(i,j,k)=0.0
          enddo
          enddo
          enddo
        ELSE
          ! axisymmetric:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=0,nj+1
          do i=0,ni+1
            divx(i,j,k)=(arh2(i)*rru(i+1,j,k)-arh1(i)*rru(i,j,k))*rdx*uh(i)   &
                       +(rrw(i,j,k+1)-rrw(i,j,k))*rdz*mh(1,1,k)
            if(abs(divx(i,j,k)).lt.smeps) divx(i,j,k)=0.0
          enddo
          enddo
          enddo
        ENDIF
      ELSE
          ! Cartesian with terrain:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=0,nj+1
          do i=0,ni+1
            divx(i,j,k)=( (rru(i+1,j,k)-rru(i,j,k))*rdx*uh(i)        &
                         +(rrv(i,j+1,k)-rrv(i,j,k))*rdy*vh(j) )      &
                         +(rrw(i,j,k+1)-rrw(i,j,k))*rdsf(k)
            if(abs(divx(i,j,k)).lt.smeps) divx(i,j,k)=0.0
          enddo
          enddo
          enddo
      ENDIF
      if(timestats.ge.1) time_divx=time_divx+mytime()

!--------------------------------------------------------------------
#ifdef MPI
        IF(nrk.ge.2)THEN
          call comm_1s_end(rho,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
          call getcorner(rho,nw1(1),nw2(1),ne1(1),ne2(1),sw1(1),sw2(1),se1(1),se2(1))
          call bcs2(rho)
        ENDIF
#endif
!--------------------------------------------------------------------
!  U-equation

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          uten(i,j,k)=uten1(i,j,k)
        enddo
        enddo
!          if( doubud .and. dotdwrite .and. nrk.eq.nrkmax )then
!            ! save u for rtke calculation:
!            ! cm1r19.6 ... broken ... fix later
!            do j=jb,je
!            do i=ib,ie+1
!              uten1(i,j,k) = u3d(i,j,k)
!            enddo
!            enddo
!          endif
        enddo
        if(timestats.ge.1) time_misc=time_misc+mytime()


        if( nudgeobc.eq.1 .and. wbc.eq.2 .and. ibw.eq.1 )then
          ! 190315: nudge inflow point back towards base state:
          tem = 1.0/alphobc
          do k=1,nk
          do j=1,nj
            if( u3d(1,j,k).gt.0.0 )then
              uten(1,j,k) = uten(1,j,k)-(u3d(1,j,k)-u0(1,j,k))*tem
            endif
          enddo
          enddo
        endif
        if( nudgeobc.eq.1 .and. ebc.eq.2 .and. ibe.eq.1 )then
          ! 190315: nudge inflow point back towards base state:
          tem = 1.0/alphobc
          do k=1,nk
          do j=1,nj
            if( u3d(ni+1,j,k).lt.0.0 )then
              uten(ni+1,j,k) = uten(ni+1,j,k)-(u3d(ni+1,j,k)-u0(ni+1,j,k))*tem
            endif
          enddo
          enddo
        endif


        ! Coriolis acceleration:
        if( icor.eq.1 )then
          IF( doubud .and. nrk.eq.nrkmax )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni+1
              udiag(i,j,k,ud_cor) = uten(i,j,k)
            enddo
            enddo
            enddo
          ENDIF
        tem = fcor*0.25
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
          IF(axisymm.eq.0)THEN
            ! for Cartesian grid:
          if( betaplane.eq.0 )then
            ! f plane:
            do j=1,nj
            do i=1,ni+1
              uten(i,j,k)=uten(i,j,k)+fcor*( 0.25*( (v3d(i  ,j,k)+v3d(i  ,j+1,k)) &
                                                   +(v3d(i-1,j,k)+v3d(i-1,j+1,k)) ) + vmove )
            enddo
            enddo
          elseif( betaplane.eq.1 )then
            ! beta plane:
            do j=1,nj
            do i=1,ni+1
              uten(i,j,k)=uten(i,j,k)+0.125*(f2d(i,j)+f2d(i-1,j))           &
                                           *( (v3d(i  ,j,k)+v3d(i  ,j+1,k)) &
                                             +(v3d(i-1,j,k)+v3d(i-1,j+1,k)) )
            enddo
            enddo
          endif
          ELSE
            ! for axisymmetric grid:
            do j=1,nj
            do i=2,ni+1
              uten(i,j,k)=uten(i,j,k)+fcor*0.5*(v3d(i,j,k)+v3d(i-1,j,k))
            enddo
            enddo
          ENDIF
        enddo
          IF( doubud .and. nrk.eq.nrkmax )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni+1
              udiag(i,j,k,ud_cor) = uten(i,j,k)-udiag(i,j,k,ud_cor)
            enddo
            enddo
            enddo
          ENDIF
          if(timestats.ge.1) time_cor=time_cor+mytime()
        endif


        ! inertial term for axisymmetric grid:
        if(axisymm.eq.1)then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
            do i=1,ni+1
              dum1(i,j,k)=(v3d(i,j,k)**2)*rxh(i)
            enddo
            if(ebc.eq.3)then
              dum1(ni+1,j,k) = -dum1(ni,j,k)
            endif
            do i=2,ni+1
              uten(i,j,k)=uten(i,j,k)+0.5*(dum1(i-1,j,k)+dum1(i,j,k))
            enddo
          enddo
          enddo
          IF( doubud .and. nrk.eq.nrkmax )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=2,ni+1
              udiag(i,j,k,ud_cent) = 0.5*(dum1(i-1,j,k)+dum1(i,j,k))
            enddo
            enddo
            enddo
          ENDIF
        endif


          call advu(nrk   ,arh1,arh2,uh,xf,rxf,arf1,arf2,uf,vh,gz,rgz,gzu,mh,rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,divx, &
                     rru,u3d,uten,rrv,rrw,rdsf,c1,c2,rho,dttmp,doubud,udiag,wprof)

!--------------------------------------------------------------------
!  V-equation
 
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj+1
        do i=1,ni
          vten(i,j,k)=vten1(i,j,k)
        enddo
        enddo
!          if( dovbud .and. dotdwrite .and. nrk.eq.nrkmax )then
!            ! save v for rtke calculation:
!            ! cm1r19.6 ... broken ... fix later
!            do j=jb,je+1
!            do i=ib,ie
!              vten1(i,j,k) = v3d(i,j,k)
!            enddo
!            enddo
!          endif
        enddo
        if(timestats.ge.1) time_misc=time_misc+mytime()


        if( nudgeobc.eq.1 .and. sbc.eq.2 .and. ibs.eq.1 )then
          ! 190315: nudge inflow point back towards base state:
          tem = 1.0/alphobc
          do k=1,nk
          do i=1,ni
            if( v3d(i,1,k).gt.0.0 )then
              vten(i,1,k) = vten(i,1,k)-(v3d(i,1,k)-v0(i,1,k))*tem
            endif
          enddo
          enddo
        endif
        if( nudgeobc.eq.1 .and. nbc.eq.2 .and. ibn.eq.1 )then
          ! 190315: nudge inflow point back towards base state:
          tem = 1.0/alphobc
          do k=1,nk
          do i=1,ni
            if( v3d(i,nj+1,k).lt.0.0 )then
              vten(i,nj+1,k) = vten(i,nj+1,k)-(v3d(i,nj+1,k)-v0(i,nj+1,k))*tem
            endif
          enddo
          enddo
        endif


        ! Coriolis acceleration:
        ! note for axisymmetric grid: since cm1r18, this term is included in advvaxi
        if( icor.eq.1 .and. axisymm.eq.0 )then
          IF( dovbud .and. nrk.eq.nrkmax )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj+1
            do i=1,ni
              vdiag(i,j,k,vd_cor) = vten(i,j,k)
            enddo
            enddo
            enddo
          ENDIF
        tem = fcor*0.25
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk

            ! for Cartesian grid:
          if( betaplane.eq.0 )then
            ! f plane:
            do j=1,nj+1
            do i=1,ni
              vten(i,j,k)=vten(i,j,k)-fcor*( 0.25*( (u3d(i,j  ,k)+u3d(i+1,j  ,k)) &
                                                   +(u3d(i,j-1,k)+u3d(i+1,j-1,k)) ) + umove )
            enddo
            enddo
          elseif( betaplane.eq.1 )then
            ! beta plane:
            do j=1,nj+1
            do i=1,ni
              vten(i,j,k)=vten(i,j,k)-0.125*(f2d(i,j)+f2d(i,j-1))           &
                                           *( (u3d(i,j  ,k)+u3d(i+1,j  ,k)) &
                                             +(u3d(i,j-1,k)+u3d(i+1,j-1,k)) )
            enddo
            enddo
          endif
        enddo
          IF( dovbud .and. nrk.eq.nrkmax )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj+1
            do i=1,ni
              vdiag(i,j,k,vd_cor) = vten(i,j,k)-vdiag(i,j,k,vd_cor)
            enddo
            enddo
            enddo
          ENDIF
        if(timestats.ge.1) time_cor=time_cor+mytime()
        endif


!!!        ! since cm1r17, this term is included in advvaxi
!!!        if(axisymm.eq.1)then
!!!          ! for axisymmetric grid:
!!!
!!!!$omp parallel do default(shared)  &
!!!!$omp private(i,j,k)
!!!          do k=1,nk
!!!          do j=1,nj
!!!          do i=1,ni
!!!            vten(i,j,k)=vten(i,j,k)-(v3d(i,j,k)*rxh(i))*0.5*(xf(i)*u3d(i,j,k)+xf(i+1)*u3d(i+1,j,k))*rxh(i)
!!!          enddo
!!!          enddo
!!!          enddo
!!!
!!!        endif


          call advv(nrk   ,xh,rxh,arh1,arh2,uh,xf,vh,vf,gz,rgz,gzv,mh,rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,divx, &
                     rru,rrv,v3d,vten,rrw,rdsf,c1,c2,rho,dttmp,dovbud,vdiag,wprof)


        IF( dovbud )THEN
        IF( axisymm.eq.1 .and. nrk.eq.nrkmax )THEN
          !  Diagnostics for axisymm:
!$omp parallel do default(shared)  &
!$omp private(i,j,k,tem1,tem2)
          do k=1,nk
          do j=1,1
          do i=1,ni
            ! estimate Coriolis:
            tem1 = -fcor*0.5*(xf(i)*u3d(i,j,k)+xf(i+1)*u3d(i+1,j,k))*rxh(i)
            ! estimate centrifugal accel:
            tem2 = -(v3d(i,j,k)*rxh(i))*0.5*(xf(i)*u3d(i,j,k)+xf(i+1)*u3d(i+1,j,k))*rxh(i)

            vdiag(i,j,k,vd_cor)  = tem1
            vdiag(i,j,k,vd_cent) = tem2
            vdiag(i,j,k,vd_hadv) = vdiag(i,j,k,vd_hadv) - tem1 - tem2

            vdiag(i,2,k,vd_cor)  = vdiag(i,1,k,vd_cor)
            vdiag(i,2,k,vd_cent) = vdiag(i,1,k,vd_cent)
            vdiag(i,2,k,vd_hadv) = vdiag(i,1,k,vd_hadv)
          enddo
          enddo
          enddo
        ENDIF
        ENDIF


!--------------------------------------------------------------------
!  Calculate misc. variables
!
!    These arrays store variables that are used later in the
!    SOUND subroutine.  Do not modify t11 or t22 until after sound!
!
!    dum1 = vapor
!    dum2 = all liquid
!    dum3 = all solid
!    t11 = theta_rho
!    t22 = ppterm

        IF(imoist.eq.1)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n,cpm,cvm)
          do k=1,nk

            do j=1,nj
            do i=1,ni
              dum2(i,j,k)=q3d(i,j,k,nql1)
            enddo
            enddo
            do n=nql1+1,nql2
              do j=1,nj
              do i=1,ni
                dum2(i,j,k)=dum2(i,j,k)+q3d(i,j,k,n)
              enddo
              enddo
            enddo
            IF(iice.eq.1)THEN
              do j=1,nj
              do i=1,ni
                dum3(i,j,k)=q3d(i,j,k,nqs1)
              enddo
              enddo
              do n=nqs1+1,nqs2
                do j=1,nj
                do i=1,ni
                  dum3(i,j,k)=dum3(i,j,k)+q3d(i,j,k,n)
                enddo
                enddo
              enddo
            ELSE
              do j=1,nj
              do i=1,ni
                dum3(i,j,k)=0.0
              enddo
              enddo
            ENDIF
            ! save qv,ql,qi for buoyancy calculation:
          IF(eqtset.eq.2)THEN
            do j=1,nj
            do i=1,ni
              t12(i,j,k)=max(q3d(i,j,k,nqv),0.0)
              t13(i,j,k)=max(0.0,dum2(i,j,k)+dum3(i,j,k))
              t11(i,j,k)=(th0(i,j,k)+th3d(i,j,k))*(1.0+reps*t12(i,j,k))     &
                         /(1.0+t12(i,j,k)+t13(i,j,k))
      ! terms in theta and pi equations for proper mass/energy conservation
      ! Reference:  Bryan and Fritsch (2002, MWR), Bryan and Morrison (2012, MWR)
              dum4(i,j,k)=cpl*max(0.0,dum2(i,j,k))+cpi*max(0.0,dum3(i,j,k))
              cpm=cp+cpv*t12(i,j,k)+dum4(i,j,k)
              cvm=1.0/(cv+cvv*t12(i,j,k)+dum4(i,j,k))
              thterm(i,j,k)=(th0(i,j,k)+th3d(i,j,k))*( rd+rv*t12(i,j,k)-rovcp*cpm )*cvm
              t22(i,j,k)=(pi0(i,j,k)+pp3d(i,j,k))*rovcp*cpm*cvm
            enddo
            enddo
          ELSEIF(eqtset.eq.1)THEN
            do j=1,nj
            do i=1,ni
              t12(i,j,k)=max(q3d(i,j,k,nqv),0.0)
              t13(i,j,k)=max(0.0,dum2(i,j,k)+dum3(i,j,k))
              t11(i,j,k)=(th0(i,j,k)+th3d(i,j,k))*(1.0+reps*t12(i,j,k))     &
                         /(1.0+t12(i,j,k)+t13(i,j,k))
              t22(i,j,k)=(pi0(i,j,k)+pp3d(i,j,k))*rddcv
            enddo
            enddo
          ENDIF

          enddo

        ELSE

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            t11(i,j,k)=th0(i,j,k)+th3d(i,j,k)
            t22(i,j,k)=(pi0(i,j,k)+pp3d(i,j,k))*rddcv
          enddo
          enddo
          enddo

        ENDIF

        if(timestats.ge.1) time_buoyan=time_buoyan+mytime()

!--------------------------------------------------------------------
        call bcs(t11)
#ifdef MPI
        call comm_1s_start(t11,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
#endif
!--------------------------------------------------------------------
!  W-equation

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk+1
        do j=1,nj
        do i=1,ni
          wten(i,j,k)=wten1(i,j,k)
        enddo
        enddo
!          if( dowbud .and. dotdwrite .and. nrk.eq.nrkmax )then
!            ! save w for rtke calculation:
!            ! cm1r19.6 ... broken ... fix later
!            do j=jb,je
!            do i=ib,ie
!              wten1(i,j,k) = w3d(i,j,k)
!            enddo
!            enddo
!          endif
        enddo
        if(timestats.ge.1) time_misc=time_misc+mytime()

          call   advw(nrk   ,xh,rxh,arh1,arh2,uh,xf,vh,gz,rgz,mh,mf,rho0,rr0,rf0,rrf0,  &
                      dum1,dum2,dum3,dum4,dum5,dum6,dum7,divx,                       &
                      rru,rrv,rrw,w3d  ,wten,rds,rdsf,c1,c2,rho,dttmp,               &
                      dowbud ,wdiag,hadvordrv,vadvordrv,advwenov)

!--------------------------------------------------------------------
!  Buoyancy

        ! dum6 stores buoyancy at s pts:
 
        if( imoist.eq.1 )then
          ! buoyancy (with moisture terms):
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do j=1,nj
            do k=1,nk
            do i=1,ni
              dum6(i,j,k) = g*( th3d(i,j,k)*rth0(i,j,k) + repsm1*(t12(i,j,k)-qv0(i,j,k)) - (t13(i,j,k)-qc0(i,j,k)-qi0(i,j,k)) )
            enddo
            enddo
            do k=2,nk
            do i=1,ni
              wten(i,j,k)=wten(i,j,k)+(c1(i,j,k)*dum6(i,j,k-1)+c2(i,j,k)*dum6(i,j,k))
            enddo
            enddo
          enddo
        else
          ! buoyancy (dry):
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do j=1,nj
            do k=1,nk
            do i=1,ni
              dum6(i,j,k) = g*th3d(i,j,k)*rth0(i,j,k)
            enddo
            enddo
            do k=2,nk
            do i=1,ni
              wten(i,j,k)=wten(i,j,k)+(c1(i,j,k)*dum6(i,j,k-1)+c2(i,j,k)*dum6(i,j,k))
            enddo
            enddo
          enddo
        endif
        if( dowbud .and. nrk.eq.nrkmax )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=2,nk
          do j=1,nj
          do i=1,ni
            wdiag(i,j,k,wd_buoy) = (c1(i,j,k)*dum6(i,j,k-1)+c2(i,j,k)*dum6(i,j,k))
          enddo
          enddo
          enddo
        endif

        if(timestats.ge.1) time_buoyan=time_buoyan+mytime()

!--------------------------------------------------------------------

        IF( (doubud.or.dovbud.or.dowbud) .and. nrk.eq.nrkmax )THEN
          ! bug fix, 170725
          ! save velocity tendencies before pgrad calculations:
          if( ud_pgrad.ge.1 )then
            !$omp parallel do default(shared)   &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj+1
            do i=1,ni+1
              udiag(i,j,k,ud_pgrad) = uten(i,j,k)
            enddo
            enddo
            enddo
          endif
          if( vd_pgrad.ge.1 )then
            !$omp parallel do default(shared)   &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj+1
            do i=1,ni+1
              vdiag(i,j,k,vd_pgrad) = vten(i,j,k)
            enddo
            enddo
            enddo
          endif
          if( wd_pgrad.ge.1 )then
            !$omp parallel do default(shared)   &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj+1
            do i=1,ni+1
              wdiag(i,j,k,wd_pgrad) = wten(i,j,k)
            enddo
            enddo
            enddo
          endif
          if(timestats.ge.1) time_misc=time_misc+mytime()
        ENDIF

!--------------------------------------------------------------------
!  cm1r19 terrain modification:
!  note:  this is part of horiz pressure gradient

        ! dum6 stores buoyancy:

      termod1:  &
      IF( terrain_flag )THEN

        call bcs(dum6)
#ifdef MPI
        call comm_1s_start(dum6,zw1,zw2,ze1,ze2,zs1,zs2,zn1,zn2,reqs_z)
        call comm_1s_end(  dum6,zw1,zw2,ze1,ze2,zs1,zs2,zn1,zn2,reqs_z)
#endif

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
        do j=0,nj+1
          do k=2,nk
          do i=0,ni+1
            dum1(i,j,k) = c1(i,j,k)*dum6(i,j,k-1)+c2(i,j,k)*dum6(i,j,k)
          enddo
          enddo
          do i=0,ni+1
            dum1(i,j,1) = 0.0
            dum1(i,j,nk+1) = 0.0
          enddo
        enddo

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
        do k=1,nk
          ! x-dir
          do j=1,nj
          do i=1+ibw,ni+1-ibe
            uten(i,j,k) = uten(i,j,k) + ( 0.125*( (dum1(i,j,k+1)+dum1(i-1,j,k+1))    &
                                                 +(dum1(i,j,k  )+dum1(i-1,j,k  )) )  &
                                          -0.25*(dum6(i,j,k)+dum6(i-1,j,k))          &
                                        )*(gxu(i,j,k)+gxu(i,j,k+1))
          enddo
          enddo
          ! y-dir
          do j=1+ibs,nj+1-ibn
          do i=1,ni
            vten(i,j,k) = vten(i,j,k) + ( 0.125*( (dum1(i,j,k+1)+dum1(i,j-1,k+1))    &
                                                 +(dum1(i,j,k  )+dum1(i,j-1,k  )) )  &
                                          -0.25*(dum6(i,j,k)+dum6(i,j-1,k))          &
                                        )*(gyv(i,j,k)+gyv(i,j,k+1))
          enddo
          enddo
        enddo

      ENDIF  termod1

!--------------------------------------------------------------------
!  Pressure equation

#ifdef MPI
      IF(nrk.ge.2)THEN
        call comm_1s_end(pp3d,vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,reqs_x)
      ENDIF
#endif

      IF( psolver.le.3 )THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k,tem)
      do k=1,nk
        IF(.not.terrain_flag)THEN
          tem = pi0(1,1,k)
          do j=0,nj+1
          do i=0,ni+1
            sadv(i,j,k)=tem+pp3d(i,j,k)
          enddo
          enddo
        ELSE
          do j=0,nj+1
          do i=0,ni+1
            sadv(i,j,k)=pi0(i,j,k)+pp3d(i,j,k)
          enddo
          enddo
        ENDIF
        IF( psolver.eq.1 )THEN
          do j=1,nj
          do i=1,ni
            sten(i,j,k)=ppten(i,j,k)
          enddo
          enddo
        ENDIF
      enddo
      if(timestats.ge.1) time_misc=time_misc+mytime()

      if( psolver.eq.1 )then
        weps = epsilon
        diffit = 0
        call advs(nrk,0,0,bfoo,xh,rxh,arh1,arh2,uh,ruh,xf,vh,rvh,gz,rgz,mh,rmh,           &
                   rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,        &
                   rru,rrv,rrw,ppi,sadv,sten ,0,0,dttmp,weps,                             &
                   flag,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,rdsf,c1,c2,rho,rr,diffit, &
                   .false.,ibdt,iedt,jbdt,jedt,kbdt,kedt,ntdiag,tdiag,1,1,1,              &
                   1,1,1,wprof,dumk1,dumk2,2,2)
      endif

      ENDIF

!--------------------------------------------------------------------
#ifdef MPI
        call comm_1s_end(  t11,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
#endif
!--------------------------------------------------------------------
!  call sound

        get_time_avg = .false.


        IF(psolver.eq.1)THEN

          call   soundns(xh,rxh,arh1,arh2,uh,xf,uf,yh,vh,yf,vf,           &
                         zh,mh,c1,c2,mf,zf,pi0,thv0,rr0,rf0,              &
                         rds,sigma,rdsf,sigmaf,                           &
                         zs,gz,rgz,gzu,rgzu,gzv,rgzv,                     &
                         dzdx,dzdy,gx,gxu,gy,gyv,                         &
                         radbcw,radbce,radbcs,radbcn,                     &
                         dum1,dum2,dum3,dum4,                             &
                         u0,ua,u3d,uten,                                  &
                         v0,va,v3d,vten,                                  &
                         wa,w3d,wten,                                     &
                         ppi,pp3d,sten ,t11,   t22,dttmp,nrk,rtime,mtime)

        ELSEIF(psolver.eq.2)THEN

          get_time_avg = .true.
          call   sounde(dt,xh,arh1,arh2,uh,ruh,xf,uf,yh,vh,rvh,yf,vf,     &
                        rds,sigma,rdsf,sigmaf,zh,mh,rmh,c1,c2,mf,zf,      &
                        pi0,rho0,rr0,rf0,rrf0,th0,rth0,zs,                &
                        gz,rgz,gzu,rgzu,gzv,rgzv,                         &
                        dzdx,dzdy,gx,gxu,gy,gyv,                          &
                        radbcw,radbce,radbcs,radbcn,                      &
                        dum1,dum2,dum3,dum4,dum5,dum6,                    &
                        dum7,dum8,t12,t13,t23,t33,                        &
                        u0,rru,ua,u3d,uten,                               &
                        v0,rrv,va,v3d,vten,                               &
                        rrw,wa,w3d,wten,                                  &
                        ppi,pp3d,sadv ,ppten,ppx,                         &
                        t11,t22   ,nrk,dttmp,rtime,mtime,get_time_avg,    &
                        pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_p)

        ELSEIF(psolver.eq.3)THEN

          get_time_avg = .true.
          call   sound( dt,xh,arh1,arh2,uh,ruh,xf,uf,yh,vh,rvh,yf,vf,     &
                        rds,sigma,rdsf,sigmaf,zh,mh,rmh,c1,c2,mf,zf,      &
                        pi0,rho0,rr0,rf0,rrf0,th0,rth0,zs,                &
                        gz,rgz,gzu,rgzu,gzv,rgzv,                         &
                        dzdx,dzdy,gx,gxu,gy,gyv,                          &
                        radbcw,radbce,radbcs,radbcn,                      &
                        dum1,dum2,dum3,dum4,dum5,dum6,                    &
                        dum7,dum8,t12,t13,t23,                            &
                        u0,rru,ua,u3d,uten,                               &
                        v0,rrv,va,v3d,vten,                               &
                        rrw,wa,w3d,wten,                                  &
                        ppi,pp3d,sadv ,ppten,ppx,                         &
                        t11,t22   ,nrk,dttmp,rtime,mtime,get_time_avg,    &
                        pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_p)

        ELSEIF(psolver.eq.4.or.psolver.eq.5)THEN
          ! anelastic/incompressible solver:

          call   anelp(xh,uh,ruh,xf,uf,yh,vh,rvh,yf,vf,             &
                       zh,mh,rmh,mf,rmf,zf,pi0,thv0,rho0,prs0,rf0,  &
                       rds,sigma,rdsf,sigmaf,                       &
                       gz,rgz,gzu,rgzu,gzv,rgzv,                    &
                       dzdx,dzdy,gx,gxu,gy,gyv,                     &
                       radbcw,radbce,radbcs,radbcn,                 &
                       dum1,dum2,dum3,dum4,divx,                    &
                       u0,ua,u3d,uten,                              &
                       v0,va,v3d,vten,                              &
                       wa,w3d,wten,                                 &
                       ppi,pp3d,phi1,phi2,cfb,cfa,cfc,              &
                       ad1,ad2,pdt,lgbth,lgbph,rhs,trans,dttmp,nrk,rtime,mtime)

        ELSEIF(psolver.eq.6)THEN

          get_time_avg = .true.
          call   soundcb(dt,xh,arh1,arh2,uh,ruh,xf,uf,yh,vh,rvh,yf,vf,    &
                        rds,sigma,rdsf,sigmaf,zh,mh,rmh,c1,c2,mf,zf,      &
                        pi0,rho0,rr0,rf0,rrf0,th0,rth0,zs,                &
                        gz,rgz,gzu,rgzu,gzv,rgzv,                         &
                        dzdx,dzdy,gx,gxu,gy,gyv,                          &
                        radbcw,radbce,radbcs,radbcn,                      &
                        dum1,dum2,dum3,dum4,dum5,dum6,                    &
                        dum7,dum8,t12,t13,t23,t33,                        &
                        u0,rru,ua,u3d,uten,                               &
                        v0,rrv,va,v3d,vten,                               &
                        rrw,wa,w3d,wten,                                  &
                        ppi,pp3d,sadv ,ppten,ppx,phi1,phi2,               &
                        t11,t22   ,nrk,dttmp,rtime,mtime,get_time_avg,    &
                        pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_p)

        ENDIF


!--------------------------------------------------------------------
!  Update v for axisymmetric model simulations:

        IF(axisymm.eq.1)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            v3d(i,j,k)=va(i,j,k)+dttmp*vten(i,j,k)
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_misc=time_misc+mytime()

        ENDIF

!--------------------------------------------------------------------
!  Diagnostics:

      IF( doubud .and. nrk.eq.nrkmax )THEN
        ! pressure gradient accel:
        rdt = 1.0/dt
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni+1
          udiag(i,j,k,ud_pgrad) = (u3d(i,j,k)-ua(i,j,k))*rdt - udiag(i,j,k,ud_pgrad)
        enddo
        enddo
        enddo
      ENDIF

      IF( dovbud .and. nrk.eq.nrkmax )THEN
        rdt = 1.0/dt
        IF( axisymm.eq.1 )THEN
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,2
          do i=1,ni
            ! pressure gradient accel:
            vdiag(i,j,k,vd_pgrad) = 0.0
          enddo
          enddo
          enddo
        ELSE
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj+1
          do i=1,ni
            ! pressure gradient accel:
            vdiag(i,j,k,vd_pgrad) = (v3d(i,j,k)-va(i,j,k))*rdt - vdiag(i,j,k,vd_pgrad)
          enddo
          enddo
          enddo
        ENDIF
      ENDIF

      IF( dowbud .and. nrk.eq.nrkmax )THEN
        ! pressure gradient accel:
        rdt = 1.0/dt
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=2,nk
        do j=1,nj
        do i=1,ni
          wdiag(i,j,k,wd_pgrad) = (w3d(i,j,k)-wa(i,j,k))*rdt - wdiag(i,j,k,wd_pgrad)
        enddo
        enddo
        enddo
      ENDIF

!--------------------------------------------------------------------

        IF( nrk.eq.nrkmax )THEN
          call calccflquick(dt,uh,vh,mh,u3d,v3d,w3d)
        ENDIF

!--------------------------------------------------------------------
!  radbc

        if(irbc.eq.4)then

          if(ibw.eq.1 .or. ibe.eq.1)then
            call radbcew4(ruf,radbcw,radbce,ua,u3d,dttmp)
          endif

          if(ibs.eq.1 .or. ibn.eq.1)then
            call radbcns4(rvf,radbcs,radbcn,va,v3d,dttmp)
          endif

        endif

!--------------------------------------------------------------------
!  For Bryan-Fritsch equation set, compute 3d divergence.
!     Store in T11 array.

    IF( imoist.eq.1 .and. eqtset.eq.2 )THEN
      if( get_time_avg )then
        ! cm1r19:  rru,rrv,rrw store small-step-avg velocities
        call     getdiv(arh1,arh2,uh,vh,mh,rru,rrv,rrw,dum1,dum2,dum3,t11,  &
                        rds,rdsf,sigma,sigmaf,gz,rgzu,rgzv,dzdx,dzdy)
      else
        call     getdiv(arh1,arh2,uh,vh,mh,u3d,v3d,w3d,dum1,dum2,dum3,t11,  &
                        rds,rdsf,sigma,sigmaf,gz,rgzu,rgzv,dzdx,dzdy)
      endif
    ENDIF

!--------------------------------------------------------------------

      if( iprcl.eq.1 .and. nrk.eq.nrkmax )then
        ! save time-averaged velocities for parcel driver:
        do k=1,nk+1
        do j=1,nj+1
        do i=1,ni+1
          uten1(i,j,k) = rru(i,j,k)
          vten1(i,j,k) = rrv(i,j,k)
          wten1(i,j,k) = rrw(i,j,k)
        enddo
        enddo
        enddo
      endif

      if( get_time_avg )then
        ! cm1r19:  rru,rrv,rrw store small-step-avg velocities
        call     getdivx(arh1,arh2,uh,vh,mh,rho0,rf0,rru,rrv,rrw,divx,  &
                         rds,rdsf,sigma,sigmaf,gz,rgzu,rgzv,dzdx,dzdy)
      endif

!--------------------------------------------------------------------
!  THETA-equation

#ifdef MPI
        IF(nrk.ge.2)THEN
          call comm_3s_end(th3d,rw31,rw32,re31,re32,   &
                                rs31,rs32,rn31,rn32,reqs_y)
        ENDIF
#endif

!$omp parallel do default(shared)   &
!$omp private(i,j,k,tem)
      do k=1,nk
        IF( imoist.eq.1 .and. eqtset.eq.2 )THEN
          ! t11 stores 3d divergence
          do j=1,nj
          do i=1,ni
            thten(i,j,k)=thten1(i,j,k)-t11(i,j,k)*thterm(i,j,k)
          enddo
          enddo
          if( dotbud .and. td_div.ge.1 )then
            do j=1,nj
            do i=1,ni
              tdiag(i,j,k,td_div) = -t11(i,j,k)*thterm(i,j,k)
            enddo
            enddo
          endif
        ELSE
          do j=1,nj
          do i=1,ni
            thten(i,j,k)=thten1(i,j,k)
          enddo
          enddo
        ENDIF
        IF(.not.terrain_flag)THEN
          tem = th0(1,1,k)-th0r
          do j=jb,je
          do i=ib,ie
            sadv(i,j,k)=tem+th3d(i,j,k)
          enddo
          enddo
        ELSE
          do j=jb,je
          do i=ib,ie
            sadv(i,j,k)=(th0(i,j,k)-th0r)+th3d(i,j,k)
          enddo
          enddo
        ENDIF
      enddo
      if(timestats.ge.1) time_misc=time_misc+mytime()


        weps = 10.0*epsilon
        diffit = 0
        if( idiff.eq.1 .and. difforder.eq.6 ) diffit = 1
        call advs(nrk,1,0,bfoo,xh,rxh,arh1,arh2,uh,ruh,xf,vh,rvh,gz,rgz,mh,rmh,           &
                   rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,        &
                   rru,rrv,rrw,tha,sadv,thten,0,0,dttmp,weps,                             &
                   flag,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,rdsf,c1,c2,rho,rr,diffit, &
                   dotbud,ibdt,iedt,jbdt,jedt,kbdt,kedt,ntdiag,tdiag,td_hadv,td_vadv,td_subs, &
                   td_hidiff,td_vidiff,td_hediff,wprof,dumk1,dumk2,hadvordrs,vadvordrs)

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        th3d(i,j,k) = tha(i,j,k)+dttmp*thten(i,j,k)
        if(abs(th3d(i,j,k)).lt.smeps) th3d(i,j,k)=0.0
      enddo
      enddo
      enddo
      if(timestats.ge.1) time_integ=time_integ+mytime()


!--------------------------------------------------------------------
!  Moisture:

  IF(imoist.eq.1)THEN

    DO n=1,numq

      ! t33 = dummy

      bflag=0
      if(stat_qsrc.eq.1 .and. nrk.eq.nrkmax) bflag=1

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        sten(i,j,k)=qten(i,j,k,n)
      enddo
      enddo
      enddo
      if(timestats.ge.1) time_misc=time_misc+mytime()

      if(nrk.eq.nrkmax)then
        pdef = 1
      else
        pdef = 0
      endif

#ifdef MPI
      if( nrk.ge.2 )then
        call comm_3s_end(q3d(ib,jb,kb,n)  &
                       ,qw31(1,1,1,n),qw32(1,1,1,n),qe31(1,1,1,n),qe32(1,1,1,n)     &
                       ,qs31(1,1,1,n),qs32(1,1,1,n),qn31(1,1,1,n),qn32(1,1,1,n)     &
                       ,reqs_q(1,n) )
      endif
#endif

      ! Note: epsilon = 1.0e-18
      weps = 0.01*epsilon
      IF( idm.eq.1 .and. n.ge.nnc1 .and. n .le. nnc2 ) weps = 1.0e5*epsilon
      IF( idmplus.eq.1 .and. n.ge.nzl1 .and. n .le. nzl2 ) weps = 1.d-30/zscale
      diffit = 0
      if( idiff.eq.1 .and. difforder.eq.6 ) diffit = 1

    IF( n.eq.nqv )THEN
      call advs(nrk,1,bflag,bsq(n),xh,rxh,arh1,arh2,uh,ruh,xf,vh,rvh,gz,rgz,mh,rmh,     &
                 rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,        &
                 rru,rrv,rrw,qa(ib,jb,kb,n),q3d(ib,jb,kb,n),sten,pdef,0,dttmp,weps,     &
                 flag,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,rdsf,c1,c2,rho,rr,diffit, &
                 doqbud ,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,qd_hadv,qd_vadv,qd_subs, &
                 qd_hidiff,qd_vidiff,qd_hediff,wprof,dumk1,dumk2,hadvordrs,vadvordrs)
    ELSE
      call advs(nrk,1,bflag,bsq(n),xh,rxh,arh1,arh2,uh,ruh,xf,vh,rvh,gz,rgz,mh,rmh,     &
                 rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,        &
                 rru,rrv,rrw,qa(ib,jb,kb,n),q3d(ib,jb,kb,n),sten,pdef,1,dttmp,weps,     &
                 flag,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,rdsf,c1,c2,rho,rr,diffit, &
                 .false.,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,1,1,1,              &
                 1,1,1,wprof,dumk1,dumk2,hadvordrs,vadvordrs)
    ENDIF


!$omp parallel do default(shared)   &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        q3d(i,j,k,n) = qa(i,j,k,n)+dttmp*sten(i,j,k)
        if( abs(q3d(i,j,k,n)).lt.smeps ) q3d(i,j,k,n) = 0.0
      enddo
      enddo
      enddo
      if(timestats.ge.1) time_integ=time_integ+mytime()

    ENDDO   ! enddo for n loop

  ENDIF    ! endif for imoist=1

!--------------------------------------------------------------------
!  bcs and comms:

      call bcu(u3d)
#ifdef MPI
      call comm_3u_start(u3d,uw31,uw32,ue31,ue32,   &
                             us31,us32,un31,un32,reqs_u)
#endif
      call bcv(v3d)
#ifdef MPI
      call comm_3v_start(v3d,vw31,vw32,ve31,ve32,   &
                             vs31,vs32,vn31,vn32,reqs_v)
#endif
      call bcw(w3d,1)
      if(terrain_flag) call bcwsfc(gz,dzdx,dzdy,u3d,v3d,w3d)
#ifdef MPI
      call comm_3w_start(w3d,ww31,ww32,we31,we32,   &
                             ws31,ws32,wn31,wn32,reqs_w)
#endif
      IF(nrk.lt.nrkmax)THEN
        call bcs(pp3d)
#ifdef MPI
        call comm_1s_start(pp3d,vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,reqs_x)
#endif
        call bcs(th3d)
#ifdef MPI
        call comm_3s_start(th3d,rw31,rw32,re31,re32,   &
                                rs31,rs32,rn31,rn32,reqs_y)
#endif
        IF(imoist.eq.1)THEN
          do n=1,numq
            call bcs(q3d(ib,jb,kb,n))
#ifdef MPI
            call comm_3s_start(q3d(ib,jb,kb,n)  &
                       ,qw31(1,1,1,n),qw32(1,1,1,n),qe31(1,1,1,n),qe32(1,1,1,n)     &
                       ,qs31(1,1,1,n),qs32(1,1,1,n),qn31(1,1,1,n),qn32(1,1,1,n)     &
                       ,reqs_q(1,n) )
#endif
          enddo
        ENDIF
      ENDIF

!--------------------------------------------------------------------
!  TKE advection
 
        IF(sgsmodel.eq.1)THEN

          ! use wten for tke tendency, step tke forward:

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=2,nk
          do j=1,nj
          do i=1,ni
            wten(i,j,k)=tketen(i,j,k)
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_misc=time_misc+mytime()

#ifdef MPI
        IF(nrk.ge.2)THEN
          call comm_3t_end(tke3d,tkw1,tkw2,tke1,tke2,   &
                                 tks1,tks2,tkn1,tkn2,reqs_tk)
        ENDIF
#endif

        if( dotdwrite .and. kd_adv.ge.1 )then
        if( nrk.eq.nrkmax )then
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk+1
          do j=1,nj
          do i=1,ni
            kdiag(i,j,k,kd_adv) = wten(i,j,k)
          enddo
          enddo
          enddo
        endif
        endif

          call   advw(nrk   ,xh,rxh,arh1,arh2,uh,xf,vh,gz,rgz,mh,mf,rho0,rr0,rf0,rrf0,  &
                      dum1,dum2,dum3,dum4,dum5,dum6,dum7,divx,                       &
                      rru,rrv,rrw,tke3d,wten,rds,rdsf,c1,c2,rho,dttmp,               &
                      .false.,wdiag,hadvordrs,vadvordrs,advwenos)

        if( dotdwrite .and. kd_adv.ge.1 )then
        if( nrk.eq.nrkmax )then
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk+1
          do j=1,nj
          do i=1,ni
            kdiag(i,j,k,kd_adv) = wten(i,j,k)-kdiag(i,j,k,kd_adv)
          enddo
          enddo
          enddo
        endif
        endif

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
        do k=2,nk
          do j=1,nj
          do i=1,ni
            tke3d(i,j,k)=tkea(i,j,k)+dttmp*wten(i,j,k)
            if(tke3d(i,j,k).lt.1.0e-10) tke3d(i,j,k)=0.0
          enddo
          enddo
        enddo
        if(timestats.ge.1) time_integ=time_integ+mytime()


          call bcw(tke3d,1)
#ifdef MPI
          call comm_3t_start(tke3d,tkw1,tkw2,tke1,tke2,   &
                                   tks1,tks2,tkn1,tkn2,reqs_tk)
#endif

        ENDIF

!--------------------------------------------------------------------
!  Passive Tracers

    if(iptra.eq.1)then

      if( nrk.eq.nrkmax .and. pdtra.eq.1 )then
        pdef = 1
      else
        pdef = 0
      endif

    DO n=1,npt

      ! t33 = dummy

      bflag=0
      if(stat_qsrc.eq.1 .and. nrk.eq.nrkmax) bflag=1

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        sten(i,j,k)=ptten(i,j,k,n)
      enddo
      enddo
      enddo
      if(timestats.ge.1) time_misc=time_misc+mytime()


#ifdef MPI
          IF(nrk.ge.2)THEN
            call comm_3s_end(pt3d(ib,jb,kb,n),                           &
                  tw1(1,1,1,n),tw2(1,1,1,n),te1(1,1,1,n),te2(1,1,1,n),   &
                  ts1(1,1,1,n),ts2(1,1,1,n),tn1(1,1,1,n),tn2(1,1,1,n),   &
                  reqs_t(1,n))
          ENDIF
#endif

      weps = 1.0*epsilon
      diffit = 0
      if( idiff.eq.1 .and. difforder.eq.6 ) diffit = 1
      call advs(nrk,1,bflag,bfoo,xh,rxh,arh1,arh2,uh,ruh,xf,vh,rvh,gz,rgz,mh,rmh,       &
                 rho0,rr0,rf0,rrf0,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,        &
                 rru,rrv,rrw,pta(ib,jb,kb,n),pt3d(ib,jb,kb,n),sten,pdef,1,dttmp,weps,   &
                 flag,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,rdsf,c1,c2,rho,rr,diffit, &
                 .false.,ibdq,iedq,jbdq,jedq,kbdq,kedq,nqdiag,qdiag,1,1,1,              &
                 1,1,1,wprof,dumk1,dumk2,hadvordrs,vadvordrs)

!$omp parallel do default(shared)   &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        pt3d(i,j,k,n)=pta(i,j,k,n)+dttmp*sten(i,j,k)
      enddo
      enddo
      enddo
      if(timestats.ge.1) time_integ=time_integ+mytime()

      IF(nrk.le.2)THEN
        call bcs(pt3d(ib,jb,kb,n))
#ifdef MPI
        call comm_3s_start(pt3d(ib,jb,kb,n)   &
                     ,tw1(1,1,1,n),tw2(1,1,1,n),te1(1,1,1,n),te2(1,1,1,n)     &
                     ,ts1(1,1,1,n),ts2(1,1,1,n),tn1(1,1,1,n),tn2(1,1,1,n)     &
                     ,reqs_t(1,n) )
#endif
      ENDIF

    ENDDO
    endif

!--------------------------------------------------------------------
!  Get pressure
!  Get density

    pscheck:  IF(psolver.eq.4.or.psolver.eq.5.or.psolver.eq.6)THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        prs(i,j,k)=prs0(i,j,k)
        rho(i,j,k)=rho0(i,j,k)
        rr(i,j,k)=rr0(i,j,k)
      enddo
      enddo
      enddo
      if(timestats.ge.1) time_prsrho=time_prsrho+mytime()

    ELSE

      IF(imoist.eq.1)THEN

        IF(nrk.eq.nrkmax.and.eqtset.eq.2)THEN
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ! subtract-off estimated diabatic terms used during RK steps:
            ! also, save values before calculating microphysics:
            pp3d(i,j,k)=pp3d(i,j,k)-dt*qpten(i,j,k)
            qpten(i,j,k)=pp3d(i,j,k)
            th3d(i,j,k)=th3d(i,j,k)-dt*qtten(i,j,k)
            qtten(i,j,k)=th3d(i,j,k)
            q3d(i,j,k,nqv)=q3d(i,j,k,nqv)-dt*qvten(i,j,k)
            qvten(i,j,k)=q3d(i,j,k,nqv)
            q3d(i,j,k,nqc)=q3d(i,j,k,nqc)-dt*qcten(i,j,k)
            qcten(i,j,k)=q3d(i,j,k,nqc)
          enddo
          enddo
          enddo
        ENDIF

        IF( nrk.eq.nrkmax .or. (idiff.ge.1 .and. difforder.eq.6) )THEN
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            prs(i,j,k)=p00*((pi0(i,j,k)+pp3d(i,j,k))**cpdrd)
            rho(i,j,k)=prs(i,j,k)                         &
               /( (th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))     &
                 *(rd+max(0.0,q3d(i,j,k,nqv))*rv) )
          enddo
          enddo
          enddo
        ENDIF

      ELSE

        IF( nrk.eq.nrkmax .or. (idiff.ge.1 .and. difforder.eq.6) )THEN
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            prs(i,j,k)=p00*((pi0(i,j,k)+pp3d(i,j,k))**cpdrd)
            rho(i,j,k)=prs(i,j,k)   &
               /(rd*(th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k)))
          enddo
          enddo
          enddo
        ENDIF

      ENDIF


      !-----------------------------------------------
      pmod:  IF( apmasscon.eq.1 .and. nrk.eq.nrkmax )THEN
        ! cm1r18:  adjust average pressure perturbation to ensure 
        !          conservation of total dry-air mass

        dumk1 = 0.0
        dumk2 = 0.0

        IF( axisymm.eq.0 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            dumk1(k) = dumk1(k) + rho(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)
            dumk2(k) = dumk2(k) + (pi0(i,j,k)+pp3d(i,j,k))
          enddo
          enddo
          enddo
        ELSEIF( axisymm.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            dumk1(k) = dumk1(k) + rho(i,j,k)*ruh(i)*rvh(j)*rmh(i,j,k)*pi*(xf(i+1)**2-xf(i)**2)
            dumk2(k) = dumk2(k) + (pi0(i,j,k)+pp3d(i,j,k))
          enddo
          enddo
          enddo
        ENDIF

#ifdef MPI
        call MPI_ALLREDUCE(mpi_in_place,dumk1(1),nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
        call MPI_ALLREDUCE(mpi_in_place,dumk2(1),nk,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,ierr)
#endif

        mass2 = 0.0
        p2 = 0.0

        do k=1,nk
          mass2 = mass2 + dumk1(k)
          p2 = p2 + dumk2(k)
        enddo

        mass2 = mass2*dble(dx*dy*dz)
        p2 = p2/dble(nx*ny*nz)

        tem = ( (mass1/mass2)**(dble(rd)/dble(cv)) - 1.0d0 )*p2

        IF( imoist.eq.1 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            pp3d(i,j,k) = pp3d(i,j,k) + tem
            prs(i,j,k)=p00*((pi0(i,j,k)+pp3d(i,j,k))**cpdrd)
            rho(i,j,k)=prs(i,j,k)                         &
               /( (th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))     &
                 *(rd+max(0.0,q3d(i,j,k,nqv))*rv) )
          enddo
          enddo
          enddo
        ELSE
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            pp3d(i,j,k) = pp3d(i,j,k) + tem
            prs(i,j,k)=p00*((pi0(i,j,k)+pp3d(i,j,k))**cpdrd)
            rho(i,j,k)=prs(i,j,k)   &
               /(rd*(th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k)))
          enddo
          enddo
          enddo
        ENDIF

      ENDIF  pmod
      !-----------------------------------------------

      if(timestats.ge.1) time_prsrho=time_prsrho+mytime()

    ENDIF  pscheck

    if( nrk.lt.nrkmax )then
      call bcs(rho)
#ifdef MPI
        call comm_1s_start(rho,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
#endif
    endif

!--------------------------------------------------------------------

      IF( idiff.ge.1 .and. difforder.eq.6 .and. nrk.lt.nrkmax )THEN
        !$omp parallel do default(shared)  &
        !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          rr(i,j,k) = 1.0/rho(i,j,k)
        enddo
        enddo
        enddo
        if(timestats.ge.1) time_prsrho=time_prsrho+mytime()
      ENDIF

!--------------------------------------------------------------------
! RK loop end

      ENDDO  rkloop


!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CC   End of RK section   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC


!--------------------------------------------------------------------
!  Final step for Passive Tracers
!  (using final value of rho)

    if(iptra.eq.1)then
      DO n=1,npt
        if( pdtra.eq.1 ) call pdefq(0.0,afoo,ruh,rvh,rmh,rho,pt3d(ib,jb,kb,n))
        call bcs(pt3d(ib,jb,kb,n))
#ifdef MPI
        call comm_3s_start(pt3d(ib,jb,kb,n)   &
                     ,tw1(1,1,1,n),tw2(1,1,1,n),te1(1,1,1,n),te2(1,1,1,n)     &
                     ,ts1(1,1,1,n),ts2(1,1,1,n),tn1(1,1,1,n),tn2(1,1,1,n)     &
                     ,reqs_t(1,n) )
#endif
      ENDDO
    endif


!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CC   BEGIN microphysics   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

      ifmp:  &
      IF(imoist.eq.1)THEN

        if( stopit ) getdbz = .true.

        IF( efall.eq.1 ) getvt = .true.
        IF( dowriteout .and. output_fallvel.eq.1 ) getvt = .true.

        ! dum1 = T
        ! dum3 = appropriate rho for budget calculations
        ! store copy of T in thten array:

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n)
        DO k=1,nk

          do j=1,nj
          do i=1,ni
            dum1(i,j,k)=(th0(i,j,k)+th3d(i,j,k))*(pi0(i,j,k)+pp3d(i,j,k))
            thten(i,j,k)=dum1(i,j,k)
            qten(i,j,k,nqv)=q3d(i,j,k,nqv)
          enddo
          enddo

          if( getdbz .and. qd_dbz.ge.1 )then
            do j=1,nj
            do i=1,ni
              qdiag(i,j,k,qd_dbz)=0.0
            enddo
            enddo
          endif

          IF(axisymm.eq.0)THEN
            ! for Cartesian grid:
            do j=1,nj
            do i=1,ni
              dum3(i,j,k)=rho(i,j,k)
            enddo
            enddo
          ELSE
            ! for axisymmetric grid:
            do j=1,nj
            do i=1,ni
              dum3(i,j,k) = rho(i,j,k)*pi*(xf(i+1)**2-xf(i)**2)/(dx*dy)
            enddo
            enddo
          ENDIF

          if( dotbud .and. td_mp.ge.1 )then
            do j=1,nj
            do i=1,ni
              tdiag(i,j,k,td_mp) = th3d(i,j,k)
              dum5(i,j,k) = pi0(i,j,k)+pp3d(i,j,k)
            enddo
            enddo
          endif
          if( doqbud .and. qd_mp.ge.1 )then
            do j=1,nj
            do i=1,ni
              qdiag(i,j,k,qd_mp) = q3d(i,j,k,nqv)
            enddo
            enddo
          endif

        ENDDO


!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!  NOTES:
!
!           dum1   is   T
!           dum3   is   rho for budget calculations
!
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccc   Kessler scheme   cccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
        ifptype:  &
        IF(ptype.eq.1)THEN
          call pdefq(    0.0,asq(1),ruh,rvh,rmh,rho,q3d(ib,jb,kb,1))
          call pdefq( qsmall,asq(2),ruh,rvh,rmh,rho,q3d(ib,jb,kb,2))
          call pdefq( qsmall,asq(3),ruh,rvh,rmh,rho,q3d(ib,jb,kb,3))
          call k_fallout(rho,q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
          call geterain(dt,cpl,lv1,qbudget(7),ruh,rvh,dum1,dum3,q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
          if(efall.ge.1)then
            call getcvm(dum2,q3d)
            call getefall(1,cpl,mf,dum1,dum2,dum4,q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk-1
            do j=1,nj
            do i=1,ni
              if( abs(dt*dum4(i,j,k)).ge.tsmall )then
                dum1(i,j,k) = dum1(i,j,k) + dt*dum4(i,j,k)
                prs(i,j,k)=rho(i,j,k)*rd*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps)
                pp3d(i,j,k)=(prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
              endif
            enddo
            enddo
            enddo
            if( dotbud .and. td_efall.ge.1 )then
              !$omp parallel do default(shared)  &
              !$omp private(i,j,k)
              do k=1,nk-1
              do j=1,nj
              do i=1,ni
                tdiag(i,j,k,td_efall) = dum4(i,j,k)
              enddo
              enddo
              enddo
            endif
          endif
          call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                       q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
          call kessler(dt,qbudget(3),qbudget(4),qbudget(5),ruh,rvh,rmh,pi0,th0,dum1,   &
                       rho,dum3,pp3d,th3d,prs,                            &
                       q3d(ib,jb,kb,nqv),q3d(ib,jb,kb,2),q3d(ib,jb,kb,3))
          call satadj(4,dt,qbudget(1),qbudget(2),ruh,rvh,rmh,pi0,th0,   &
                      rho,dum3,pp3d,prs,th3d,q3d)
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccc   Goddard LFO scheme   cccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
        ELSEIF(ptype.eq.2)THEN
          call pdefq(    0.0,asq(1),ruh,rvh,rmh,rho,q3d(ib,jb,kb,1))
          call pdefq( qsmall,asq(2),ruh,rvh,rmh,rho,q3d(ib,jb,kb,2))
          call pdefq( qsmall,asq(3),ruh,rvh,rmh,rho,q3d(ib,jb,kb,3))
          call pdefq( qsmall,asq(4),ruh,rvh,rmh,rho,q3d(ib,jb,kb,4))
          call pdefq( qsmall,asq(5),ruh,rvh,rmh,rho,q3d(ib,jb,kb,5))
          call pdefq( qsmall,asq(6),ruh,rvh,rmh,rho,q3d(ib,jb,kb,6))
          call goddard(dt,qbudget(3),qbudget(4),qbudget(5),ruh,rvh,rmh,pi0,th0,             &
                       rho,dum3,prs,pp3d,th3d,                            &
     q3d(ib,jb,kb,1), q3d(ib,jb,kb,2),q3d(ib,jb,kb,3),qten(ib,jb,kb,3),   &
     q3d(ib,jb,kb,4),qten(ib,jb,kb,4),q3d(ib,jb,kb,5),qten(ib,jb,kb,5),   &
     q3d(ib,jb,kb,6),qten(ib,jb,kb,6))
          call satadj_ice(4,dt,qbudget(1),qbudget(2),ruh,rvh,rmh,pi0,th0,     &
                          rho,dum3,pp3d,prs,th3d,                     &
              q3d(ib,jb,kb,1),q3d(ib,jb,kb,2),q3d(ib,jb,kb,3),   &
              q3d(ib,jb,kb,4),q3d(ib,jb,kb,5),q3d(ib,jb,kb,6))
          call geterain(dt,cpl,lv1,qbudget(7),ruh,rvh,dum1,dum3,q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
          call geterain(dt,cpi,ls1,qbudget(7),ruh,rvh,dum1,dum3,q3d(ib,jb,kb,4),qten(ib,jb,kb,4))
          call geterain(dt,cpi,ls1,qbudget(7),ruh,rvh,dum1,dum3,q3d(ib,jb,kb,5),qten(ib,jb,kb,5))
          call geterain(dt,cpi,ls1,qbudget(7),ruh,rvh,dum1,dum3,q3d(ib,jb,kb,6),qten(ib,jb,kb,6))
          if(efall.ge.1)then
            call getcvm(dum2,q3d)
            call getefall(1,cpl,mf,dum1,dum2,dum4,q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
            call getefall(0,cpi,mf,dum1,dum2,dum4,q3d(ib,jb,kb,4),qten(ib,jb,kb,4))
            call getefall(0,cpi,mf,dum1,dum2,dum4,q3d(ib,jb,kb,5),qten(ib,jb,kb,5))
            call getefall(0,cpi,mf,dum1,dum2,dum4,q3d(ib,jb,kb,6),qten(ib,jb,kb,6))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk-1
            do j=1,nj
            do i=1,ni
              if( abs(dt*dum4(i,j,k)).ge.tsmall )then
                dum1(i,j,k) = dum1(i,j,k) + dt*dum4(i,j,k)
                prs(i,j,k)=rho(i,j,k)*rd*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps)
                pp3d(i,j,k)=(prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
              endif
            enddo
            enddo
            enddo
            if( dotbud .and. td_efall.ge.1 )then
              !$omp parallel do default(shared)  &
              !$omp private(i,j,k)
              do k=1,nk-1
              do j=1,nj
              do i=1,ni
                tdiag(i,j,k,td_efall) = dum4(i,j,k)
              enddo
              enddo
              enddo
            endif
          endif
          call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                       q3d(ib,jb,kb,3),qten(ib,jb,kb,3))
          call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                       q3d(ib,jb,kb,4),qten(ib,jb,kb,4))
          call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                       q3d(ib,jb,kb,5),qten(ib,jb,kb,5))
          call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                       q3d(ib,jb,kb,6),qten(ib,jb,kb,6))
          if(getdbz) call calcdbz(rho,q3d(ib,jb,kb,3),q3d(ib,jb,kb,5),q3d(ib,jb,kb,6),  &
                                  qdiag(ibdq,jbdq,kbdq,qd_dbz))

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccc   Thompson scheme   ccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

        ELSEIF(ptype.eq.3)THEN
          call pdefq(    0.0,asq(1),ruh,rvh,rmh,rho,q3d(ib,jb,kb,1))
          call pdefq( qsmall,asq(2),ruh,rvh,rmh,rho,q3d(ib,jb,kb,2))
          call pdefq( qsmall,asq(3),ruh,rvh,rmh,rho,q3d(ib,jb,kb,3))
          call pdefq( qsmall,asq(4),ruh,rvh,rmh,rho,q3d(ib,jb,kb,4))
          call pdefq( qsmall,asq(5),ruh,rvh,rmh,rho,q3d(ib,jb,kb,5))
          call pdefq( qsmall,asq(6),ruh,rvh,rmh,rho,q3d(ib,jb,kb,6))
!!!          call pdefq(    1.0,asq(7),ruh,rvh,rmh,rho,q3d(ib,jb,kb,7))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ! cm1r17:  to make things easier to understand, use same arrays 
            !          that are used for morrison code:
            ! dum1 = T  (this should have been calculated already)
            ! dum2 = pi (nondimensional pressure)
            ! dum4 = dz
            ! thten = copy of T  (this should have been calculated already)
            dum2(i,j,k)=pi0(i,j,k)+pp3d(i,j,k)
            dum4(i,j,k)=dz*rmh(i,j,k)
          enddo
          enddo
          enddo

          if( radopt.eq.2 )then
            has_reqc = 1
            has_reqi = 1
            has_reqs = 1
          else
            has_reqc = 0
            has_reqi = 0
            has_reqs = 0
          endif
          do_radar_ref = 1

          call   mp_gt_driver(qv=q3d(ib,jb,kb,1), &
                              qc=q3d(ib,jb,kb,2), &
                              qr=q3d(ib,jb,kb,3), &
                              qi=q3d(ib,jb,kb,4), &
                              qs=q3d(ib,jb,kb,5), &
                              qg=q3d(ib,jb,kb,6), &
                              ni=q3d(ib,jb,kb,7), &
                              nr=q3d(ib,jb,kb,8), &
                  t3d=dum1, pii=dum2, p=prs, w=w3d, dz=dum4, dt_in=dt, itimestep=nstep,                &
                  RAINNC=rain(ib,jb,1), RAINNCV=dum5(ib,jb,1), SR=dum5(ib,jb,2),                       &
                  refl_10cm=qdiag(ibdq,jbdq,kbdq,qd_dbz), diagflag=getdbz, do_radar_ref=do_radar_ref,  &
                  re_cloud=dum6, re_ice=dum7, re_snow=dum8,                  &
                  has_reqc=has_reqc, has_reqi=has_reqi, has_reqs=has_reqs,   &
                  nrain=nrain,dx=dx, dy=dy, cm1dz=dz,                        &
                  tcond=qbudget(1),tevac=qbudget(2),                         &
                  tevar=qbudget(5),train=qbudget(6),                         &
                  ruh=ruh,rvh=rvh,rmh=rmh,rr=dum3,rain=rain,prate=prate,     &
                  ib3d=ib3d,ie3d=ie3d,jb3d=jb3d,je3d=je3d,kb3d=kb3d,ke3d=ke3d, &
                  nout3d=nout3d,out3d=out3d,eqtset=eqtset,                   &
                  ids=1  ,ide=ni+1 , jds= 1 ,jde=nj+1 , kds=1  ,kde=nk+1 ,   &
                  ims=ib ,ime=ie   , jms=jb ,jme=je   , kms=kb ,kme=ke ,     &
                  its=1  ,ite=ni   , jts=1  ,jte=nj   , kts=1  ,kte=nk )

          ! Get final values for th3d,pp3d,prs:
          ! Note:  dum1 stores temperature, thten stores old temperature:
          IF( eqtset.eq.2 )THEN
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              if( abs(dum1(i,j,k)-thten(i,j,k)).ge.tsmall .or.  &
                  abs(q3d(i,j,k,nqv)-qten(i,j,k,nqv)).ge.qsmall )then
                prs(i,j,k)=rho(i,j,k)*(rd+rv*q3d(i,j,k,nqv))*dum1(i,j,k)
                pp3d(i,j,k)=(prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
              endif
            enddo
            enddo
            enddo
          ELSE
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              if( abs(dum1(i,j,k)-thten(i,j,k)).ge.tsmall .or.  &
                  abs(q3d(i,j,k,nqv)-qten(i,j,k,nqv)).ge.qsmall )then
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
                rho(i,j,k)=prs(i,j,k)/(rd*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps))
              endif
            enddo
            enddo
            enddo
          ENDIF
          if( radopt.eq.2 )then
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              effc(i,j,k) = dum6(i,j,k)
              effi(i,j,k) = dum7(i,j,k)
              effs(i,j,k) = dum8(i,j,k)
            enddo
            enddo
            enddo
          endif
          if(timestats.ge.1) time_microphy=time_microphy+mytime()

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccc   GSR LFO scheme   cccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

        ELSEIF(ptype.eq.4)THEN
          call pdefq(    0.0,asq(1),ruh,rvh,rmh,rho,q3d(ib,jb,kb,1))
          call pdefq( qsmall,asq(2),ruh,rvh,rmh,rho,q3d(ib,jb,kb,2))
          call pdefq( qsmall,asq(3),ruh,rvh,rmh,rho,q3d(ib,jb,kb,3))
          call pdefq( qsmall,asq(4),ruh,rvh,rmh,rho,q3d(ib,jb,kb,4))
          call pdefq( qsmall,asq(5),ruh,rvh,rmh,rho,q3d(ib,jb,kb,5))
          call pdefq( qsmall,asq(6),ruh,rvh,rmh,rho,q3d(ib,jb,kb,6))
          call lfo_ice_drive(dt, mf, pi0, prs0, pp3d, prs, th0, th3d,    &
                             qv0, rho0, q3d, qten, dum1)
          do n=2,numq
            call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                         q3d(ib,jb,kb,n),qten(ib,jb,kb,n))
          enddo

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccc   Morrison scheme   cccccccccccccccccccccccccccccccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

        ELSEIF(ptype.eq.5)THEN
          call pdefq(    0.0,asq(1),ruh,rvh,rmh,rho,q3d(ib,jb,kb,1))
          call pdefq( qsmall,asq(2),ruh,rvh,rmh,rho,q3d(ib,jb,kb,2))
          call pdefq( qsmall,asq(3),ruh,rvh,rmh,rho,q3d(ib,jb,kb,3))
          call pdefq( qsmall,asq(4),ruh,rvh,rmh,rho,q3d(ib,jb,kb,4))
          call pdefq( qsmall,asq(5),ruh,rvh,rmh,rho,q3d(ib,jb,kb,5))
          call pdefq( qsmall,asq(6),ruh,rvh,rmh,rho,q3d(ib,jb,kb,6))
!!!          call pdefq(    1.0,asq(7),ruh,rvh,rmh,rho,q3d(ib,jb,kb,7))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ! dum1 = T  (this should have been calculated already)
            ! dum4 = dz
            ! thten = copy of T  (this should have been calculated already)
            dum4(i,j,k)=dz*rmh(i,j,k)
          enddo
          enddo
          enddo
          IF(numq.eq.11)THEN
            ! ppten stores ncc:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              ppten(i,j,k) = q3d(i,j,k,11)
            enddo
            enddo
            enddo
          ENDIF
          ! cm1r17:  get fall velocities (store in qten array)
          call MP_GRAUPEL(nstep,dum1,dum5,                            &
                          q3d(ib,jb,kb, 1),q3d(ib,jb,kb, 2),q3d(ib,jb,kb, 3), &
                          q3d(ib,jb,kb, 4),q3d(ib,jb,kb, 5),q3d(ib,jb,kb, 6), &
                          q3d(ib,jb,kb, 7),q3d(ib,jb,kb, 8),q3d(ib,jb,kb, 9), &
                          q3d(ib,jb,kb,10),ppten,                             &
                               prs,rho,dt,dum4,w3d,rain,prate,                &
                          effc,effi,effs,effr,effg,effis,                     &
                          qbudget(1),qbudget(2),qbudget(5),qbudget(6),        &
                          ruh,rvh,rmh,dum3,getdbz,                            &
                          qten(ib,jb,kb,nqc),qten(ib,jb,kb,nqr),qten(ib,jb,kb,nqi),  &
                          qten(ib,jb,kb,nqs),qten(ib,jb,kb,nqg),getvt,dorad,  &
                          dotbud,doqbud,tdiag,qdiag,out3d)
          IF(numq.eq.11)THEN
            ! ppten stores ncc:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              q3d(i,j,k,11) = ppten(i,j,k)
            enddo
            enddo
            enddo
          ENDIF
          if(timestats.ge.1) time_microphy=time_microphy+mytime()
          IF(efall.eq.1)THEN
            ! dum1 = T
            ! dum2 = cvm
            ! dum4 = T tendency
            call getcvm(dum2,q3d)
            call getefall(1,cpl,mf,dum1,dum2,dum4,q3d(ib,jb,kb,nqc),qten(ib,jb,kb,nqc))
            call getefall(0,cpl,mf,dum1,dum2,dum4,q3d(ib,jb,kb,nqr),qten(ib,jb,kb,nqr))
            call getefall(0,cpi,mf,dum1,dum2,dum4,q3d(ib,jb,kb,nqi),qten(ib,jb,kb,nqi))
            call getefall(0,cpi,mf,dum1,dum2,dum4,q3d(ib,jb,kb,nqs),qten(ib,jb,kb,nqs))
            call getefall(0,cpi,mf,dum1,dum2,dum4,q3d(ib,jb,kb,nqg),qten(ib,jb,kb,nqg))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk-1
            do j=1,nj
            do i=1,ni
              dum1(i,j,k) = dum1(i,j,k) + dt*dum4(i,j,k)
            enddo
            enddo
            enddo
            if( dotbud .and. td_efall.ge.1 )then
              !$omp parallel do default(shared)  &
              !$omp private(i,j,k)
              do k=1,nk-1
              do j=1,nj
              do i=1,ni
                tdiag(i,j,k,td_efall) = dum4(i,j,k)
              enddo
              enddo
              enddo
            endif
          ENDIF
          ! Get final values for th3d,pp3d,prs:
          ! Note:  dum1 stores temperature, thten stores old temperature:
          IF( eqtset.eq.2 )THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              if( abs(dum1(i,j,k)-thten(i,j,k)).ge.tsmall .or.  &
                  abs(q3d(i,j,k,nqv)-qten(i,j,k,nqv)).ge.qsmall )then
                prs(i,j,k)=rho(i,j,k)*(rd+rv*q3d(i,j,k,nqv))*dum1(i,j,k)
                pp3d(i,j,k)=(prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
              endif
            enddo
            enddo
            enddo
          ELSE
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              if( abs(dum1(i,j,k)-thten(i,j,k)).ge.tsmall .or.  &
                  abs(q3d(i,j,k,nqv)-qten(i,j,k,nqv)).ge.qsmall )then
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
                rho(i,j,k)=prs(i,j,k)/(rd*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps))
              endif
            enddo
            enddo
            enddo
          ENDIF

          IF( getvt )THEN
          IF( dowriteout .or. dotdwrite .or. doazimwrite .or. dorestart )THEN
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk
              if( qd_vtc.ge.1 )then
                do j=1,nj
                do i=1,ni
                  qdiag(i,j,k,qd_vtc) = qten(i,j,k,nqc)
                enddo
                enddo
              endif
              if( qd_vtr.ge.1 )then
                do j=1,nj
                do i=1,ni
                  qdiag(i,j,k,qd_vtr) = qten(i,j,k,nqr)
                enddo
                enddo
              endif
              if( qd_vts.ge.1 )then
                do j=1,nj
                do i=1,ni
                  qdiag(i,j,k,qd_vts) = qten(i,j,k,nqs)
                enddo
                enddo
              endif
              if( qd_vtg.ge.1 )then
                do j=1,nj
                do i=1,ni
                  qdiag(i,j,k,qd_vtg) = qten(i,j,k,nqg)
                enddo
                enddo
              endif
              if( qd_vti.ge.1 )then
                do j=1,nj
                do i=1,ni
                  qdiag(i,j,k,qd_vti) = qten(i,j,k,nqi)
                enddo
                enddo
              endif
            enddo
          ENDIF
          ENDIF

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!ccc   RE87-type scheme   cccccccccccccccccccccccccccccccccccccccccccccc
!ccc   also:  reversible moist thermo. if v_t = 0   cccccccccccccccccccc
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

        ELSEIF(ptype.eq.6)THEN
          call pdefq(    0.0,asq(1),ruh,rvh,rmh,rho,q3d(ib,jb,kb,1))
          call pdefq( qsmall,asq(2),ruh,rvh,rmh,rho,q3d(ib,jb,kb,2))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            if(q3d(i,j,k,2).gt.0.001)then
              qten(i,j,k,2) = v_t
            else
              qten(i,j,k,2) = 0.0
            endif
          enddo
          enddo
          enddo
          call geterain(dt,cpl,lv1,qbudget(7),ruh,rvh,dum1,dum3,q3d(ib,jb,kb,2),qten(ib,jb,kb,2))
          if( efall.ge.1 .and. v_t.gt.1.0e-6 )then
            call getcvm(dum2,q3d)
            call getefall(1,cpl,mf,dum1,dum2,dum4,q3d(ib,jb,kb,2),qten(ib,jb,kb,2))
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk-1
            do j=1,nj
            do i=1,ni
              if( abs(dt*dum4(i,j,k)).ge.tsmall )then
                dum1(i,j,k) = dum1(i,j,k) + dt*dum4(i,j,k)
                prs(i,j,k)=rho(i,j,k)*rd*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps)
                pp3d(i,j,k)=(prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
                th3d(i,j,k)=dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
              endif
            enddo
            enddo
            enddo
            if( dotbud .and. td_efall.ge.1 )then
              !$omp parallel do default(shared)  &
              !$omp private(i,j,k)
              do k=1,nk-1
              do j=1,nj
              do i=1,ni
                tdiag(i,j,k,td_efall) = dum4(i,j,k)
              enddo
              enddo
              enddo
            endif
          endif
          call fallout(dt,qbudget(6),ruh,rvh,zh,mh,mf,rain,prate,dum3,rho,   &
                       q3d(ib,jb,kb,2),qten(ib,jb,kb,2))
          call satadj(4,dt,qbudget(1),qbudget(2),ruh,rvh,rmh,pi0,th0,   &
                      rho,dum3,pp3d,prs,th3d,q3d)

          IF( v_t.lt.(-0.0001) )THEN
            ! pseudoadiabatic approach of Bryan and Rotunno (2009, JAS, pg 3046)
            !$omp parallel do default(shared)  &
            !$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              q3d(i,j,k,nqc) = min( q3d(i,j,k,nqc) , 0.0001 )
            enddo
            enddo
            enddo
          ENDIF

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!  Ziegler/Mansell (NSSL) two-moment scheme
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!
        ELSEIF(ptype.ge.26)THEN
          IF ( ptype .eq. 26 ) THEN
            j = 13
          ELSEIF ( ptype .eq. 27 ) THEN
            j = 16
          ELSEIF ( ptype .eq. 28) THEN ! single moment
            j = 6
          ELSEIF ( ptype .eq. 29 ) THEN
            j = 19
          ENDIF
          DO i = 1,j
            call pdefq(0.0,asq(i),ruh,rvh,rmh,rho,q3d(ib,jb,kb,i))
          ENDDO

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            dum1(i,j,k) = pi0(i,j,k)+pp3d(i,j,k)
            dum2(i,j,k) = dz*rmh(i,j,k)
            dum4(i,j,k) = th0(i,j,k)+th3d(i,j,k)
            ! store old theta in thten array:
            thten(i,j,k)=dum4(i,j,k)
          enddo
          enddo
          enddo
          
          IF ( ptype .eq. 26 ) THEN  ! graupel only
             call nssl_2mom_driver(                          &
                               th  = dum4,                   &
                               qv  = q3d(ib,jb,kb, 1),       &
                               qc  = q3d(ib,jb,kb, 2),       &
                               qr  = q3d(ib,jb,kb, 3),       &
                               qi  = q3d(ib,jb,kb, 4),       &
                               qs  = q3d(ib,jb,kb, 5),       &
                               qh  = q3d(ib,jb,kb, 6),       &
                               cn  = q3d(ib,jb,kb, 7),       &
                               ccw = q3d(ib,jb,kb, 8),       &
                               crw = q3d(ib,jb,kb, 9),       &
                               cci = q3d(ib,jb,kb, 10),      &
                               csw = q3d(ib,jb,kb, 11),      &
                               chw = q3d(ib,jb,kb, 12),      &
                               vhw = q3d(ib,jb,kb, 13),      &
                               pii = dum1,                   &
                               p   =  prs,                   &
                               w   =  w3d,                   &
                               dn  =  rho,                   &
                               dz  =  dum2,                  &
                               dtp = dt,                     &
                               itimestep = nstep,            &
                              RAIN = rain,                   &
                              nrain = nrain,                 &
                              prate = prate,                 &
                              dbz = qdiag(ibdq,jbdq,kbdq,qd_dbz), &
                              ruh = ruh, rvh = rvh, rmh = rmh, &
                              dx = dx, dy = dy,              &
                              tcond = qbudget(1),            &
                              tevac = qbudget(2),            &
                              tevar = qbudget(5),            &
                              train = qbudget(6),            &
                              rr    = dum3,                  &
                              diagflag = getdbz,                  &
                  ib3d=ib3d,ie3d=ie3d,jb3d=jb3d,je3d=je3d,kb3d=kb3d,ke3d=ke3d, &
                  nout3d=nout3d,out3d=out3d,                                 &
                              ims = ib ,ime = ie , jms = jb ,jme = je, kms = kb,kme = ke,  &  
                              its = 1 ,ite = ni, jts = 1,jte = nj, kts = 1,kte = nk)
         ELSEIF ( ptype .eq. 27 ) THEN
             call nssl_2mom_driver(                          &
                               th  = dum4,                   &
                               qv  = q3d(ib,jb,kb, 1),       &
                               qc  = q3d(ib,jb,kb, 2),       &
                               qr  = q3d(ib,jb,kb, 3),       &
                               qi  = q3d(ib,jb,kb, 4),       &
                               qs  = q3d(ib,jb,kb, 5),       &
                               qh  = q3d(ib,jb,kb, 6),       &
                               qhl = q3d(ib,jb,kb, 7),       &
                               cn  = q3d(ib,jb,kb, 8),       &
                               ccw = q3d(ib,jb,kb, 9),       &
                               crw = q3d(ib,jb,kb,10),       &
                               cci = q3d(ib,jb,kb, 11),      &
                               csw = q3d(ib,jb,kb, 12),      &
                               chw = q3d(ib,jb,kb, 13),      &
                               chl = q3d(ib,jb,kb, 14),      &
                               vhw = q3d(ib,jb,kb, 15),      &
                               vhl = q3d(ib,jb,kb, 16),      &
                               pii = dum1,                   &
                               p   =  prs,                   &
                               w   =  w3d,                   &
                               dn  =  rho,                   &
                               dz  =  dum2,                  &
                               dtp = dt,                     &
                               itimestep = nstep,            &
                              RAIN = rain,                   &
                              nrain = nrain,                 &
                              prate = prate,                 &
                              dbz = qdiag(ibdq,jbdq,kbdq,qd_dbz), &
                              ruh = ruh, rvh = rvh, rmh = rmh, &
                              dx = dx, dy = dy,              &
                              tcond = qbudget(1),            &
                              tevac = qbudget(2),            &
                              tevar = qbudget(5),            &
                              train = qbudget(6),            &
                              rr    = dum3,                  &
                              diagflag = getdbz,             &
                  ib3d=ib3d,ie3d=ie3d,jb3d=jb3d,je3d=je3d,kb3d=kb3d,ke3d=ke3d, &
                  nout3d=nout3d,out3d=out3d,                                 &
                              ims = ib ,ime = ie , jms = jb ,jme = je, kms = kb,kme = ke,  &  
                              its = 1 ,ite = ni, jts = 1,jte = nj, kts = 1,kte = nk)
          ELSEIF ( ptype .eq. 28 ) THEN  ! single moment
             call nssl_2mom_driver(                          &
                               th  = dum4,                   &
                               qv  = q3d(ib,jb,kb, 1),       &
                               qc  = q3d(ib,jb,kb, 2),       &
                               qr  = q3d(ib,jb,kb, 3),       &
                               qi  = q3d(ib,jb,kb, 4),       &
                               qs  = q3d(ib,jb,kb, 5),       &
                               qh  = q3d(ib,jb,kb, 6),       &
                               pii = dum1,                   &
                               p   =  prs,                   &
                               w   =  w3d,                   &
                               dn  =  rho,                   &
                               dz  =  dum2,                  &
                               dtp = dt,                     &
                               itimestep = nstep,            &
                              RAIN = rain,                   &
                              nrain = nrain,                 &
                              prate = prate,                 &
                              dbz = qdiag(ibdq,jbdq,kbdq,qd_dbz), &
                              ruh = ruh, rvh = rvh, rmh = rmh, &
                              dx = dx, dy = dy,              &
                              tcond = qbudget(1),            &
                              tevac = qbudget(2),            &
                              tevar = qbudget(5),            &
                              train = qbudget(6),            &
                              rr    = dum3,                  &
                              diagflag = getdbz,                  &
                  ib3d=ib3d,ie3d=ie3d,jb3d=jb3d,je3d=je3d,kb3d=kb3d,ke3d=ke3d, &
                  nout3d=nout3d,out3d=out3d,                                 &
                              ims = ib ,ime = ie , jms = jb ,jme = je, kms = kb,kme = ke,  &  
                              its = 1 ,ite = ni, jts = 1,jte = nj, kts = 1,kte = nk)

!         ELSEIF ( ptype .eq. 29 ) THEN ! 3-moment
!             call nssl_2mom_driver(                          &
!                               th  = dum4,                   &
!                               qv  = q3d(ib,jb,kb, 1),       &
!                               qc  = q3d(ib,jb,kb, 2),       &
!                               qr  = q3d(ib,jb,kb, 3),       &
!                               qi  = q3d(ib,jb,kb, 4),       &
!                               qs  = q3d(ib,jb,kb, 5),       &
!                               qh  = q3d(ib,jb,kb, 6),       &
!                               qhl = q3d(ib,jb,kb, 7),       &
!                               cn  = q3d(ib,jb,kb, 8),       &
!                               ccw = q3d(ib,jb,kb, 9),       &
!                               crw = q3d(ib,jb,kb,10),       &
!                               cci = q3d(ib,jb,kb, 11),      &
!                               csw = q3d(ib,jb,kb, 12),      &
!                               chw = q3d(ib,jb,kb, 13),      &
!                               chl = q3d(ib,jb,kb, 14),      &
!                               zrw = q3d(ib,jb,kb, 15),      &
!                               zhw = q3d(ib,jb,kb, 16),      &
!                               zhl = q3d(ib,jb,kb, 17),      &
!                               vhw = q3d(ib,jb,kb, 18),      &
!                               vhl = q3d(ib,jb,kb, 19),      &
!                               pii = dum1,                   &
!                               p   =  prs,                   &
!                               w   =  w3d,                   &
!                               dn  =  rho,                   &
!                               dz  =  dum2,                  &
!                               dtp = dt,                     &
!                               itimestep = nstep,            &
!                              RAIN = rain,                   &
!                              nrain = nrain,                 &
!                              prate = prate,                 &
!                              dbz = qdiag(ibdq,jbdq,kbdq,qd_dbz), &
!                              ruh = ruh, rvh = rvh, rmh = rmh, &
!                              dx = dx, dy = dy,              &
!                              tcond = qbudget(1),            &
!                              tevac = qbudget(2),            &
!                              tevar = qbudget(5),            &
!                              train = qbudget(6),            &
!                              rr    = dum3,                  &
!                              diagflag = getdbz,             &
!                  ib3d=ib3d,ie3d=ie3d,jb3d=jb3d,je3d=je3d,kb3d=kb3d,ke3d=ke3d, &
!                  nout3d=nout3d,out3d=out3d,                                 &
!                              ims = ib ,ime = ie , jms = jb ,jme = je, kms = kb,kme = ke,  &  
!                              its = 1 ,ite = ni, jts = 1,jte = nj, kts = 1,kte = nk)
!          
          ENDIF

        IF(eqtset.eq.2)THEN
          ! for mass conservation:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            if( abs(dum4(i,j,k)-thten(i,j,k)).ge.tsmall .or.  &
                abs(q3d(i,j,k,nqv)-qten(i,j,k,nqv)).ge.qsmall )then
              prs(i,j,k) = rho(i,j,k)*rd*dum4(i,j,k)*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps)
              pp3d(i,j,k) = (prs(i,j,k)*rp00)**rovcp - pi0(i,j,k)
              th3d(i,j,k) = dum4(i,j,k)*dum1(i,j,k)/(pi0(i,j,k)+pp3d(i,j,k)) - th0(i,j,k)
            endif
          enddo
          enddo
          enddo
        ELSE
          ! traditional thermodynamics:  p,pi remain unchanged
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            if( abs(dum4(i,j,k)-thten(i,j,k)).ge.tsmall .or.  &
                abs(q3d(i,j,k,nqv)-qten(i,j,k,nqv)).ge.qsmall )then
              th3d(i,j,k)= dum4(i,j,k) - th0(i,j,k)
              rho(i,j,k)=prs(i,j,k)/(rd*dum4(i,j,k)*dum1(i,j,k)*(1.0+q3d(i,j,k,nqv)*reps))
            endif
          enddo
          enddo
          enddo
        ENDIF

          if(timestats.ge.1) time_microphy=time_microphy+mytime()

!
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!  insert new microphysics schemes here
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!        ELSEIF(ptype.eq.8)THEN
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
! otherwise, stop for undefined ptype
        ELSE
          print *,'  Undefined ptype!'
          call stopcm1
        ENDIF  ifptype

!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CC   END microphysics   CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
!CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

          if( dotbud .and. td_mp.ge.1 )then
            rdt = 1.0/dt
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              tdiag(i,j,k,td_mp) = (th3d(i,j,k)-tdiag(i,j,k,td_mp))*rdt
            enddo
            enddo
            enddo
          endif
          if( doqbud .and. qd_mp.ge.1 )then
            rdt = 1.0/dt
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,nk
            do j=1,nj
            do i=1,ni
              qdiag(i,j,k,qd_mp) = (q3d(i,j,k,nqv)-qdiag(i,j,k,qd_mp))*rdt
            enddo
            enddo
            enddo
          endif

        if(timestats.ge.1) time_microphy=time_microphy+mytime()

      ENDIF  ifmp

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!Begin:  message passing

          call bcs(pp3d)
#ifdef MPI
          call comm_1s_start(pp3d,vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,reqs_x)
#endif
          call bcs(th3d)
#ifdef MPI
          call comm_3s_start(th3d,rw31,rw32,re31,re32,   &
                                  rs31,rs32,rn31,rn32,reqs_y)
#endif
          call bcs(rho)
#ifdef MPI
          call comm_1s_start(rho,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
#endif

      IF( imoist.eq.1 )THEN
          DO n=1,numq
            call bcs(q3d(ib,jb,kb,n))
#ifdef MPI
            call comm_3s_start(q3d(ib,jb,kb,n)  &
                       ,qw31(1,1,1,n),qw32(1,1,1,n),qe31(1,1,1,n),qe32(1,1,1,n)     &
                       ,qs31(1,1,1,n),qs32(1,1,1,n),qn31(1,1,1,n),qn32(1,1,1,n)     &
                       ,reqs_q(1,n) )
#endif
          ENDDO
      ENDIF

!-----------------------------------------------------------------

      IF( psolver.eq.2 .or. psolver.eq.3 .or. psolver.eq.6 )THEN
        ! 180212: moved this out of sound,sounde,soundcb

        if( psolver.eq.2 .or. psolver.eq.3 )then

          !$omp parallel do default(shared)   &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ppx(i,j,k)=pp3d(i,j,k)+ppx(i,j,k)
          enddo
          enddo
          enddo

        elseif( psolver.eq.6 )then

          !$omp parallel do default(shared)   &
          !$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            ppx(i,j,k)=phi1(i,j,k)+ppx(i,j,k)
          enddo
          enddo
          enddo

        endif

        call bcs(ppx)
#ifdef MPI
        call comm_1s_start(ppx,zw1,zw2,ze1,ze2,zs1,zs2,zn1,zn2,reqs_z)
#endif

      ENDIF

!-----------------------------------------------------------------

!Done:  message passing
!-----------------------------------------------------------------
!  cm1r17:  diabatic tendencies for next timestep:

        IF(imoist.eq.1.and.eqtset.eq.2)THEN
          ! get diabatic tendencies (will be used in next timestep):
          rdt = 1.0/dt
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=1,nj
          do i=1,ni
            qpten(i,j,k)=(pp3d(i,j,k)-qpten(i,j,k))*rdt
            qtten(i,j,k)=(th3d(i,j,k)-qtten(i,j,k))*rdt
            qvten(i,j,k)=(q3d(i,j,k,nqv)-qvten(i,j,k))*rdt
            qcten(i,j,k)=(q3d(i,j,k,nqc)-qcten(i,j,k))*rdt
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_microphy=time_microphy+mytime()
        ENDIF

!-----------------------------------------------------------------
!  Equate the two arrays

#ifdef MPI
      call comm_3u_end(u3d,uw31,uw32,ue31,ue32,   &
                           us31,us32,un31,un32,reqs_u)
      call comm_3v_end(v3d,vw31,vw32,ve31,ve32,   &
                           vs31,vs32,vn31,vn32,reqs_v)
      call comm_3w_end(w3d,ww31,ww32,we31,we32,   &
                           ws31,ws32,wn31,wn32,reqs_w)
#endif

      if(terrain_flag)then
        call bcwsfc(gz,dzdx,dzdy,u3d,v3d,w3d)
        call bc2d(w3d(ib,jb,1))
      endif

!----------
!  comms for parcels:

      IF(iprcl.eq.1)THEN
        ! cm1r18:  use velocities averaged over small time steps (for psolver=2,3,6)
        IF( psolver.eq.2 .or. psolver.eq.3 .or. psolver.eq.6 )THEN
          ! 180713:  now saved in ten1 arrays
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=1,nk
            do j=1,nj
            do i=1,ni+1
              rru(i,j,k)=uten1(i,j,k)
            enddo
            enddo
            IF(axisymm.eq.0)THEN
              ! Cartesian grid:
              do j=1,nj+1
              do i=1,ni
                rrv(i,j,k)=vten1(i,j,k)
              enddo
              enddo
            ENDIF
            IF(k.gt.1)THEN
              do j=1,nj
              do i=1,ni
                rrw(i,j,k)=wten1(i,j,k)
              enddo
              enddo
            ENDIF
          enddo
        ELSE
          ! psolver=1,4,5:
!$omp parallel do default(shared)   &
!$omp private(i,j,k)
          do k=1,nk
            do j=1,nj
            do i=1,ni+1
              rru(i,j,k)=u3d(i,j,k)
            enddo
            enddo
            IF(axisymm.eq.0)THEN
              ! Cartesian grid:
              do j=1,nj+1
              do i=1,ni
                rrv(i,j,k)=v3d(i,j,k)
              enddo
              enddo
            ENDIF
            IF(k.gt.1)THEN
              do j=1,nj
              do i=1,ni
                rrw(i,j,k)=w3d(i,j,k)
              enddo
              enddo
            ENDIF
          enddo
        ENDIF
        if(timestats.ge.1) time_parcels=time_parcels+mytime()
        ! bc/comms:
        call bcu(rru)
#ifdef MPI
        call comm_3u_start(rru,uw31,uw32,ue31,ue32,us31,us32,un31,un32,reqs_u)
#endif
        call bcv(rrv)
#ifdef MPI
        call comm_3v_start(rrv,vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,reqs_v)
#endif
        call bcw(rrw,1)
#ifdef MPI
        call comm_3w_start(rrw,ww31,ww32,we31,we32,ws31,ws32,wn31,wn32,reqs_w)
#endif
      ENDIF

!----------

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        do j=0,nj+1
        do i=0,ni+2
          ua(i,j,k)=u3d(i,j,k)
        enddo
        enddo
        do j=0,nj+2
        do i=0,ni+1
          va(i,j,k)=v3d(i,j,k)
        enddo
        enddo
        do j=0,nj+1
        do i=0,ni+1
          wa(i,j,k)=w3d(i,j,k)
        enddo
        enddo
      enddo
      if(timestats.ge.1) time_integ=time_integ+mytime()

!----------

      if(sgsmodel.eq.1)then
#ifdef MPI
        call comm_3t_end(tke3d,tkw1,tkw2,tke1,tke2,   &
                               tks1,tks2,tkn1,tkn2,reqs_tk)
#endif
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk+1
        do j=0,nj+1
        do i=0,ni+1
          tkea(i,j,k)=tke3d(i,j,k)
        enddo
        enddo
        enddo
        if(timestats.ge.1) time_integ=time_integ+mytime()
      endif

!----------

      if(iptra.eq.1)then
        do n=1,npt
#ifdef MPI
          call comm_3s_end(pt3d(ib,jb,kb,n),                           &
                tw1(1,1,1,n),tw2(1,1,1,n),te1(1,1,1,n),te2(1,1,1,n),   &
                ts1(1,1,1,n),ts2(1,1,1,n),tn1(1,1,1,n),tn2(1,1,1,n),   &
                reqs_t(1,n))
#endif
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,nk
          do j=0,nj+1
          do i=0,ni+1
            pta(i,j,k,n)=pt3d(i,j,k,n)
          enddo
          enddo
          enddo
          if(timestats.ge.1) time_integ=time_integ+mytime()
        enddo
      endif

!----------

#ifdef MPI
      call comm_1s_end(pp3d,vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,reqs_x)
#endif
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        do j=0,nj+1
        do i=0,ni+1
          ppi(i,j,k)=pp3d(i,j,k)
        enddo
        enddo
      enddo
      if(timestats.ge.1) time_integ=time_integ+mytime()

!----------

#ifdef MPI
      call comm_3s_end(th3d,rw31,rw32,re31,re32,   &
                            rs31,rs32,rn31,rn32,reqs_y)
#endif
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
        do j=0,nj+1
        do i=0,ni+1
          tha(i,j,k)=th3d(i,j,k)
        enddo
        enddo
      enddo
      if(timestats.ge.1) time_integ=time_integ+mytime()

!----------

#ifdef MPI
        call comm_1s_end(rho,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
        call getcorner(rho,nw1(1),nw2(1),ne1(1),ne2(1),sw1(1),sw2(1),se1(1),se2(1))
        call bcs2(rho)
#endif

      !$omp parallel do default(shared)  &
      !$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          rr(i,j,k) = 1.0/rho(i,j,k)
          rf(i,j,k) = (c1(i,j,k)*rho(i,j,k-1)+c2(i,j,k)*rho(i,j,k))
        enddo
        enddo
        enddo

        ! meh 1 !
      !$omp parallel do default(shared)  &
      !$omp private(i,j,k)
        do j=1,nj
        do i=1,ni
          ! cm1r17, 2nd-order extrapolation:
          rf(i,j,1) = cgs1*rho(i,j,1)+cgs2*rho(i,j,2)+cgs3*rho(i,j,3)
          rf(i,j,nk+1) = cgt1*rho(i,j,nk)+cgt2*rho(i,j,nk-1)+cgt3*rho(i,j,nk-2)
        enddo
        enddo

        if(timestats.ge.1) time_prsrho=time_prsrho+mytime()

        call bcs(rr)
#ifdef MPI
        call comm_1s_start(rr,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
#endif
        call bcs(rf)
#ifdef MPI
        call comm_1s_start(rf,vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,reqs_x)
#endif

!----------

      if(imoist.eq.1)then
        DO n=1,numq
#ifdef MPI
          call comm_3s_end(q3d(ib,jb,kb,n)  &
                     ,qw31(1,1,1,n),qw32(1,1,1,n),qe31(1,1,1,n),qe32(1,1,1,n)     &
                     ,qs31(1,1,1,n),qs32(1,1,1,n),qn31(1,1,1,n),qn32(1,1,1,n)     &
                     ,reqs_q(1,n) )
#endif
          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,nk
          do j=0,nj+1
          do i=0,ni+1
            qa(i,j,k,n)=q3d(i,j,k,n)
          enddo
          enddo
          enddo
        ENDDO
        if(timestats.ge.1) time_integ=time_integ+mytime()
      endif

!----------

#ifdef MPI
        !-----
        call comm_1s_end(rr,pw1,pw2,pe1,pe2,ps1,ps2,pn1,pn2,reqs_s)
        call getcorner(rr,nw1(1),nw2(1),ne1(1),ne2(1),sw1(1),sw2(1),se1(1),se2(1))
        call bcs2(rr)
        !-----
        call comm_1s_end(rf,vw1,vw2,ve1,ve2,vs1,vs2,vn1,vn2,reqs_x)
        call getcorner(rf,nw1(1),nw2(1),ne1(1),ne2(1),sw1(1),sw2(1),se1(1),se2(1))
        call bcs2(rf)
        !-----
#endif

!-----------------------------------------------------------------

#ifdef MPI
      IF( psolver.eq.2 .or. psolver.eq.3 .or. psolver.eq.6 )THEN
        call comm_1p_end(ppx,zw1,zw2,ze1,ze2,zs1,zs2,zn1,zn2,reqs_z)
      ENDIF
#endif

!-----------------------------------------------------------------

!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!cc  Update parcel locations  ccccccccccccccccccccccccccccccccccccccc
!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      IF(iprcl.eq.1)THEN
        !  get corner info, ghost zone data, etc:
        !  (may not parallelize correctly if this is not done)
#ifdef MPI
        call comm_3u_end( rru,uw31,uw32,ue31,ue32,us31,us32,un31,un32,reqs_u)
        call comm_3v_end( rrv,vw31,vw32,ve31,ve32,vs31,vs32,vn31,vn32,reqs_v)
        call comm_3w_end( rrw,ww31,ww32,we31,we32,ws31,ws32,wn31,wn32,reqs_w)
        call getcorneru3(rru,n3w1(1,1,1),n3w2(1,1,1),n3e1(1,1,1),n3e2(1,1,1),  &
                             s3w1(1,1,1),s3w2(1,1,1),s3e1(1,1,1),s3e2(1,1,1))
        call getcornerv3(rrv,n3w1(1,1,1),n3w2(1,1,1),n3e1(1,1,1),n3e2(1,1,1),  &
                             s3w1(1,1,1),s3w2(1,1,1),s3e1(1,1,1),s3e2(1,1,1))
        call getcornerw3(rrw,n3w1,n3w2,n3e1,n3e2,s3w1,s3w2,s3e1,s3e2)
        call bcu2(rru)
        call bcv2(rrv)
        call bcw2(rrw)
#endif

        prltrn:  &
        if(terrain_flag)then
          ! 180713:  get sigma-dot

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          DO k=1,nk
            do j=0,nj+1
            do i=0,ni+2
              rru(i,j,k)=rru(i,j,k)*rgzu(i,j)
            enddo
            enddo
            do j=0,nj+2
            do i=0,ni+1
              rrv(i,j,k)=rrv(i,j,k)*rgzv(i,j)
            enddo
            enddo
          ENDDO

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,r1,r2)
          DO k=1,nk
            IF(k.eq.1)THEN
              do j=0,nj+1
              do i=0,ni+1
                rrw(i,j,   1) = 0.0
                rrw(i,j,nk+1) = 0.0
              enddo
              enddo
            ELSE
              r2 = (sigmaf(k)-sigma(k-1))*rds(k)
              r1 = 1.0-r2
              r1 = 0.5*r1
              r2 = 0.5*r2
              do j=0,nj+1
              do i=0,ni+1
                rrw(i,j,k)=rrw(i,j,k)                              &
                          +( ( r2*(rru(i,j,k  )+rru(i+1,j,k  ))               &
                              +r1*(rru(i,j,k-1)+rru(i+1,j,k-1)) )*dzdx(i,j)   &
                            +( r2*(rrv(i,j,k  )+rrv(i,j+1,k  ))               &
                              +r1*(rrv(i,j,k-1)+rrv(i,j+1,k-1)) )*dzdy(i,j)   &
                           )*(sigmaf(k)-zt)*gz(i,j)*rzt
              enddo
              enddo
            ENDIF
          ENDDO

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k,r1,r2)
          do k=1,nk
          do j=0,nj+2
          do i=0,ni+2
            rru(i,j,k) = rru(i,j,k)*gzu(i,j)
            rrv(i,j,k) = rrv(i,j,k)*gzv(i,j)
            rrw(i,j,k) = rrw(i,j,k)*gz(i,j)
          enddo
          enddo
          enddo

        endif  prltrn

        call     parcel_driver(dt,xh,uh,ruh,xf,yh,vh,rvh,yf,zh,mh,rmh,zf,mf,zs,    &
                               sigma,sigmaf,znt,rho,rru,rrv,rrw,pdata)
        if(timestats.ge.1) time_parcels=time_parcels+mytime()
      ENDIF


!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!cc   All done   cccccccccccccccccccccccccccccccccccccccccccccccccccc
!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc


      ! cm1r19.6  (preliminary ... needs more testing)
      IF( imove.eq.1 )THEN
      IF( (sfcmodel.eq.2) .or. (sfcmodel.eq.3) .or. (sfcmodel.eq.4) )THEN

        weps = 0.0001*epsilon
        call movesfc(0.0,dt,weps,uh,vh,znt(ib,jb),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))

        weps = 1.0*epsilon
        call movesfc(0.0,dt,weps,uh,vh,ust(ib,jb),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))

        weps = 100.0*epsilon
        call movesfc(0.0,dt,weps,uh,vh,hfx(ibl,jbl),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))

        weps = 1.0e-6*epsilon
        call movesfc(0.0,dt,weps,uh,vh,qfx(ibl,jbl),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
        call movesfc(0.0,dt,weps,uh,vh,qsfc(ibl,jbl),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))

        weps = 200.0*epsilon
        call movesfc(0.0,dt,weps,uh,vh,tsk(ib,jb),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
        call movesfc(0.0,dt,weps,uh,vh,tmn(ibl,jbl),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
        do n=1,num_soil_layers
        call movesfc(0.0,dt,weps,uh,vh,tslb(ibl,jbl,n),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
        enddo

      ENDIF
      ENDIF


!!!#ifdef MPI
!!!      call MPI_BARRIER (MPI_COMM_WORLD,ierr)
!!!      if(timestats.ge.1) time_mpb=time_mpb+mytime()
!!!#endif

!--------------------------------------------------------------------
!  Calculate surface "swaths."  Move surface (if necessary). 
!--------------------------------------------------------------------

    IF( output_rain.eq.1 )THEN

      if(imove.eq.1.and.imoist.eq.1)then
        weps = 10.0*epsilon
        call movesfc(0.0,dt,weps,uh,vh,rain(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

    ENDIF

!--------------------------------------------------------------------
! Maximum horizontal wind speed at lowest model level: 
! (include domain movement in calculation)

    IF( output_sws.eq.1 )THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,n,tem)
      do j=1,nj
      do i=1,ni
        tem = sqrt( (umove+0.5*(ua(i,j,1)+ua(i+1,j,1)))**2    &
                   +(vmove+0.5*(va(i,j,1)+va(i,j+1,1)))**2 ) 
        do n=1,nrain
          sws(i,j,n)=max(sws(i,j,n),tem)
        enddo
      enddo
      enddo
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 10.0*epsilon
        call movesfc(0.0,dt,weps,uh,vh,sws(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3),  &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

    ENDIF

!--------------------------------------------------------------------
!  Maximum vertical vorticity at lowest model level:

  IF( output_svs.eq.1 )THEN

  IF(axisymm.eq.0)THEN
    IF(.not.terrain_flag)THEN
      ! Cartesian grid, without terrain:
!$omp parallel do default(shared)  &
!$omp private(i,j,n,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,1)-va(i-1,j,1))*rdx*uf(i)   &
             -(ua(i,j,1)-ua(i,j-1,1))*rdy*vf(j)
        do n=1,nrain
          svs(i,j,n)=max(svs(i,j,n),tem)
        enddo
      enddo
      enddo
    ELSE
      ! Cartesian grid, with terrain:
      ! dum1 stores u at w-pts:
      ! dum2 stores v at w-pts:
!$omp parallel do default(shared)   &
!$omp private(i,j,k,r1,r2)
      do j=0,nj+2
        ! lowest model level:
        do i=0,ni+2
          dum1(i,j,1) = cgs1*ua(i,j,1)+cgs2*ua(i,j,2)+cgs3*ua(i,j,3)
          dum2(i,j,1) = cgs1*va(i,j,1)+cgs2*va(i,j,2)+cgs3*va(i,j,3)
        enddo
        ! interior:
        do k=2,2
        r2 = (sigmaf(k)-sigma(k-1))*rds(k)
        r1 = 1.0-r2
        do i=0,ni+2
          dum1(i,j,k) = r1*ua(i,j,k-1)+r2*ua(i,j,k)
          dum2(i,j,k) = r1*va(i,j,k-1)+r2*va(i,j,k)
        enddo
        enddo
      enddo
      k = 1
!$omp parallel do default(shared)  &
!$omp private(i,j,n,r1,tem)
      do j=1,nj+1
      do i=1,ni+1
        r1 = zt/(zt-0.25*((zs(i-1,j-1)+zs(i,j))+(zs(i-1,j)+zs(i,j-1))))
        tem = ( r1*(va(i,j,k)*rgzv(i,j)-va(i-1,j,k)*rgzv(i-1,j))*rdx*uf(i)  &
               +0.5*( (zt-sigmaf(k+1))*(dum2(i-1,j,k+1)+dum2(i,j,k+1))      &
                     -(zt-sigmaf(k  ))*(dum2(i-1,j,k  )+dum2(i,j,k  ))      &
                    )*rdsf(k)*r1*(rgzv(i,j)-rgzv(i-1,j))*rdx*uf(i) )        &
             -( r1*(ua(i,j,k)*rgzu(i,j)-ua(i,j-1,k)*rgzu(i,j-1))*rdy*vf(j)  &
               +0.5*( (zt-sigmaf(k+1))*(dum1(i,j-1,k+1)+dum1(i,j,k+1))      &
                     -(zt-sigmaf(k  ))*(dum1(i,j-1,k  )+dum1(i,j,k  ))      &
                    )*rdsf(k)*r1*(rgzu(i,j)-rgzu(i,j-1))*rdy*vf(j) )
        do n=1,nrain
          svs(i,j,n)=max(svs(i,j,n),tem)
        enddo
      enddo
      enddo
    ENDIF
  ELSE
      ! Axisymmetric grid:
!$omp parallel do default(shared)  &
!$omp private(i,j,n,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,1)*xh(i)-va(i-1,j,1)*xh(i-1))*rdx*uf(i)*rxf(i)
        do n=1,nrain
          svs(i,j,n)=max(svs(i,j,n),tem)
        enddo
      enddo
      enddo
  ENDIF
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 1.0*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,svs(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

  ENDIF

!--------------------------------------------------------------------
!  Minimum pressure perturbation at lowest model level:

  IF( output_sps.eq.1 )THEN

!$omp parallel do default(shared)  &
!$omp private(i,j,n,tem)
      do j=1,nj
      do i=1,ni
        tem = prs(i,j,1)-prs0(i,j,1)
        do n=1,nrain
          sps(i,j,n)=min(sps(i,j,n),tem)
        enddo
      enddo
      enddo
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 1000.0*epsilon
        call movesfc(-200000.0,dt,weps,uh,vh,sps(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

  ENDIF

!--------------------------------------------------------------------
!  Maximum rainwater mixing ratio (qr) at lowest model level:

  IF( output_srs.eq.1 )THEN

    IF(imoist.eq.1.and.nqr.ne.0)THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,n,tem)
      do j=1,nj
      do i=1,ni
        tem = qa(i,j,1,nqr)
        do n=1,nrain
          srs(i,j,n)=max(srs(i,j,n),tem)
        enddo
      enddo
      enddo
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(0.0,dt,weps,uh,vh,srs(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3),  &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif
    ENDIF

  ENDIF

!--------------------------------------------------------------------
!  Maximum graupel/hail mixing ratio (qg) at lowest model level:

  IF( output_sgs.eq.1 )THEN

    IF(imoist.eq.1.and.nqg.ne.0)THEN
!$omp parallel do default(shared)  &
!$omp private(i,j,n,tem)
      do j=1,nj
      do i=1,ni
        tem = qa(i,j,1,nqg)
        do n=1,nrain
          sgs(i,j,n)=max(sgs(i,j,n),tem)
        enddo
      enddo
      enddo
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(0.0,dt,weps,uh,vh,sgs(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3),  &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif
    ENDIF

  ENDIF

!--------------------------------------------------------------------

  IF( output_sus.eq.1 )THEN

      ! get height AGL:
      if( .not. terrain_flag )then
        ! without terrain:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk+1
        do j=1,nj
        do i=1,ni
          dum3(i,j,k) = zh(i,j,k)
          wten(i,j,k) = zf(i,j,k)
        enddo
        enddo
        enddo
      else
        ! get height AGL:
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk+1
        do j=1,nj
        do i=1,ni
          dum3(i,j,k) = zh(i,j,k)-zs(i,j)
          wten(i,j,k) = zf(i,j,k)-zs(i,j)
        enddo
        enddo
        enddo
      endif

!--------------------------------------------------------------------
!  Maximum updraft velocity (w) at 5 km AGL:

!$omp parallel do default(shared)  &
!$omp private(i,j,k,n,tem)
      do j=1,nj
      do i=1,ni
        k = 2
        ! wten is height AGL:
        do while( wten(i,j,k).lt.5000.0 .and. k.lt.nk )
          k = k + 1
        enddo
        tem = w3d(i,j,k)
        do n=1,nrain
          sus(i,j,n)=max(sus(i,j,n),tem)
        enddo
      enddo
      enddo
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 10.0*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,sus(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

    ENDIF

!--------------------------------------------------------------------
!  Maximum integrated updraft helicity:

    IF( output_shs.eq.1 )THEN

      ! dum3 is zh (agl), wten is zf (agl)
      call calcuh(uf,vf,dum3,wten,ua,va,wa,dum1(ib,jb,1),dum2,dum5,dum6, &
                  zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf)
!$omp parallel do default(shared)  &
!$omp private(i,j,n)
      do j=1,nj
      do i=1,ni
        do n=1,nrain
          shs(i,j,n)=max(shs(i,j,n),dum1(i,j,1))
        enddo
      enddo
      enddo
      if(timestats.ge.1) time_swath=time_swath+mytime()

      if(imove.eq.1)then
        weps = 100.0*epsilon
        call movesfc(0.0,dt,weps,uh,vh,shs(ib,jb,2),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3),  &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

    ENDIF

!  Done with "swaths"
!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!  Pressure decomposition:

    ifpdcomp:  &
    IF( pdcomp )THEN
    IF( dowriteout .or. doazimwrite )THEN

      if(myid.eq.0) print *,'  Getting pressure diagnostics ... '

      call       pidcomp(dt,xh,rxh,arh1,arh2,uh,xf,rxf,arf1,arf2,uf,vh,vf,          &
                         gz,rgz,gzu,gzv,mh,rmh,mf,rmf,rds,rdsf,c1,c2,f2d,wprof,     &
                         pi0,th0,rth0,thv0,qv0,qc0,qi0,rho0,rr0,rf0,rrf0,u0,v0,     &
                         dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,divx,              &
                         u3d,rru,uten,uten1,v3d,rrv,vten,vten1,w3d,rrw,wten,wten1,  &
                         rho,pp3d,th3d,q3d,udiag,vdiag,wdiag,pdiag,                 &
                         cfb,cfa,cfc,ad1,ad2,pdt,lgbth,lgbph,rhs,trans)

      if(myid.eq.0) print *,'  ... finished pressure diagnostics '

      if(timestats.ge.1) time_poiss=time_poiss+mytime()

    ENDIF
    ENDIF  ifpdcomp

!  end pressure decomposition.
!cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

!--------------------------------------------------------------------
      ! all done

      end subroutine solve

  END MODULE solve_module
