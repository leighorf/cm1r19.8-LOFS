#define check_err(ierr) if(ierr.lt.0) print *,"Bad return value in ",__FILE__," line ",__LINE__," ierr = ",ierr

!Contains the following:
!subroutine initialize_lofs_swaths
!subroutine write_wforce
!subroutine get_command_line_arguments
!subroutine bcast_lofs
!subroutine allocate_orf_vars1
!subroutine setvindices
!subroutine create_hardware_rank_mapping
!subroutine h5_file_op_int
!subroutine h5_file_op
!subroutine prexecdiag
!subroutine set_MCM_params


subroutine initialize_lofs_swaths
implicit none

!   w_min_0500
    lofs_swaths(:,:,:,1) =  1000.0
!   w_min_1000
    lofs_swaths(:,:,:,2) =  1000.0
!   w_max_1000
    lofs_swaths(:,:,:,3) = -1000.0
!   w_max_0500
    lofs_swaths(:,:,:,4) = -1000.0
!   zeta_max_0500
    lofs_swaths(:,:,:,5) = -200.0
!   zeta_max_1000
    lofs_swaths(:,:,:,6) = -200.0
!   zeta_max_2000
    lofs_swaths(:,:,:,7) = -200.0
!   zeta_min_sfc
    lofs_swaths(:,:,:,8) =  200.0
!   zeta_min_0500
    lofs_swaths(:,:,:,9) =  200.0
!   zeta_min_1000
    lofs_swaths(:,:,:,10) =  200.0
!   zeta_min_2000
    lofs_swaths(:,:,:,11) =  200.0
!   prespert_min_1000
    lofs_swaths(:,:,:,12) =  20000.0
!   prespert_min_2000
    lofs_swaths(:,:,:,13) =  20000.0

end subroutine initialize_lofs_swaths



#ifdef WFORCE
subroutine write_wforce()
    if(dowr) write(outfile,*) 'wforceon  =',wforceon
    if(dowr) write(outfile,*) 'wforceendtime  =',wforceendtime
    if(dowr) write(outfile,*) 'wforceendval  =',wforceendval
    if(dowr) write(outfile,*) 'wforcealpha  =',wforcealpha
    if(dowr) write(outfile,*) 'wforcexrad  =',wforcexrad
    if(dowr) write(outfile,*) 'wforceyrad  =',wforceyrad
    if(dowr) write(outfile,*) 'wforcezrad  =',wforcezrad
    if(dowr) write(outfile,*) 'wforcexctr  =',wforcexctr
    if(dowr) write(outfile,*) 'wforceyctr  =',wforceyctr
    if(dowr) write(outfile,*) 'wforcezctr  =',wforcezctr
    return
end subroutine write_wforce
#endif

subroutine get_command_line_arguments()
    implicit none

    n_cmd_args = command_argument_count()
1964 format("n_cmd_args=",i2,", should be 4")
    if (n_cmd_args .ne. 4) then
        write (*,1964) n_cmd_args
! ORF FIX TODO: exit gracefully
        stop
    endif

    call get_command_argument(0,executable_cmdline)
    call get_command_argument(1,namelist_cmdline)
    call get_command_argument(2,output_path_cmdline)
    call get_command_argument(3,output_basename_cmdline)
    call get_command_argument(4,restart_path_cmdline)

! print *,executable_cmdline,namelist_cmdline,output_path_cmdline,output_basename_cmdline,restart_path_cmdline

    return
end subroutine get_command_line_arguments

subroutine bcast_lofs()
    implicit none
!     call MPI_BCAST(dtl_dbl_orf ,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
!     call MPI_BCAST(use_dtinv ,1,MPI_LOGICAL,0,MPI_COMM_CM1,ierr)
!     call MPI_BCAST(dtinv,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(time_levels_per_histfile,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_full_domain ,1,MPI_LOGICAL,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_x0,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_y0,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_x1,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_y1,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_full_vertical_extent ,1,MPI_LOGICAL,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(nkwrite_val,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_all_times ,1,MPI_LOGICAL,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(save_start_time,1,MPI_REAL,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(prespert_swath_start_time,1,MPI_REAL,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(numconcfreq,1,MPI_REAL,0,MPI_COMM_CM1,ierr)
!New from r16 1-29-2020
      call MPI_Bcast(output_prespert    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_thrhopert     ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_qc     ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_qi     ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_qr     ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_qs     ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_qg     ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_nci    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_ncr    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_ncs    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_ncg    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_qhl    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_ccn    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_ccw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_crw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_cci    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_csw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_chw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_chl    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_vhw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_vhl    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zrw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zhw    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zhl    ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_rain_accum, 1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_hwin_max_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_w_max_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_w_max_1000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_w_min_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_w_min_1000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_w_max_5000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_max_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_max_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_max_1000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_max_2000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_min_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_min_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_min_1000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zeta_min_2000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_prespert_min_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_prespert_min_1000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_prespert_min_2000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_thrho_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_dbz_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_w_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_prespert_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_prespert_0500 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_w_5000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_qc_1000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_qc_2000 ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_u_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_snapshot_v_sfc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_helicity_max_2_5km ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
!     call MPI_Bcast(output_q_mixrat ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
!     call MPI_Bcast(output_q_numconc ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_xvort ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_yvort ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_zvort ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)
      call MPI_Bcast(output_vortmag ,1,MPI_INTEGER,0,MPI_COMM_CM1,ierr)

      call MPI_BCAST(u_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(v_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(w_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(uinterp_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(vinterp_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(winterp_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(upert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(vpert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(th_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(thpert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(thrhopert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(prs_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(prespert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(pi_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(pipert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(rho_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(rhopert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(tke_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(km_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(kh_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qv_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qvpert_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(dbz_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qc_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qr_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qi_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qs_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(qg_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(nci_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(ncr_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(ncs_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(ncg_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)

      call MPI_BCAST(qhl_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(ccn_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(ccw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(crw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(cci_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(csw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(chw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(chl_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(vhw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(vhl_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(zrw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(zhw_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(zhl_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)

      call MPI_BCAST(xvort_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(yvort_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(zvort_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(vortmag_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(zvort_tilt_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)
      call MPI_BCAST(zvort_stretch_acc,1,MPI_DOUBLE,0,MPI_COMM_CM1,ierr)

      return
end subroutine bcast_lofs

subroutine allocate_orf_vars1()
    implicit none
    allocate(lofs_swaths(ib:ie,jb:je,2,nlofsswaths))
!   allocate(dum5(ib:ie,jb:je,kb:ke))
!   allocate(dum6(ib:ie,jb:je,kb:ke))
!   allocate(dum7(ib:ie,jb:je,kb:ke))
!   allocate(dum8(ib:ie,jb:je,kb:ke))
!   allocate(dum9(ib:ie,jb:je,kb:ke))
!   allocate(dum10(ib:ie,jb:je,kb:ke))
    allocate(lofstmp1(ni,nj,nk))
    allocate(var2d(ni,nj))
    allocate(var3d(ni,nj,nk))
    allocate(xhfull(1:nx))
    allocate(yhfull(1:ny))
    allocate(xffull(1:nx+1))
    allocate(yffull(1:ny+1))
    return
end subroutine allocate_orf_vars1

subroutine setvindices(zh,zf)
    implicit none
      real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: zh
      real, dimension(ib:ie,jb:je,kb:ke+1), intent(in) :: zf
      integer :: k
!Set vertical indices for some popular levels in 2D slices
      ksfc = 1
      k = 2; do while( zh(1,1,k).lt.100.0 .and. k.lt.nk ); k = k + 1; enddo
      k100 = k
      k = 2; do while( zh(1,1,k).lt.200.0 .and. k.lt.nk ); k = k + 1; enddo
      k200 = k
      k = 2; do while( zh(1,1,k).lt.300.0 .and. k.lt.nk ); k = k + 1; enddo
      k300 = k
      k = 2; do while( zh(1,1,k).lt.400.0 .and. k.lt.nk ); k = k + 1; enddo
      k400 = k
      k = 2; do while( zh(1,1,k).lt.500.0 .and. k.lt.nk ); k = k + 1; enddo
      k500 = k
      k = 2; do while( zf(1,1,k).lt.500.0 .and. k.lt.nk ); k = k + 1; enddo
      kw500 = k
      k = 2; do while( zh(1,1,k).lt.1000.0 .and. k.lt.nk ); k = k + 1; enddo
      k1km = k
      k = 2; do while( zf(1,1,k).lt.1000.0 .and. k.lt.nk ); k = k + 1; enddo
      kw1km = k
      k = 2; do while( zh(1,1,k).lt.2000.0 .and. k.lt.nk ); k = k + 1; enddo
      k2km = k
      k = 2; do while( zh(1,1,k).lt.3000.0 .and. k.lt.nk ); k = k + 1; enddo
      k3km = k
      k = 2; do while( zh(1,1,k).lt.4000.0 .and. k.lt.nk ); k = k + 1; enddo
      k4km = k
      k = 2; do while( zh(1,1,k).lt.5000.0 .and. k.lt.nk ); k = k + 1; enddo
      k5km = k
      k = 2; do while( zf(1,1,k).lt.5000.0 .and. k.lt.nk ); k = k + 1; enddo
      kw5km = k
    return
end subroutine setvindices


! Create a group, the same size as MPI_COMM_WORLD, and fill it up
! manually with the ranks we want. Loops are my old nodes.py script.
! MD gave me fixed locality code and the results are identical, just
! getting there from a different perspective (he still does the fake
! MPI_Comm_Split, but setting the key correctly now). Our intranode
! communicators (myMCMcomm) are mapped to the hardware for sure, and are
! completely independent of MPI_COMM_CM1

      subroutine create_hardware_rank_mapping(comm_in,       &
                                            corex,corey,     &
                                            rankx,ranky,     &
                                            comm_out)
      implicit none

      integer :: iyn,iyc,ixn,ixc,i,rank,nranks,ncores,nnodes,nodes_in_x,nodes_in_y,ierr
      integer :: world_group,new_world_group,new_world_size
      integer :: world_size,new_world_rank
      integer, intent(in) :: corex,corey ! how many cores in one node, along each dimension
      integer, intent(in) :: rankx,ranky ! how many cores in total along each dimension
      integer :: myrank ! this process' rank in comm_in
      integer, intent(in) :: comm_in
      integer, intent(out) :: comm_out
      integer, dimension(:), allocatable :: newranks
      integer :: errcode

      nodes_in_x=rankx/corex
      nodes_in_y=ranky/corey
      nnodes=nodes_in_x*nodes_in_y
      ncores=corex*corey

      nranks=nnodes*ncores
      call mpi_comm_size(comm_in,world_size,ierr);check_err(ierr)
      call mpi_comm_rank(comm_in,myrank,ierr);check_err(ierr)
1001  format("Error: world_size = ",i8," and nranks = ",i8". These should be equal. Exiting.")
1002  format("rankx = ",i5,"    corex = ",i4, "     nodes_in_x = ",i6,"     ranky = ",i5,"     corey = ",i4,"      nodes_in_y = ",i6)
      if (world_size .ne. nranks) then
              if(myid.eq.0) write(*,1001) world_size,nranks
              if(myid.eq.0) write(*,1002) rankx,corex,nodes_in_x,ranky,corey,nodes_in_y
              call MPI_Barrier(MPI_COMM_WORLD,ierr)
              call MPI_Abort(MPI_COMM_WORLD,errcode,ierr)
              stop
      endif

      allocate(newranks(nranks))

      i=1
      do iyn = 0,nodes_in_y-1
      do iyc = 0,corey-1
      do ixn = 0,nodes_in_x-1
      do ixc = 0,corex-1
      rank=ixc+iyc*corex + ixn*ncores + iyn*(corex*corey*nodes_in_x)
      newranks(i) = rank
      i=i+1
      enddo
      enddo
      enddo
      enddo

      call mpi_comm_group(comm_in,world_group,ierr);check_err(ierr)
      call mpi_group_incl(world_group,world_size,newranks,new_world_group,ierr);check_err(ierr)
      call mpi_comm_create_group(comm_in,new_world_group,0,comm_out,ierr);check_err(ierr)

      deallocate(newranks)

      call mpi_comm_size(MPI_COMM_CM1,numprocs,ierr);check_err(ierr)
      call mpi_comm_rank(MPI_COMM_WORLD,myid_orig,ierr);check_err(ierr)
      call mpi_comm_rank(MPI_COMM_CM1,myid,ierr);check_err(ierr)
      myMCMid=myid_orig/(corex*corey)
      call mpi_comm_split(MPI_COMM_WORLD,myMCMid,myid_orig,myMCMcomm,ierr);check_err(ierr)
      call mpi_comm_rank(myMCMcomm,localMCMrank,ierr);check_err(ierr)
      call mpi_comm_size(myMCMcomm,new_local_mcm_size,ierr);check_err(ierr)
      call mpi_comm_group(myMCMcomm,myMCMgroup,ierr);check_err(ierr)


 if(dbg)      write(*,1969)myid_orig,myid

1969 format('DEBUG2: myid_orig = ',i3,' myid = ',i3)

2020  format(a10,'=',i5)
        if(myid.eq.0) then
            print *,"MPI_COMM_CM1 and myMCMcomm communicators succesfully mapped to hardware."
            print *,"We were called as: ",trim(executable_cmdline)
            print *,"Namelist file is: ",trim(namelist_cmdline)
            print *,"output_path_cmdline is: ",trim(output_path_cmdline)
            print *,"output_basename_cmdline is: ",trim(output_basename_cmdline)
            print *,"restart_path_cmdline is: ",trim(restart_path_cmdline)
            write(*,*) '-----------------------'
            write(*,2020) "rankx",rankx
            write(*,2020) "corex",corex
            write(*,2020) "nodes_in_x",nodes_in_x
            write(*,2020) "cores_in_x",nodes_in_x*corex
            write(*,*)
            write(*,2020) "ranky",ranky
            write(*,2020) "corey",corey
            write(*,2020) "nodes_in_y",nodes_in_y
            write(*,2020) "cores_in_y",nodes_in_y*corey
            write(*,*) '-----------------------'
        endif


end subroutine create_hardware_rank_mapping


!-----------------------------------------------------------------------------------MARK
! ORF combine all file operations into one subroutine to reduce redundancy
! This is the old integer based subroutine, we keep this for compatibility with the old restart files

subroutine h5_file_op_int (operation,timeindex)
    implicit none

    integer :: operation !See orfmod.F
    integer :: timeindex !Could be time step, or time in seconds
    integer :: ichunk,ierr,cmd_s

! ORF can't use parameters for format statements, so make sure
! padtime and padnode are 5 and 6, or change accordingly
! Wait, check fortran book, maybe we can.

180 format(i5.5)
181 format(i6.6)

    character (len=5) :: ctime
    character (len=6) :: cchunk,crank
    character (len=strsize) :: message

    write(ctime,180) timeindex
    message(:) = ' '
    newdir(:) = ' '
    shellcmd(:) = ' '

    select case (operation)

        case(op_mkrestartdirs)
! Make restart directories
            do ichunk=0,numprocs-1,nhistperdir
                write(cchunk,181) ichunk
                newdir=trim(restart_path_cmdline)//'/restart/'//trim(output_basename_cmdline)//'.'//ctime//'/'//cchunk
                shellcmd='mkdir -p ' //trim(newdir)
                call execute_command_line(shellcmd,exitstat=ierr,cmdstat=cmd_s,cmdmsg=message)
                if (ierr.ne.0) call prexecdiag(ierr,cmd_s,message)
            enddo

        case(op_mkrestartfilename)

            ichunk=(myid/nhistperdir)*nhistperdir
            write(cchunk,181) ichunk
            write(crank,181) myid
      
            filename=trim(restart_path_cmdline)//'/restart/'//trim(output_basename_cmdline)//'.'//ctime//'/'//cchunk
            filename=trim(filename)//'/'//trim(output_basename_cmdline)//'.'//ctime//'_'//crank//'.restart.hdf5'

        case default

            print *, "No such operation: ",operation
            !ORF shut_down_everything

      end select

    return
end subroutine h5_file_op_int
!-----------------------------------------------------------------------------------MARK
! ORF combine all file operations into one subroutine to reduce redundancy

subroutine h5_file_op (operation,fileoptime)
    implicit none

    integer, intent(in) :: operation 
    double precision, intent(in) :: fileoptime
    integer :: ichunk,ierr,cmd_s

170 format(i5.5)
171 format(i7.7)
181 format(i7.7)

    character (len=padtimeint) :: inttime
    character (len=padtimefrac) :: fractime
    character (len=padnode) :: cchunk,crank
    character (len=strsize) :: message

    double precision frac_rhs


! ORF NEWHIST hope this always works
    write(inttime,170) int(fileoptime+dble(1.0e-8))
! NOTE had to crank up to 1e-10 to avoid stars in the directory and file name
! one save after the first when running from restart for some reason
! ORF 2019-09022 now 1e-6 (still was getting stars)
! So what if there is some residual in the file names, the actual time is stored
! in the /times array.
    frac_rhs =  dble(fileoptime+dble(1.0e-6)) - dble(int(fileoptime+dble(1.0e-6)))
!   print *,"frac_rhs = ",frac_rhs
    write(fractime,171) nint(dble(1.0e7)*frac_rhs)
!   print *, "fractime = ",fractime
    message(:) = ' '
    newdir(:) = ' '
    shellcmd(:) = ' '

!   print *,"h5_file_op: operation = ",operation," fileoptime = ",fileoptime
    select case (operation)

        case(op_mkhistdirs)

            do ichunk=0,numMCM-1,nhistperdir
                write(cchunk,181) ichunk
                newdir=trim(output_path_cmdline)//'/3D/'//trim(output_basename_cmdline)//'.'//inttime//'.'//fractime//'/'//cchunk
                shellcmd='mkdir -p ' //trim(newdir)
!               print*, "MKHIST: shellcmd = ",shellcmd
                call execute_command_line(trim(shellcmd),exitstat=ierr,cmdstat=cmd_s,cmdmsg=message)
                if (ierr.ne.0) call prexecdiag(ierr,cmd_s,message)
            enddo

        case(op_mk3dfilename)

            ichunk=(myMCMid/nhistperdir)*nhistperdir
            write(cchunk,181) ichunk
            write(crank,181) myMCMid

            filename=trim(output_path_cmdline)//'/3D/'//trim(output_basename_cmdline)//'.'//inttime//'.'//fractime//'/'//cchunk
            filename=trim(filename)//'/'//trim(output_basename_cmdline)//'.'//inttime//'.'//fractime//'_'//crank//'.cm1hdf5'

        case default

            print *, "No such operation: ",operation
            !ORF shut_down_everything

      end select

    return
end subroutine h5_file_op

subroutine prexecdiag(ierr,cmd_s,message)
    integer ierr,cmd_s
    character (len=strsize) :: message
    print *,"Exitstat = ",ierr
    print *,"cmdstat = ",cmd_s
    print *,"cmdmsg = ",trim(message)
    call FFLUSH(6)
!ORF HERE IS WHERE WE WANT TO TRIGGER
!SHUT_DOWN_EVERYTHING
    return
end subroutine prexecdiag

subroutine set_MCM_params(xh,yh,xf,yf)
    implicit none
    real, dimension(ib:ie) :: xh
    real, dimension(jb:je) :: yh
    real, dimension(ib:ie+1) :: xf
    real, dimension(jb:je+1) :: yf
    integer i,j,k,n,ii,plen
    integer rootonlygroup,orig_group,MCMrootgroup,x1dgroup,y1dgroup,myMCMbxgroup,myMCMlygroup
    character (len=MPI_MAX_PROCESSOR_NAME) procname
    integer, dimension(:), allocatable :: MCMrootranks,MCMrootranks_old,myMCMxranks,myMCMyranks,x1dranks,y1dranks
    integer, dimension(1) :: rootonlyranks
    integer :: e_id, n_id, e_id_world, n_id_world
    logical :: iwrite3d_global

    cores_per_MCM = corex * corey
    myfulloffseti = (myi-1)*ni !used in 2d collective write
    myfulloffsetj = (myj-1)*nj

    MCMnx = rankx/corex
    MCMny = ranky/corey
    numMCM = MCMnx*MCMny
    MCMi = mod(myMCMid,MCMnx)
    MCMj = myMCMid/MCMnx !ORF 2019-11-14 BUG FOUND was MCMny... found on Frontera
    myMCMni=ni*corex
    myMCMnj=nj*corey
    myMCMx0=MCMi*myMCMni
    myMCMx1=(MCMi+1)*myMCMni-1
    myMCMy0=MCMj*myMCMnj
    myMCMy1=(MCMj+1)*myMCMnj-1

    mylocalid=localMCMrank

1969 format ('DEBUG2: myid_orig = ',i3,' myid = ',i3,' new_mcm_id = ',i3,' new_local_mcm_rank = ',i3)
!   if (mylocalid.eq.0) then
!       write(*,1969),myid_orig,myid,new_mcm_id,new_local_mcm_rank
!   endif

    if (mylocalid.eq.0) then; iamio = .true.; else; iamio = .false.; endif

iprintinfo = .false.

if (iamio) then
      if (.not.save_full_domain) then
           if     ((((myMCMx1.ge.save_x0).and.(myMCMx0.le.save_x0))  &
                .or.((myMCMx0.ge.save_x0).and.(myMCMx1.le.save_x1))  &
                .or.((myMCMx0.le.save_x1).and.(myMCMx1.ge.save_x1))) &
                                .and.                                &
                   (((myMCMy1.ge.save_y0).and.(myMCMy0.le.save_y0))  &
                .or.((myMCMy0.ge.save_y0).and.(myMCMy1.le.save_y1))  &
                .or.((myMCMy0.le.save_y1).and.(myMCMy1.ge.save_y1)))) then
                        iwrite3d = .true.
           else
                        iwrite3d = .false.
           endif
! Pick lowest number write member to report memory stats
! I think I should nuke this as no memory stuff is being saved any more
           if ((myMCMx1.ge.save_x0).and.(myMCMx0.le.save_x0).and.(myMCMy1.ge.save_y0).and.(myMCMy0.le.save_y0)) iprintinfo = .true.

      else !save full domain
            iwrite3d = .true.
      endif
endif

!Check to make sure we are actually writing output data (in case
!we chose to not save the full domain and we miss everything...
!yes, this has happened and caused me confusion LOL

call MPI_REDUCE(iwrite3d,iwrite3d_global,1,MPI_LOGICAL,MPI_LOR,0,MPI_COMM_CM1,ierr)

if(myid.eq.0) then
	  if(.not.iwrite3d_global) then
  	     print *,"Oh no! We are not saving any history data!"
	     print *,"Make sure your save parameters in the LOFS block of the namelist file make sense"
		 print *,"save_full_domain = ",save_full_domain
		 print *,"save_x0 = ",save_x0
		 print *,"save_x1 = ",save_x1
		 print *,"save_y0 = ",save_y0
		 print *,"save_y1 = ",save_y1
		 print *,"nx = ",nx
		 print *,"ny = ",ny
		 call stopcm1
	  endif
endif


! Since I print I/O status info but don't always save at rank 0; hence
! in order to see from within the 3D save stuff you have to pick a
! rank that is doing I/O in order to see this output ('myid.eq.0' will
! never be true). I choose the smallest rank that is saving data, which
! will always correspond to an I/O node, because of the big if block
! above which is granular on a node basis even if chosen x0,x1 etc.
! doesn't land on an I/O rank. So anyway just use iprintinfo for those
! writes. I should at some point consolidate "myid.eq.0" and "dowr" and
! "iprintinfo" etc. but blah.

if(iamio.and.save_full_domain.and.myid.eq.0) iprintinfo = .true.
if(iprintinfo) print *,"Hello, myid = ",myid,"and I am going to be printing I/O information today!"

    if (iamio) then
        allocate ( MCM3dbuf(myMCMni*myMCMnj*nk))
        allocate ( MCM3d(myMCMni,myMCMnj,nk))
        allocate ( MCM2dbuf(myMCMni*myMCMnj))
        allocate ( MCM2d(myMCMni,myMCMnj))
    else
        allocate ( MCM3dbuf(1))
        allocate ( MCM3d(1,1,1))
        allocate ( MCM2dbuf(1))
        allocate ( MCM2d(1,1))
    endif

! orig_group contains all MPI ranks, you need to start with this

      call MPI_COMM_GROUP(MPI_COMM_CM1,orig_group,ierr); check_err(ierr)

      allocate( MCMrootranks_old(MCMnx*MCMny))
      allocate( MCMrootranks(MCMnx*MCMny))
      allocate( x1dranks(rankx))
      allocate( y1dranks(ranky))
      allocate( myMCMxranks(corex))
      allocate( myMCMyranks(corey))


      ! We don't actually use this communicator... yet. It's the communicator that contains just the iamio ranks
      ! We could use it at some point
      ! There is probably a better MPI way to do this (getting the mylocalid.eq.0 ranks)
      ii=1
      do j=0,MCMny-1
      do i=0,MCMnx-1
            MCMrootranks_old(ii) = i*corex + j*MCMnx*cores_per_MCM
            MCMrootranks(ii) = i*corex + j*corex*cores_per_MCM
!           if(myid.eq.0)print *,"DEBUG3: old: ",MCMrootranks_old(ii),"new: ",MCMrootranks(ii)
            ii=ii+1
      end do
      end do
!     if(mylocalid.eq.0) print*,"DEBUG4: mylocalid=0 and my actual id = ",myid
            
!     call MPI_GROUP_INCL(orig_group,MCMnx*MCMny,MCMrootranks,MCMrootgroup,ierr); check_err(ierr)
!     call MPI_COMM_CREATE(MPI_COMM_CM1,MCMrootgroup,MCMrootcomm,ierr); check_err(ierr)
!     call MPI_GROUP_RANK(MCMrootgroup,MCMrootrank,ierr); check_err(ierr)

!     if (mylocalid .eq. 0 .and. MCMrootrank .eq. MPI_UNDEFINED) then
!         print *, "Exiting, we have not set up MCMrootranks correctly"
!         write(*,1919) myid,myid_orig,MCMi,MCMj,myMCMid,mylocalid,MCMrootrank
!         call FFLUSH(6)
!         call stopcm1
!     endif
!     write(*,1919) myid,myid_orig,MCMi,MCMj,myMCMid,mylocalid,MCMrootrank
1919  format("myid = ",i5," myid_orig = ",i5, " MCMi = ",i5,"  MCMj = ",i5,"  myMCMid = ",i5,"  mylocalid = ",i5,"  MCMrootrank = ",i15)
      deallocate(MCMrootranks)

      rootonlyranks(1) = 0
      call MPI_GROUP_INCL(orig_group,1,rootonlyranks,rootonlygroup,ierr); check_err(ierr)
      call MPI_GROUP_RANK(rootonlygroup,rootonlyrank,ierr); check_err(ierr)

!     if(mylocalid.eq.0) then
!           call MPI_Get_processor_name(procname,plen,ierr)
!           write(outfile,199) 'procname,myMCMid,mylocalid,myid,myi,myj =',trim(procname),myMCMid,mylocalid,myid,myi,myj
!     endif
199   format(1x,a40,a19,5(4x,i5))

      if (myid.eq.0) then
            if ( mod(numprocs,cores_per_MCM).ne.0 )   then
                  print *, "Exiting, numprocs/cores_per_MCM not evenly divisible"
                  write(*,1917) numprocs,cores_per_MCM
                  call FFLUSH(6)
                  call stopcm1
            endif
            if ( mod(rankx,corex).ne.0 .or. mod(ranky,corey).ne.0 )   then
                  print *, "Exiting, rankx/corex or ranky/corey not evenly divisible"
                  write(*,1918) rankx,corex,ranky,corey
                  call FFLUSH(6)
                  call stopcm1
            endif
      endif
1917  format("numprocs = ",i5,"  cores_per_mcm = ",i5)
1918  format("rankx = ",i5,"  corex = ",i5,"  ranky = ",i5,"  corey = ",i5)

      do i=1,corex
            myMCMxranks(i)=i-1 
      end do
      do j=1,corey
            myMCMyranks(j)=(j-1)*corex
      end do

      do i=1,rankx
            x1dranks(i) = i-1
      enddo

      i=1

      do j=0,numprocs-1,rankx
            y1dranks(i) = j
            i = i + 1
      enddo

      call MPI_GROUP_INCL(orig_group,rankx,x1dranks,x1dgroup,ierr); check_err(ierr)
      call MPI_COMM_CREATE(MPI_COMM_CM1,x1dgroup,x1dcomm,ierr); check_err(ierr)
      call MPI_GROUP_RANK(x1dgroup,x1drank,ierr); check_err(ierr)
      call MPI_GROUP_INCL(orig_group,ranky,y1dranks,y1dgroup,ierr); check_err(ierr)
      call MPI_COMM_CREATE(MPI_COMM_CM1,y1dgroup,y1dcomm,ierr); check_err(ierr)
      call MPI_GROUP_RANK(y1dgroup,y1drank,ierr); check_err(ierr)
      call MPI_GROUP_INCL(myMCMgroup,corex,myMCMxranks,myMCMbxgroup,ierr); check_err(ierr)
      call MPI_COMM_CREATE(myMCMcomm,myMCMbxgroup,myMCMbxcomm,ierr); check_err(ierr)
      call MPI_GROUP_RANK(myMCMbxgroup,myMCMbxrank,ierr); check_err(ierr)
      call MPI_GROUP_INCL(myMCMgroup,corey,myMCMyranks,myMCMlygroup,ierr); check_err(ierr)
      call MPI_COMM_CREATE(myMCMcomm,myMCMlygroup,myMCMlycomm,ierr); check_err(ierr)
      call MPI_GROUP_RANK(myMCMlygroup,myMCMlyrank,ierr); check_err(ierr)
      call MPI_TYPE_CONTIGUOUS(ni,MPI_REAL,nitype,ierr);check_err(ierr)
      call MPI_TYPE_COMMIT    (nitype,ierr); check_err(ierr)
      call MPI_TYPE_CONTIGUOUS(nj,MPI_REAL,njtype,ierr); check_err(ierr)
      call MPI_TYPE_COMMIT    (njtype,ierr); check_err(ierr)
      call MPI_TYPE_CONTIGUOUS(nx,MPI_REAL,nxtype,ierr); check_err(ierr)
      call MPI_TYPE_COMMIT    (nxtype,ierr); check_err(ierr)
      call MPI_TYPE_CONTIGUOUS(ny,MPI_REAL,nytype,ierr); check_err(ierr)
      call MPI_TYPE_COMMIT    (nytype,ierr); check_err(ierr)
      call MPI_TYPE_CONTIGUOUS(ni*nj,MPI_REAL,ninjtype,ierr); check_err(ierr)
      call MPI_TYPE_COMMIT    (ninjtype,ierr); check_err(ierr)
      call MPI_TYPE_CONTIGUOUS(ni*nj*nk,MPI_REAL,ninjnktype,ierr); check_err(ierr)
      call MPI_TYPE_COMMIT    (ninjnktype,ierr); check_err(ierr)
      ! We wish to save full u,v mesh values
      ! in addition to scalar values so we can save u, v on their native mesh
      ! in visit, netCDF stuff. So we need to save xffull and yffull.
      ! This requires a little extra work as we need to tack on the extra value
      ! which lives on the furthest cores to the east for u, and to the north for v.
      ! We find the core that lives in our x1d and y1d comm ranks.

      !e_id and n_id are ranks within x1dcomm and y1dcomm - starting with 0 and
      !incrementing by one.
      !e_id_world and n_id_world are the same ranks but within MPI_COMM_CM1 
      e_id=rankx-1 !easternmost,  y=0
      n_id=ranky-1 !northernmost, x=0
      e_id_world = e_id
      n_id_world = rankx*(ranky-1)

      ! Now, collect full x and y mesh values to the "appropriate" rank, and
      ! then broadcast to everyone
      if (x1drank .ne. MPI_UNDEFINED) then
          call MPI_Gather (xh(1:ni),ni,MPI_REAL,xhfull,ni,MPI_REAL,0,x1dcomm,ierr); check_err(ierr)
          call MPI_Gather (xf(1:ni),ni,MPI_REAL,xffull,ni,MPI_REAL,e_id,x1dcomm,ierr); check_err(ierr)
      endif
      if (y1drank .ne. MPI_UNDEFINED) then
          call MPI_Gather (yh(1:nj),nj,MPI_REAL,yhfull,nj,MPI_REAL,0,y1dcomm,ierr); check_err(ierr)
          call MPI_Gather (yf(1:nj),nj,MPI_REAL,yffull,nj,MPI_REAL,n_id,y1dcomm,ierr); check_err(ierr)
      endif
      ! Tack on last value
      if (myid.eq.e_id_world ) xffull(nx+1) = xf(ni+1)
      if (myid.eq.n_id_world ) yffull(ny+1) = yf(nj+1)
      ! Send to everyone
      call MPI_Bcast(xhfull,nx,MPI_REAL,0,MPI_COMM_CM1,ierr); check_err(ierr)
      call MPI_Bcast(yhfull,ny,MPI_REAL,0,MPI_COMM_CM1,ierr); check_err(ierr)
      call MPI_Bcast(xffull,nx+1,MPI_REAL,e_id_world,MPI_COMM_CM1,ierr); check_err(ierr)
      call MPI_Bcast(yffull,ny+1,MPI_REAL,n_id_world,MPI_COMM_CM1,ierr); check_err(ierr)
    return
    end subroutine set_MCM_params

