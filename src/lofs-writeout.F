#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

      subroutine writeout_hdf5(qname,xh,xf,uf,uh,yh,yf,vf,vh,                                        &
                          rds,sigma,rdsf,sigmaf,zh,mh,zf,mf,pi0,prs0,rho0,th0,qv0,u0,v0,             &
                          zs,gz,gzu,gzv,gxu,gyv,rgz,rgzu,rgzv,rain,sws,svs,sps,srs,sgs,sus,shs,      &
                          dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,dum9,qa,                       &
                          t11,t12,rho,prs,ua,va,wa,ppi,tha,tkea,kmh,kmv,khh,khv,                     &
                          znt,ust,u1,v1,s1,rr,tdiag,qdiag,udiag,vdiag,wdiag,pdiag)

      use misclibs, only : calcvort
      character*3, dimension(maxq), intent(in) :: qname
      real, dimension(ib:ie), intent(in) :: xh,uh
      real, dimension(ib:ie+1), intent(in) :: xf,uf
      real, dimension(jb:je), intent(in) :: yh,vh
      real, dimension(jb:je+1), intent(in) :: yf,vf
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: zh
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: zf,mf
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: pi0,prs0,rho0,th0,qv0
      real, dimension(ib:ie,jb:je,nrain), intent(in) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, dimension(ib:ie,jb:je,kb:ke), intent(inout) :: dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,dum9
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: ppi,prs,tha,rho,t11,t12
      real, dimension(ibt:iet,jbt:jet,kbt:ket), intent(in) :: tkea
      real, intent(in), dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv
      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq), intent(in) :: qa
      real, dimension(ib:ie+1,jb:je,kb:ke), intent(in) :: u0,ua
      real, dimension(ib:ie,jb:je+1,kb:ke), intent(in) :: v0,va
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: wa
      real, dimension(kb:ke), intent(in) :: rds,sigma
      real, dimension(kb:ke+1), intent(in) :: rdsf,sigmaf
      real, dimension(itb:ite,jtb:jte), intent(in) :: zs,rgzu,rgzv,gz,rgz,gzu,gzv
      real, dimension(ib:ie,jb:je), intent(in) :: znt,ust,u1,v1,s1
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rr
      real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gxu,gyv
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: mh
      real, intent(in) , dimension(ibdt:iedt,jbdt:jedt,kbdt:kedt,ntdiag) :: tdiag
      real, intent(in) , dimension(ibdq:iedq,jbdq:jedq,kbdq:kedq,nqdiag) :: qdiag
      real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nudiag) :: udiag
      real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nvdiag) :: vdiag
      real, intent(in) , dimension(ibdv:iedv,jbdv:jedv,kbdv:kedv,nwdiag) :: wdiag
      real, intent(in) , dimension(ibdp:iedp,jbdp:jedp,kbdp:kedp,npdiag) :: pdiag !shared memory only

      integer i,j,k,n

    nkwrite=nk !ORF TODO fix
    call h5_prelim(xh,xf,yh,yf,zh,zf,pi0,th0,prs0,rho0,qv0,u0,v0)

1101 format('DEBUG: myid = ',I2.2,' A')
1102 format('DEBUG: myid = ',I2.2,' B')
1103 format('DEBUG: myid = ',I2.2,' ',L2,' A')
1104 format('DEBUG: myid = ',I2.2,' ',L2,' B')

    if(imoist.eq.1.and.output_rain_accum.eq.1) then
        varname = "rain_sfc"
        description="accumulated surface rainfall"
        units="cm"
        var2d(:,:) = rain(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1) then
            varname = "rain_sfc_move"
            description="accumulated surface rainfall, transalted with the moving domain"
            units="cm"
            var2d(:,:) = rain(1:ni,1:nj,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
         endif
    endif

    if(output_w_min_0500.eq.1) then
        varname = "w_min_0500"
        description='minmum downdraft at 500 meters'
        units='m/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1) then
            varname = "w_min_0500_move"
            description='minmum downdraft at 500 meters, translated with the moving domain'
            units='m/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,1)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_w_min_1000.eq.1) then
        varname = "w_min_1000"
        description='minmum downdraft at 1 km'
        units='m/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,2)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1) then
            varname = "w_min_1000_move"
            description='minmum downdraft at 1 km, translated with the moving domain'
            units='m/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_w_max_1000.eq.1) then
        varname = "w_max_1000"
        description='maximum updraft at 1 km'
        units='m/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,3)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "w_max_1000_move"
            description='maximum updraft at 1 km, translated with the moving domain'
            units='m/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,3)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_w_max_5000.eq.1) then
        varname = "w_max_5000"
        description='maximum updraft at 5 km'
        units='m/s'
        var2d(:,:) = sus(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "w_max_5000_move"
            description='maximum updraft at 5 km, translated with the moving domain'
            units='m/s'
            var2d(:,:) = sus(1:ni,1:nj,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_w_max_0500.eq.1) then
        varname = "w_max_0500"
        description='maximum updraft at 500 m'
        units='m/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,4)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "w_max_0500_move"
            description='maximum updraft at 500 m, translated with the moving domain'
            units='m/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,4)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_0500.eq.1) then
        varname = "zeta_max_0500"
        description='maximum vertical vorticity at 500 m'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,5)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_0500_move"
            description='maximum vertical vorticity at 500 m, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,5)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_1000.eq.1) then
        varname = "zeta_max_1000"
        description='maximum vertical vorticity at 1 km'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,6)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_1000_move"
            description='maximum vertical vorticity at 1km, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,6)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_2000.eq.1) then
        varname = "zeta_max_2000"
        description='maximum vertical vorticity at 2 km'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,7)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_2000_move"
            description='maximum vertical vorticity at 2km, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,7)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_sfc.eq.1) then
        varname = "zeta_max_sfc"
        description='maximum vertical vorticity at lowest model grid level'
        units='/s'
        var2d(:,:) = svs(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_sfc_move"
            description='maximum vertical vorticity at 2km, translated with the moving domain'
            units='/s'
            var2d(:,:) = svs(1:ni,1:nj,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_hwin_max_sfc.eq.1) then
        varname = "hwin_max_sfc"
        description='maximum horizontal wind speed at lowest model grid level'
        units='m/s'
        var2d(:,:) = sws(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "hwin_max_sfc_move"
            description='maximum horizontal wind speed at lowest model grid level, translated with the moving domain'
            units='m/s'
            var2d(:,:) = sws(1:ni,1:nj,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_sfc.eq.1) then
        varname = "zeta_min_sfc"
        description='minimum vertical vorticity at lowest model grid level'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,8)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_sfc_move"
            description='minimum vertical vorticity at lowest model grid level, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,8)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_0500.eq.1) then
        varname = "zeta_min_0500"
        description='minimum vertical vorticity at 500 m'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,9)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_0500_move"
            description='minimum vertical vorticity at 500 m, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,9)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_1000.eq.1) then
        varname = "zeta_min_1000"
        description='minimum vertical vorticity at 1 km'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,10)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_1000_move"
            description='minimum vertical vorticity at 1 km, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,10)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_2000.eq.1) then
        varname = "zeta_min_2000"
        description='minimum vertical vorticity at 2 km'
        units='/s'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,11)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_2000_move"
            description='minimum vertical vorticity at 2 km, translated with the moving domain'
            units='/s'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,11)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_prespert_min_sfc.eq.1) then
        varname = "prespert_min_sfc"
        description='minimum perturbation pressure at lowest model grid level'
        units='hPa'
        var2d(:,:) = sps(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "prespert_min_sfc_move"
            description='minimum perturbation pressure at lowest model grid level, translated with the moving domain'
            units='hPa'
            var2d(:,:) = sps(1:ni,1:nj,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_prespert_min_1000.eq.1) then
        varname = "prespert_min_1000"
        description='minimum perturbation pressure at 1 km'
        units='hPa'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,12)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "prespert_min_1000_move"
            description='minimum perturbation pressure at 1 km, translated with the moving domain'
            units='hPa'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,12)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_prespert_min_2000.eq.1) then
        varname = "prespert_min_2000"
        description='minimum perturbation pressure at 2 km'
        units='hPa'
        var2d(:,:) = lofs_swaths(1:ni,1:nj,1,13)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "prespert_min_2000_move"
            description='minimum perturbation pressure at 2 km, translated with the moving domain'
            units='hPa'
            var2d(:,:) = lofs_swaths(1:ni,1:nj,2,13)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_snapshot_thrho_sfc.eq.1) then
        varname = "snapshot_thrho_sfc"
        description='snapshot of density potential temperature perturbation at lowest model grid level'
        units='K'
        call calc_thrho_pert(th0,tha,qa,qv0,dum1,lofstmp1)
        var2d(:,:) = lofstmp1(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(imoist.eq.1.and.output_snapshot_dbz_0500.eq.1) then
        varname = "snapshot_dbz_0500"
        description='snapshot of calculated reflectivity at 500 m'
        units='dBZ'
!       var2d(:,:) = dbz(1:ni,1:nj,k500)
        var2d(:,:) = qdiag(1:ni,1:nj,k500,qd_dbz)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_snapshot_w_0500.eq.1) then
        varname = "snapshot_w_0500"
        description='snapshot of w at 500 m'
        units='m/s'
        var2d(:,:) = wa(1:ni,1:nj,kw500)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_snapshot_prespert_sfc.eq.1) then
        varname = "snapshot_prespert_sfc"
        description='snapshot of pressure at lowest model grid level'
        units='hPa'
        var2d(:,:) = 0.01*(prs(1:ni,1:nj,ksfc)-p00*(pi0(1:ni,1:nj,ksfc)**cpdrd))
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_snapshot_prespert_0500.eq.1) then
        varname = "snapshot_prespert_0500"
        description='snapshot of pressure at 500 m'
        units='hPa'
        var2d(:,:) = 0.01*(prs(1:ni,1:nj,k500)-p00*(pi0(1:ni,1:nj,k500)**cpdrd))
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_snapshot_w_5000.eq.1) then
        varname = "snapshot_w_5000"
        description='snapshot of pressure at 5 km'
        units='m/s'
        var2d(:,:) = wa(1:ni,1:nj,kw5km)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(imoist.eq.1.and.output_snapshot_qc_1000.eq.1) then
        varname = "snapshot_qc_1000"
        description='snapshot of cloud water mixing ratio at 1 km'
        units='g/kg'
        var2d(:,:) = 1000.0*qa(1:ni,1:nj,k1km,nql1)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(imoist.eq.1.and.output_snapshot_qc_2000.eq.1) then
        varname = "snapshot_qc_2000"
        description='snapshot of cloud water mixing ratio at 2 km'
        units='g/kg'
        var2d(:,:) = 1000.0*qa(1:ni,1:nj,k2km,nql1)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_snapshot_u_sfc.eq.1) then
        varname = "snapshot_u_sfc"
        description='snapshot of u at lowest model grid level'
        units='m/s'
        do j=1,nj
        do i=1,ni
          var2d(i,j)=0.5*(ua(i,j,1)+ua(i+1,j,1))
        enddo
        enddo
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_snapshot_v_sfc.eq.1) then
        varname = "snapshot_v_sfc"
        description='snapshot of v at lowest model grid level'
        units='m/s'
        do j=1,nj
        do i=1,ni
          var2d(i,j)=0.5*(va(i,j,1)+va(i,j+1,1))
        enddo
        enddo
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(output_helicity_max_2_5km .eq.1) then
        varname = "helicity_max_2_5km"
        description='Integrated updraft helicity between 2 and 5 km'
        units='helicity'
        var2d(:,:) = shs(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "helicity_max_2_5km_move"
            description='Integrated updraft helicity between 2 and 5 km, translated with moving domain'
            units='helicity'
            var2d(:,:) = shs(1:ni,1:nj,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

! If we are not saving all vertical points we need to set dims(3) to
! nkwrite_val. Also make sure chunk dims is small enough so HDF doesn't barf
! (   chunkdims(3) .le. dims(3)   )

    if(output_u.eq.1) then
        varname="u"
        description = "u, on native C grid"
        units = "m/s"
        var3d(:,:,:)=ua(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,u_acc)
    endif

    if(output_uinterp.eq.1) then
        varname="uinterp"
        description = "u, interpolated to scalar mesh"
        units = "m/s"
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          var3d(i,j,k)=0.5*(ua(i,j,k)+ua(i+1,j,k))
        enddo
        enddo
        enddo
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,uinterp_acc)
    endif

    if(output_v.eq.1) then
        varname="v"
        description = "v, on native C grid"
        units = "m/s"
        var3d(:,:,:)=va(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,v_acc)
    endif

    if(output_rhopert.eq.1) then
        varname="rhopert"
        description = "density perturbation from base state"
        units = "kg/m^3"
        var3d(:,:,:)=rho(1:ni,1:nj,1:nk)-rho0(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,v_acc)
    endif

    if(output_vinterp.eq.1) then
        varname="vinterp"
        description = "v, interpolated to scalar mesh"
        units = "m/s"
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          var3d(i,j,k)=0.5*(va(i,j,k)+va(i,j+1,k))
        enddo
        enddo
        enddo
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vinterp_acc)
    endif

    if(output_w.eq.1) then
        varname="w"
        description = "w, on native C grid"
        units = "m/s"
        var3d(:,:,:)=wa(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,w_acc)
    endif

    if(output_winterp.eq.1) then
        varname="winterp"
        description = "w, interpolated to scalar mesh"
        units = "m/s"
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          var3d(i,j,k)=0.5*(wa(i,j,k)+wa(i,j,k+1))
        enddo
        enddo
        enddo
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,winterp_acc)
    endif

    if(output_xvort.eq.1.or.output_yvort.eq.1.or.output_zvort.eq.1.or.output_vortmag.eq.1) &
         call calcvort(xh,xf,uf,vf,zh,mh,zf,mf,                                           &
                          zs,gz,gzu,gzv,rgz,rgzu,rgzv,gxu,gyv,rds,sigma,rdsf,sigmaf,       &
                          ua,va,wa,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,th0,tha,rr,  &
                          ust,znt,u1,v1,s1)

!        call calcvort(xh,xf,uf,vf,zh,mf,zf,zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf,  &
!                     ua,va,wa,dum1,dum2,dum3,dum4,t11,t12)

    if(output_xvort.eq.1) then
        varname="xvort"
        description = "x component of vorticity (xi)"
        units = "/s"
        var3d(:,:,:) = dum1(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,xvort_acc)
    endif

    if(output_yvort.eq.1) then
        varname="yvort"
        description = "y component of vorticity (eta)"
        units = "/s"
        var3d(:,:,:) = dum2(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,yvort_acc)
    endif

    if(output_zvort.eq.1) then
        varname="zvort"
        description = "z component of vorticity (zeta)"
        units = "/s"
        var3d(:,:,:) = dum3(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,zvort_acc)
    endif

    if(output_vortmag.eq.1) then
        varname="vortmag"
        description = "magnitude of vorticity vector"
        units = "/s"
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,nk
        do j=1,nj
        do i=1,ni
          var3d(i,j,k)=sqrt(dum1(i,j,k)**2+dum2(i,j,k)**2+dum3(i,j,k)**2)
        enddo
        enddo
        enddo
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vortmag_acc)
    endif

    if(output_tke.eq.1) then
        varname="tke_sg"
        description = "Subgrid turbulence kinetic energy"
        units = "m^2/s^2"
        var3d(:,:,:) = tkea(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tke_acc)
    endif

    if(output_kh.eq.1) then
        varname="khh"
        description = "Subgrid eddy scalar diffusivity, horizontal"
        units = "m^2/s"
        var3d(:,:,:) = khh(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,kh_acc)

       varname="khv"
       description = "Subgrid eddy scalar diffusivity, vertical"
       units = "m^2/s"
       var3d(:,:,:) = khv(1:ni,1:nj,1:nk)
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,kh_acc)
    endif

    if(output_km.eq.1) then
        varname="kmh"
        description = "Subgrid eddy momentum viscosity, horizontal"
        units = "m^2/s"
        var3d(:,:,:) = kmh(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,km_acc)

        varname="kmv"
        description = "Subgrid eddy momentum viscosity, vertical"
        units = "m^2/s"
        var3d(:,:,:) = kmv(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,km_acc)
    endif

    if(output_thpert.eq.1) then
        varname="thpert"
        description = "Perturbation potential temperature"
        units = "K"
        var3d(:,:,:) = tha(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,thpert_acc)
    endif

    if(output_thrhopert.eq.1) then
        varname="thrhopert"
        description = "Perturbation density potential temperature"
        units = "K"
        call calc_thrho_pert(th0,tha,qa,qv0,dum1,lofstmp1)
        var3d(:,:,:) = lofstmp1(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,thrhopert_acc)
    endif

    if(output_prespert.eq.1) then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
      do k=1,nk
      do j=1,nj
      do i=1,ni
        var3d(i,j,k)=0.01*(prs(i,j,k)-p00*(pi0(i,j,k)**cpdrd))
      enddo
      enddo
      enddo
      varname="prespert"
      description = "Perturbation pressure"
      units = "hPa"
      call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,prespert_acc)
    endif

    if(imoist.eq.1.and.output_qv.eq.1)then
        varname="qv"
        description = "total water vapor mixing ratio"
        units = "g/kg"
          do k=1,nk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k)=1000.0*(qa(i,j,k,nqv))
          enddo
          enddo
          enddo
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qv_acc)
    endif

    if(imoist.eq.1.and.output_qvpert.eq.1)then
        varname="qvpert"
        description = "perturbation water vapor mixing ratio"
        units = "g/kg"
          do k=1,nk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k)=1000.0*(qa(i,j,k,nqv)-qv0(i,j,k))
          enddo
          enddo
          enddo
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvpert_acc)
    endif
!Just the mixing ratios
!ORF 2019-09-23 Now we have output selections for each mixing ratio
!These must be added to namelist.input
    if(imoist.eq.1)then
      do n=nql1,nqs2
      if(n.ne.nqv)then !ORF these are unnecessary calculations if not chosen to write
          do k=1,nk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k)=1000.0*qa(i,j,k,n)
          enddo
          enddo
          enddo
          varname = qname(n)
          description = qname(n)
          units = "g/kg"
          if (varname == "qc" .and. output_qc.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qc_acc)
          if (varname == "qr" .and. output_qr.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qr_acc)
          if (varname == "qi" .and. output_qi.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qi_acc)
          if (varname == "qs" .and. output_qs.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qs_acc)
          if (varname == "qg" .and. output_qg.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qg_acc)
        endif
      enddo
    endif

!Just the number concentrations
! we_are_dumping_numconcdata is set in solve next to we_are_dumping_hist_data
!write(*,1103)myid,we_are_dumping_numconc_data

!ORF now we specify these separately, not as a group
    if(imoist.eq.1)then
      do n=nnc1,nnc2
          do k=1,nk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k)=qa(i,j,k,n)
          enddo
          enddo
          enddo
          varname = qname(n)
          description = qname(n)
          units = "number concentration"
          if (varname == "nci" .and. output_nci.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,nci_acc)
          if (varname == "ncr" .and. output_ncr.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ncr_acc)
          if (varname == "ncs" .and. output_ncs.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ncs_acc)
          if (varname == "ncg" .and. output_ncg.eq.1) call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ncg_acc)
      enddo
!     if(myid.eq.0)print*,"We just dumped number concentration data"
!     if(myid.eq.0)call FFLUSH(6)
    endif

! Calc_dbz should be called of course, check for this in r18
    if(imoist.eq.1.and.output_dbz.eq.1) then
        varname="dbz"
        description = "Simulated reflectivity"
        units = "dBZ"
!       var3d(:,:,:) = dbz(1:ni,1:nj,1:nk)
        var3d(:,:,:) = qdiag(1:ni,1:nj,1:nk,qd_dbz)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,dbz_acc)
    endif


!!!!!! 2020-01-30 ORF new diagnostics !!!!!!

! holy shit there are a lot of them

! ORF TODO: Note that some of the diagnostics are saved on the scalar grid, some on the velocity / staggered grid
! George saves metadata for this for each variable... perhaps we should as well.

! Yes, we should. Currently hdf2nc handles this based upon variable name but an hdf5 attribute would be a good idea

! ORF We deviate from George's approach here and do not save the extra stagger point (not using dumu array)
! stagger points are duplicated on adjacent ranks anyway

! But, we should have the option interpolating to the scalar mesh when we read these into hdf2nc or whatever
wbudget: if (output_wbudget.eq.1) then

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_hadv)
          enddo
          enddo
          enddo

          varname="wb_hadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="w budget: horizontal advection (non-diff component)"
          else
                description="w budget: horizontal advection"
          endif
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_hadv_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_vadv)
          enddo
          enddo
          enddo

          varname="wb_vadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="w budget: vertical advection (non-diff component)"
          else
                description="w budget: vertical advection"
          endif
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_vadv_acc)


        if( cm1setup.ge.1 .or. ipbl.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_hturb)
          enddo
          enddo
          enddo

          varname="wb_hturb"
          description="w budget: horizontal parameterized turbulence"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_hturb_acc)


!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_vturb)
          enddo
          enddo
          enddo

          varname="wb_vturb"
          description="w budget: vertical parameterized turbulence"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_vturb_acc)

        endif

        if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_hidiff)
          enddo
          enddo
          enddo

          varname="wb_hidiff"
          description="w budget: horizontal implicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_hidiff_acc)

        endif

        if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_vidiff)
          enddo
          enddo
          enddo

          varname="wb_vidiff"
          description="w budget: vertical implicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_vidiff_acc)

        endif

        if( idiff.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_hediff)
          enddo
          enddo
          enddo

          varname="wb_hediff"
          description="w budget: horizontal explicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_hediff_acc)

          if( difforder.eq.2 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_vediff)
          enddo
          enddo
          enddo

          varname="wb_vediff"
          description="w budget: vertical explicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_vediff_acc)

          endif
        endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_pgrad)
          enddo
          enddo
          enddo

          varname="wb_pgrad"
          description="w budget: pressure gradient"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_pgrad_acc)


        if( irdamp.ge.1 .or. hrdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_rdamp)
          enddo
          enddo
          enddo

          varname="wb_rdamp"
          description="w budget: Rayleigh damper"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_rdamp_acc)

        endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = wdiag(i,j,k,wd_buoy)
          enddo
          enddo
          enddo

          varname="wb_buoy"
          description="w budget: buoyancy"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,wb_buoy_acc)

endif wbudget

vbudget: if (output_vbudget.eq.1) then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_hadv)
          enddo
          enddo
          enddo

          varname="vb_hadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="v budget: horizontal advection (non-diff component)"
          else
                description="v budget: horizontal advection"
          endif
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_hadv_acc)


!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_vadv)
          enddo
          enddo
          enddo

          varname="vb_vadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="v budget: vertical advection (non-diff component)"
          else
                description="v budget: vertical advection"
          endif
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_vadv_acc)

        if( cm1setup.ge.1 .or. ipbl.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_hturb)
          enddo
          enddo
          enddo

          varname="vb_hturb"
          description="v budget: horizontal parameterized turbulence"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_hturb_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_vturb)
          enddo
          enddo
          enddo

          varname="vb_vturb"
          description="v budget: vertical parameterized turbulence"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_vturb_acc)

        endif
        if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_hidiff)
          enddo
          enddo
          enddo

          varname="vb_hidiff"
          description="v budget: horiz implicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_hidiff_acc)
        endif

        if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_vidiff)
          enddo
          enddo
          enddo

          varname="vb_vidiff"
          description="v budget: vert implicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_vidiff_acc)
        endif
        if( idiff.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_hediff)
          enddo
          enddo
          enddo

          varname="vb_hediff"
          description="v budget: horiz explicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_hediff_acc)


          if( difforder.eq.2 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              var3d(i,j,k) = vdiag(i,j,k,vd_vediff)
            enddo
            enddo
            enddo

            varname="vb_vediff"
            description="v budget: vert explicit diffusion"
            units="m/s/s"
            call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_vediff_acc)
          endif
        endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,maxk
        do j=1,nj
        do i=1,ni
          var3d(i,j,k) = vdiag(i,j,k,vd_pgrad)
        enddo
        enddo
        enddo

        varname="vb_pgrad"
        description="v budget: pressure gradient"
        units="m/s/s"
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_pgrad_acc)


        if( irdamp.ge.1 .or. hrdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_rdamp)
          enddo
          enddo
          enddo

          varname="vb_rdamp"
          description="v budget: Rayleigh damper"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_rdamp_acc)
        endif

        if( icor.eq.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_cor)
          enddo
          enddo
          enddo

          varname="vb_cor"
          description="v budget: Coriolis acceleration"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_cor_acc)
        endif

        if( ipbl.eq.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_pbl)
          enddo
          enddo
          enddo

          varname="vb_pbl"
          description="v budget: PBL scheme"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_pbl_acc)
        endif

        if( dosub )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = vdiag(i,j,k,vd_subs)
          enddo
          enddo
          enddo

          varname="vb_subs"
          description="v budget: large-scale subsidence "
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,vb_subs_acc)
        endif
endif vbudget

ubudget: if (output_ubudget.eq.1) then

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_hadv)
          enddo
          enddo
          enddo

          varname="ub_hadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="u budget: horizontal advection (non-diff component)"
          else
                description="u budget: horizontal advection"
          endif
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_hadv_acc)


!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_vadv)
          enddo
          enddo
          enddo

          varname="ub_vadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="u budget: vertical advection (non-diff component)"
          else
                description="u budget: vertical advection"
          endif
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_vadv_acc)


        if( cm1setup.ge.1 .or. ipbl.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_hturb)
          enddo
          enddo
          enddo

          varname="ub_hturb"
          description="u budget: horizontal parameterized turbulence"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_hturb_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_vturb)
          enddo
          enddo
          enddo

          varname="ub_vturb"
          description="u budget: vertical parameterized turbulence"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_vturb_acc)

        endif

        if( hadvordrv.eq.3 .or. hadvordrv.eq.5 .or. hadvordrv.eq.7 .or. hadvordrv.eq.9 .or. advwenov.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_hidiff)
          enddo
          enddo
          enddo

          varname="ub_hidiff"
          description="u budget: horiz implicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_hidiff_acc)
        endif

        if( vadvordrv.eq.3 .or. vadvordrv.eq.5 .or. vadvordrv.eq.7 .or. vadvordrv.eq.9 .or. advwenov.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_vidiff)
          enddo
          enddo
          enddo

          varname="ub_vidiff"
          description="u budget: vert implicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_vidiff_acc)
        endif

        if( idiff.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_hediff)
          enddo
          enddo
          enddo

          varname="ub_hediff"
          description="u budget: horiz explicit diffusion"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_hediff_acc)


          if( difforder.eq.2 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
            do k=1,maxk
            do j=1,nj
            do i=1,ni
              var3d(i,j,k) = udiag(i,j,k,ud_vediff)
            enddo
            enddo
            enddo

            varname="ub_vediff"
            description="u budget: vert explicit diffusion"
            units="m/s/s"
            call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_vediff_acc)
          endif
        endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
        do k=1,maxk
        do j=1,nj
        do i=1,ni
          var3d(i,j,k) = udiag(i,j,k,ud_pgrad)
        enddo
        enddo
        enddo

        varname="ub_pgrad"
        description="u budget: pressure gradient"
        units="m/s/s"
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_pgrad_acc)


        if( irdamp.ge.1 .or. hrdamp.ge.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_rdamp)
          enddo
          enddo
          enddo

          varname="ub_rdamp"
          description="u budget: Rayleigh damper"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_rdamp_acc)
        endif

        if( icor.eq.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_cor)
          enddo
          enddo
          enddo

          varname="ub_cor"
          description="u budget: Coriolis acceleration"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_cor_acc)
        endif

        if( ipbl.eq.1 )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_pbl)
          enddo
          enddo
          enddo

          varname="ub_pbl"
          description="u budget: PBL scheme"
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_pbl_acc)
        endif

        if( dosub )then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = udiag(i,j,k,ud_subs)
          enddo
          enddo
          enddo

          varname="ub_subs"
          description="u budget: large-scale subsidence "
          units="m/s/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ub_subs_acc)
        endif

endif ubudget

qvbudget: if (output_qvbudget.eq.1) then

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_hadv)
          enddo
          enddo
          enddo
          varname="qvb_hadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="qv budget: horizontal advection (non-diff component)"
          else
                description="qv budget: horizontal advection"
          endif
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_hadv_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_vadv)
          enddo
          enddo
          enddo
          varname="qvb_vadv"
          if (hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 ) then
                description="qv budget: vertical advection (non-diff component)"
          else
                description="qv budget: vertical advection"
          endif
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_vadv_acc)

!       elseif( trim(name_output(n)).eq.'qvb_hturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_hturb)
          enddo
          enddo
          enddo

          varname="qvb_hturb"
          description="qv budget: horizontal parameterized turbulence"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_hturb_acc)

!       elseif( trim(name_output(n)).eq.'qvb_vturb' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_vturb)
          enddo
          enddo
          enddo

          varname="qvb_vturb"
          description="qv budget: vertical parameterized turbulence"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_vturb_acc)

!       elseif( trim(name_output(n)).eq.'qvb_hidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_hidiff)
          enddo
          enddo
          enddo

          varname="qvb_hidiff"
          description="qv budget: horiz implicit diffusion"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_hdiff_acc)

!       elseif( trim(name_output(n)).eq.'qvb_vidiff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_vidiff)
          enddo
          enddo
          enddo

          varname="qvb_vidiff"
          description="qv budget: vert implicit diffusion"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_vdiff_acc)

!       elseif( trim(name_output(n)).eq.'qvb_hediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_hediff)
          enddo
          enddo
          enddo

          varname="qvb_hediff"
          description="qv budget: horiz explicit diffusion"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_hediff_acc)

!       elseif( trim(name_output(n)).eq.'qvb_vediff' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_vediff)
          enddo
          enddo
          enddo

          varname="qvb_vediff"
          description="qv budget: vert explicit diffusion"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_vediff_acc)


!       elseif( trim(name_output(n)).eq.'qvb_mp' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_mp)
          enddo
          enddo
          enddo

          varname="qvb_mp"
          description="qv budget: microphysics scheme"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_mp_acc)

!       elseif( trim(name_output(n)).eq.'qvb_pbl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_pbl)
          enddo
          enddo
          enddo

          varname="qvb_pbl"
          description="qv budget: PBL scheme"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_pbl_acc)

!       elseif( trim(name_output(n)).eq.'qvb_subs' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_subs)
          enddo
          enddo
          enddo

          varname="qvb_subs"
          description="qv budget: large-scale subsidence"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qvb_subs_acc)

ptype5a: if (ptype.eq.5) then

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_cond)
          enddo
          enddo
          enddo

          varname="qt_cond"
          description="qv tendency: condensation"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qt_cond_acc)

!       elseif( trim(name_output(n)).eq.'qt_evac' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_evac)
          enddo
          enddo
          enddo

          varname="qt_evac"
          description="qv tendency: cloudwater evaporation"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qt_evac_acc)

!       elseif( trim(name_output(n)).eq.'qt_evar' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_evar)
          enddo
          enddo
          enddo

          varname="qt_evar"
          description="qv tendency: rainwater evaporation"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qt_evar_acc)

!       elseif( trim(name_output(n)).eq.'qt_dep' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_dep)
          enddo
          enddo
          enddo

          varname="qt_dep"
          description="qv tendency: deposition"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qt_dep_acc)

!       elseif( trim(name_output(n)).eq.'qt_subl' )then

          !$omp parallel do default(shared)  &
          !$omp private(i,j,k)
          do k=1,maxk
          do j=1,nj
          do i=1,ni
            var3d(i,j,k) = qdiag(i,j,k,qd_subl)
          enddo
          enddo
          enddo

          varname="qt_subl"
          description="qv tendency: sublimation"
          units="kg/kg/s"
          call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,qt_subl_acc)

      endif ptype5a

endif qvbudget



thbudget: if (output_thbudget.eq.1) then
     
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_hadv)
       enddo
       enddo
       enddo

       varname="ptb_hadv"
       if( hadvordrs.eq.3 .or. hadvordrs.eq.5 .or. hadvordrs.eq.7 .or. hadvordrs.eq.9 .or. advwenos.ge.1 )then
            description = "pot temp budget: horiz advection (non-diff component)"
       else
            description = "pot temp budget: horiz advection"
       endif
       units = "K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_hadv_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_vadv)
       enddo
       enddo
       enddo

       varname="ptb_vadv"
       if( vadvordrs.eq.3 .or. vadvordrs.eq.5 .or. vadvordrs.eq.7 .or. vadvordrs.eq.9 .or. advwenos.ge.1 )then
            description = "pot temp budget: vert advection (non-diff component)"
       else
            description = "pot temp budget: vert advection"
       endif
       units = "K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_vadv_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_hturb)
       enddo
       enddo
       enddo

       varname="ptb_hturb"
       description="pot temp budget: horiz parameterized turbulence"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_hturb_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_vturb)
       enddo
       enddo
       enddo

       varname="ptb_vturb"
       description="pot temp budget: vert parameterized turbulence"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_vturb_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_hidiff)
       enddo
       enddo
       enddo

       varname="ptb_hidiff"
       description="pot temp budget: horiz implicit diffusion"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_hidiff_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_vidiff)
       enddo
       enddo
       enddo

       varname="ptb_vidiff"
       description="pot temp budget: vert implicit diffusion"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_vidiff_acc)

       if(idiff.eq.1)  then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_hediff)
       enddo
       enddo
       enddo

       varname="ptb_hediff"
       description="pot temp budget: horiz explicit diffusion"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_hediff_acc)
       endif

       if(idiff.eq.1)  then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_vediff)
       enddo
       enddo
       enddo

       varname="ptb_vediff"
       description="pot temp budget: vert explicit diffusion"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_vediff_acc)
       endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_mp)
       enddo
       enddo
       enddo

       varname="ptb_mp"
       description="pot temp budget: microphysics scheme"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_mp_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_rdamp)
       enddo
       enddo
       enddo

       varname="ptb_rdamp"
       description="pot temp budget: Rayleigh damper"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_rdamp_acc)

       if(radopt.ne.0) then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_rad)
       enddo
       enddo
       enddo

       varname="ptb_rad"
       description="pot temp budget: radiation scheme"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_rad_acc)
       endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_div)
       enddo
       enddo
       enddo

       varname="ptb_div"
       description="pot temp budget: moist divergence term"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_div_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_diss)
       enddo
       enddo
       enddo

       varname="ptb_diss"
       description="pot temp budget: dissipating heating"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_diss_acc)

       if(ipbl.eq.1) then
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_pbl)
       enddo
       enddo
       enddo

       varname="ptb_pbl"
       description="pot temp budget: PBL scheme"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_pbl_acc)
       endif

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_subs)
       enddo
       enddo
       enddo

       varname="ptb_subs"
       description="pot temp budget: large-scale subsidence"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,ptb_subs_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_efall)
       enddo
       enddo
       enddo

       varname="td_efall"
       description="temp. tendency: energy fallout terms"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,td_efall_acc)

ptype5b: if (ptype.eq.5) then

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_cond)
       enddo
       enddo
       enddo

       varname="tt_cond"
       description="theta. tendency: condensation"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_cond_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_evac)
       enddo
       enddo
       enddo

       varname="tt_evac"
       description="theta. tendency: cloudwater evaporation"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_evac_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_evar)
       enddo
       enddo
       enddo

       varname="tt_evar"
       description="theta. tendency: rainwater evaporation"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_evar_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_dep)
       enddo
       enddo
       enddo

       varname="tt_dep"
       description="theta. tendency: deposition"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_dep_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_subl)
       enddo
       enddo
       enddo

       varname="tt_subl"
       description="theta. tendency: sublimation"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_subl_acc)

!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_melt)
       enddo
       enddo
       enddo

       varname="tt_melt"
       description="theta. tendency: melting"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_melt_acc)
       
!$omp parallel do default(shared)  &
!$omp private(i,j,k)
       do k=1,maxk
       do j=1,nj
       do i=1,ni
         var3d(i,j,k) = tdiag(i,j,k,td_frz)
       enddo
       enddo
       enddo

       varname="tt_frz"
       description="theta. tendency: freezing"
       units="K/s"
       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,tt_frz_acc)
 endif ptype5b

endif thbudget



! ORF this is freaking important... now with fixing restart/missing single
! time step problem. We also set firstvisit to .true. in solve.
if (nobuffer.or.we_are_dumping_restarts) then
    if(iprintinfo) write(outfile,"('nobuffer=.true.; immediately flushing to disk...')")
    if(iprintinfo) call FFLUSH(6)
    if (iamio.and.iwrite3d) then
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
          call h5gclose_f(param13_group_id,ierr); check_err(ierr)
          call h5gclose_f(param14_group_id,ierr); check_err(ierr)
          call h5gclose_f(param15_group_id,ierr); check_err(ierr)
          call h5gclose_f(nssl2mom_params_group_id,ierr); check_err(ierr)
          call h5gclose_f(zfp_accuracy_group_id,ierr); check_err(ierr)
          call h5gclose_f(lofs_group_id,ierr); check_err(ierr)
          call h5gclose_f(namelist_group_id,ierr); check_err(ierr)
          call h5gclose_f(twod_static_group_id,ierr); check_err(ierr)
          call h5gclose_f(twod_swath_group_id,ierr); check_err(ierr)
          call h5gclose_f(twod_group_id,ierr); check_err(ierr)
          call h5gclose_f(threed_group_id,ierr); check_err(ierr)
          call h5gclose_f(fileindex_group_id,ierr); check_err(ierr)
          call h5fclose_f(file_3d_id,ierr); check_err(ierr) !Everything should get flushed to disk here
    endif
    call mpi_barrier(MPI_COMM_CM1,ierr)
    if(iprintinfo) write(outfile,"('...done flushing to disk.')")
    if(iprintinfo) call FFLUSH(6)
endif




end subroutine writeout_hdf5
