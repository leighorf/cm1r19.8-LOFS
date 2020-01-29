#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

      subroutine writeout_hdf5(qname,xh,xf,uf,uh,yh,yf,vf,vh,                                        &
                          rds,sigma,rdsf,sigmaf,zh,mh,zf,mf,pi0,prs0,rho0,th0,qv0,u0,v0,             &
                          zs,gz,gzu,gzv,gxu,gyv,rgz,rgzu,rgzv,rain,sws,svs,sps,srs,sgs,sus,shs,      &
                          dum1,dum2,dum3,dum4,dbz,qa,                            &
                          t11,t12,rho,prs,ua,va,wa,ppi,tha,tkea,kmh,kmv,khh,khv,                     &
                          znt,ust,u1,v1,rr)

      character*3, dimension(maxq), intent(in) :: qname
      real, dimension(ib:ie), intent(in) :: xh,uh
      real, dimension(ib:ie+1), intent(in) :: xf,uf
      real, dimension(jb:je), intent(in) :: yh,vh
      real, dimension(jb:je+1), intent(in) :: yf,vf
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: zh
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: dbz
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: zf,mf
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: pi0,prs0,rho0,th0,qv0
      real, dimension(ib:ie,jb:je,nrain), intent(in) :: rain,sws,svs,sps,srs,sgs,sus,shs
      real, dimension(ib:ie,jb:je,kb:ke), intent(inout) :: dum1,dum2,dum3,dum4,t11,t12
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: ppi,prs,tha,rho
      real, dimension(ibt:iet,jbt:jet,kbt:ket), intent(in) :: tkea
      real, intent(in), dimension(ibc:iec,jbc:jec,kbc:kec) :: kmh,kmv,khh,khv
      real, dimension(ibm:iem,jbm:jem,kbm:kem,numq), intent(in) :: qa
      real, dimension(ib:ie+1,jb:je,kb:ke), intent(in) :: u0,ua
      real, dimension(ib:ie,jb:je+1,kb:ke), intent(in) :: v0,va
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: wa
      real, dimension(kb:ke), intent(in) :: rds,sigma
      real, dimension(kb:ke+1), intent(in) :: rdsf,sigmaf
      real, dimension(itb:ite,jtb:jte), intent(in) :: zs,rgzu,rgzv,gz,rgz,gzu,gzv
      real, dimension(ib:ie,jb:je), intent(in) :: znt,ust,u1,v1
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: rr
      real, intent(in), dimension(itb:ite,jtb:jte,ktb:kte) :: gxu,gyv
      real, intent(in), dimension(ib:ie,jb:je,kb:ke) :: mh

      integer i,j,k,n

    call h5_prelim(xh,xf,yh,yf,zh,zf,pi0,th0,prs0,rho0,qv0,u0,v0)

! ORF Definitely need to save swaths to 3D files.
! With frequent saving, we could create neat animations of 2D swath fields
! translated with the moving domain, but just centered on the action
! 2D data should take no time whatsoever to write to 3D files

! ORF If we ever get asynchronous I/O working we should definitely pass
! varname, description, units as arguments (not make them global)

! This new way of doing things has everything controlled by
! output_XXX.eq.1... so we may need to add more of these to input.incl,
! or "bunch" some stuff together

! TODO: Keep swath of surface qc to follow tornado condensation funnel
! at surface, can superimpose this with sws or sp to show relationship
! between visible funnel and tornado strength winds

!First, 2D

!ALL RIGHT LISTEN UP BITCHES: WE HAVE TURNED OFF 2D COLECTIVE WRITES. We
!will reconstruct the 2D swath files with a newly modified hdf2nc. The
!2D writes were impossibly slow for large core counts and aren't part of
!LOFS anyway...

!So, if we are here, we are writing data out, based upon the 3D tapfrq.
!Now that we are going to save 2d data in 3d files *every tapfrq* we
!need to reorganize the logic. Rather than create new booleans, we
!just write ALL of our 2d patches w/out asking.... note, there are
!forty-something of them! But they are 2D so I doubt this will slow us
!down much.

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
        var2d(:,:) = orfswaths(1:ni,1:nj,1,1)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1) then
            varname = "w_min_0500_move"
            description='minmum downdraft at 500 meters, translated with the moving domain'
            units='m/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,1)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_w_min_1000.eq.1) then
        varname = "w_min_1000"
        description='minmum downdraft at 1 km'
        units='m/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,2)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1) then
            varname = "w_min_1000_move"
            description='minmum downdraft at 1 km, translated with the moving domain'
            units='m/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,2)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_w_max_1000.eq.1) then
        varname = "w_max_1000"
        description='maximum updraft at 1 km'
        units='m/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,3)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "w_max_1000_move"
            description='maximum updraft at 1 km, translated with the moving domain'
            units='m/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,3)
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
        var2d(:,:) = orfswaths(1:ni,1:nj,1,4)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "w_max_0500_move"
            description='maximum updraft at 500 m, translated with the moving domain'
            units='m/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,4)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_0500.eq.1) then
        varname = "zeta_max_0500"
        description='maximum vertical vorticity at 500 m'
        units='/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,5)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_0500_move"
            description='maximum vertical vorticity at 500 m, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,5)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_1000.eq.1) then
        varname = "zeta_max_1000"
        description='maximum vertical vorticity at 1 km'
        units='/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,6)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_1000_move"
            description='maximum vertical vorticity at 1km, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,6)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_max_2000.eq.1) then
        varname = "zeta_max_2000"
        description='maximum vertical vorticity at 2 km'
        units='/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,7)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_max_2000_move"
            description='maximum vertical vorticity at 2km, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,7)
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
        var2d(:,:) = orfswaths(1:ni,1:nj,1,8)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_sfc_move"
            description='minimum vertical vorticity at lowest model grid level, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,8)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_0500.eq.1) then
        varname = "zeta_min_0500"
        description='minimum vertical vorticity at 500 m'
        units='/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,9)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_0500_move"
            description='minimum vertical vorticity at 500 m, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,9)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_1000.eq.1) then
        varname = "zeta_min_1000"
        description='minimum vertical vorticity at 1 km'
        units='/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,10)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_1000_move"
            description='minimum vertical vorticity at 1 km, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,10)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_zeta_min_2000.eq.1) then
        varname = "zeta_min_2000"
        description='minimum vertical vorticity at 2 km'
        units='/s'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,11)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "zeta_min_2000_move"
            description='minimum vertical vorticity at 2 km, translated with the moving domain'
            units='/s'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,11)
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
        var2d(:,:) = orfswaths(1:ni,1:nj,1,12)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "prespert_min_1000_move"
            description='minimum perturbation pressure at 1 km, translated with the moving domain'
            units='hPa'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,12)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_prespert_min_2000.eq.1) then
        varname = "prespert_min_2000"
        description='minimum perturbation pressure at 2 km'
        units='hPa'
        var2d(:,:) = orfswaths(1:ni,1:nj,1,13)
        call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        if(imove.eq.1)then
            varname = "prespert_min_2000_move"
            description='minimum perturbation pressure at 2 km, translated with the moving domain'
            units='hPa'
            var2d(:,:) = orfswaths(1:ni,1:nj,2,13)
            call h5_write_2d_float_scalar(twod_swath_group_id,var2d,ninjtype)
        endif
    endif

    if(output_snapshot_thrho_sfc.eq.1) then
        varname = "snapshot_thrho_sfc"
        description='snapshot of density potential temperature perturbation at lowest model grid level'
        units='K'
        call calc_thrho_pert(th0,tha,qa,qv0,dum1,tmp1)
        var2d(:,:) = tmp1(1:ni,1:nj,1)
        call h5_write_2d_float_scalar(twod_static_group_id,var2d,ninjtype)
    endif

    if(imoist.eq.1.and.output_snapshot_dbz_0500.eq.1) then
        varname = "snapshot_dbz_0500"
        description='snapshot of calculated reflectivity at 500 m'
        units='dBZ'
        var2d(:,:) = dbz(1:ni,1:nj,k500)
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

wr3dtrue: if(wr3d) then
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
         call calcvort(xh,xf,uf,vf,zh,mf,zf,zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf,  &
                      ua,va,wa,dum1,dum2,dum3,dum4,t11,t12)

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

! TODO: get rid of all these internal calculations - do them from saved data

!  if(output_zeta_tilt.eq.1.or.output_zeta_stretch.eq.1) &
!  call calc_str_tlt_zeta(xh,xf,uf,uh,vf,vh,zh,mf,zf,zs,rgzu,rgzv,rds,sigma,rdsf,sigmaf,  &
!                        ua,va,wa,dum1,dum2,dum3,dum4,dum5,dum6,dum7,dum8,dum9,dum10)

!ORF temp

!        varname="dwdx"
!        description = "dwdx"
!        units = "s^-1"
!        var3d(:,:,:) = dum7(1:ni,1:nj,1:nk)
!        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,accuracy)
!        varname="dvdz"
!        description = "dvdz"
!        units = "s^-1"
!        var3d(:,:,:) = dum8(1:ni,1:nj,1:nk)
!        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,accuracy)
!        varname="dwdy"
!        description = "dwdy"
!        units = "s^-1"
!        var3d(:,:,:) = dum9(1:ni,1:nj,1:nk)
!        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,accuracy)
!        varname="dudz"
!        description = "dudz"
!        units = "s^-1"
!        var3d(:,:,:) = dum10(1:ni,1:nj,1:nk)
!        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,accuracy)


!   if(output_zeta_tilt.eq.1) then
!       varname="zvort_tlt"
!       description = "tilting of z component of vorticity (zeta)"
!       units = "s^-2"
!       var3d(:,:,:) = dum1(1:ni,1:nj,1:nk)
!       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,zvort_tilt_acc)
!   endif

!   if(output_zeta_stretch.eq.1) then
!       varname="zvort_str"
!       description = "stretching of z component of vorticity (zeta)"
!       units = "s^-2"
!       var3d(:,:,:) = dum2(1:ni,1:nj,1:nk)
!       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,zvort_stretch_acc)
!   endif

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

!ORF for istotropic mesh we only need one of these, same for km below
!       varname="khv"
!       description = "Subgrid eddy scalar diffusivity, vertical"
!       units = "m^2/s"
!       var3d(:,:,:) = khv(1:ni,1:nj,1:nk)
!       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,kh_acc)

! ORF for Smagorinsky runs khh=khv (except khv=0 at sfc) and kmh=1/3 khh
! So we only need to save 1 of these (scalar so we have 1st sfc gridpoint)
! Any code that needs khv, kmh, kmv will have to read khh and adjust
! accordingly (multiply by 1/3 and/or set sfc to zero if khv/kmv)
    endif

    if(output_km.eq.1) then
        varname="kmh"
        description = "Subgrid eddy momentum viscosity, horizontal"
        units = "m^2/s"
        var3d(:,:,:) = kmh(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,km_acc)
!       varname="kmv"
!       description = "Subgrid eddy momentum viscosity, vertical"
!       units = "m^2/s"
!       var3d(:,:,:) = kmv(1:ni,1:nj,1:nk)
!       call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,km_acc)
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
        call calc_thrho_pert(th0,tha,qa,qv0,dum1,tmp1)
        var3d(:,:,:) = tmp1(1:ni,1:nj,1:nk)
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

    if(imoist.eq.1.and.output_qvpert.eq.1)then
        varname="qvpert"
        description = "water vapor mixing ratio perturbation"
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
! ORF 2019-06-14 only save numconc every 10 seconds for Bodine/Frank study
! numconcfreq is set in orf_io block of namelist file
! we_are_dumping_numconcdata is set in solve next to we_are_dumping_hist_data
!write(*,1103)myid,we_are_dumping_numconc_data

!ORF now we specify these separately, not as a group
    if(imoist.eq.1.and.we_are_dumping_numconc_data)then
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
        var3d(:,:,:) = dbz(1:ni,1:nj,1:nk)
        call h5_write_3d_float_scalar(threed_group_id,var3d,ninjnktype,dbz_acc)
    endif

! ORF this is freaking important... now with fixing restart/missing single
! time step problem. We also set firstvisit to .true. in solve.
if (nobuffer.or.we_are_dumping_restarts) then
    if(iprintinfo) write(outfile,"('nobuffer=.true.; immediately flushing to disk...')")
    if(iprintinfo) call FFLUSH(6)
    if (iamio.and.wr3d.and.iwrite3d) then
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
          call h5fclose_f(file_3d_id,ierr); check_err(ierr) !Everything should get flushed to disk here
    endif
    call mpi_barrier(MPI_COMM_CM1,ierr)
    if(iprintinfo) write(outfile,"('...done flushing to disk.')")
    if(iprintinfo) call FFLUSH(6)
endif


endif wr3dtrue


end subroutine writeout_hdf5
