
subroutine do_lofs_swaths(rtime,dum1,uh,vh,reqs_s,sw31,sw32,se31,se32,ss31,ss32,sn31,sn32,dt, &
      uf,vf,w3d,ua,va,prs,prs0)  
        
implicit none
real :: tem
double precision :: weps
integer :: i,j,k

real, intent(inout), dimension(ib:ie,jb:je,kb:ke) :: dum1
real, intent(in), dimension(ib:ie) :: uh
real, intent(in), dimension(jb:je) :: vh
integer, intent(inout), dimension(rmp) :: reqs_s
real, intent(inout), dimension(cmp,jmp,kmp)   :: sw31,sw32,se31,se32
real, intent(inout), dimension(imp,cmp,kmp)   :: ss31,ss32,sn31,sn32
real, intent(in) :: dt
real, intent(in), dimension(ib:ie+1,jb:je,kb:ke) :: ua
real, intent(in), dimension(ib:ie,jb:je+1,kb:ke) :: va
real, intent(in), dimension(ib:ie,jb:je,kb:ke+1) :: w3d
real, intent(in), dimension(ib:ie,jb:je,kb:ke)   :: prs,prs0
real, intent(in) :: rtime
real, intent(in), dimension(ib:ie+1) :: uf
real, intent(in), dimension(jb:je+1) :: vf

integer :: si

!  What follows are new swaths (ORF)
!  These are stored in a 4D array. Last index indicated in header, must match
!  what is going on in writeout (orfmod.F)

! ------------------  1: w_min_0500 ------------------- !

si = 1

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj
      do i=1,ni
          tem = w3d(i,j,kw1km)
          lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 10.0*epsilon
        call movesfc(-20000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  2: w_min_1000 ------------------- !

si = 2

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj
      do i=1,ni
          tem = w3d(i,j,kw500)
          lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        !-20000 m/s sanity minimum
        weps = 10.0*epsilon
        call movesfc(-20000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  3: w_max_1000 ------------------- !

si = 3

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj
      do i=1,ni
          tem = w3d(i,j,kw1km)
          lofs_swaths(i,j,1,si)=max(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=max(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 10.0*epsilon
        !-100 m/s sanity minimum maximum updraft
        call movesfc(-10000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  4: w_max_0500 ------------------- !

si = 4

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj
      do i=1,ni
          tem = w3d(i,j,kw500)
          lofs_swaths(i,j,1,si)=max(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=max(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 10.0*epsilon
        !-100 m/s sanity minimum maximum updraft
        call movesfc(-10000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  5: zeta_max_0500 ------------------- !

si = 5

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,kw500)-va(i-1,j,kw500))*rdx*uf(i)   &
             -(ua(i,j,kw500)-ua(i,j-1,kw500))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=max(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=max(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  6: zeta_max_1000 ------------------- !

si = 6

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,k1km)-va(i-1,j,k1km))*rdx*uf(i)   &
             -(ua(i,j,k1km)-ua(i,j-1,k1km))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=max(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=max(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        ! -10.0 /s sanity minimum maximum vertical vorticity
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  7: zeta_max_2000 ------------------- !

si = 7

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,k2km)-va(i-1,j,k2km))*rdx*uf(i)   &
             -(ua(i,j,k2km)-ua(i,j-1,k2km))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=max(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=max(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif


! ------------------  8: zeta_min_sfc ------------------- !

si = 8

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,ksfc)-va(i-1,j,ksfc))*rdx*uf(i)   &
             -(ua(i,j,ksfc)-ua(i,j-1,ksfc))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  9: zeta_min_0500 ------------------- !

si = 9

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,k500)-va(i-1,j,k500))*rdx*uf(i)   &
             -(ua(i,j,k500)-ua(i,j-1,k500))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        ! -10.0 /s sanity minimum maximum vertical vorticity
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  10: zeta_min_1000 ------------------- !

si = 10

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,k1km)-va(i-1,j,k1km))*rdx*uf(i)   &
             -(ua(i,j,k1km)-ua(i,j-1,k1km))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  11: zeta_min_2000 ------------------- !

si = 11

!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj+1
      do i=1,ni+1
        tem = (va(i,j,k2km)-va(i-1,j,k2km))*rdx*uf(i)   &
             -(ua(i,j,k2km)-ua(i,j-1,k2km))*rdy*vf(j)
          lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
          lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo

      if(imove.eq.1)then
        weps = 0.01*epsilon
        call movesfc(-1000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif

! ------------------  12: prespert_min_1000 ------------------- !

! ORF 2016-12-06
! For reasons that I can't quite comprehend, unless I scale things
! down (do mbar instead of Pa) I get instability when calling movesfc.
! Surface pressure (sps) does not go unstable with Pa, though, which
! makes no sense to me. I have converted all of the pressure fields
! being moved to mbar and don't see instability. Perhaps this is a
! function of coarse runs I've been experimenting with (development has
! been mostly 1km runs)

! I have scaled weps and the 1st term of movesfc accordingly.

si = 12

if(rtime.ge.prespert_swath_start_time)  then
!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj
      do i=1,ni
        tem = 0.01*(prs(i,j,k1km)-prs0(i,j,k1km))
           lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
           lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo
      if(imove.eq.1)then
        weps = 10.0*epsilon
        call movesfc(-2000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif
endif

! ------------------  13: prespert_min_2000 ------------------- !

si = 13

if(rtime.ge.prespert_swath_start_time)  then
!$omp parallel do default(shared)  &
!$omp private(i,j,tem)
      do j=1,nj
      do i=1,ni
           tem = 0.01*(prs(i,j,k2km)-prs0(i,j,k2km))
           lofs_swaths(i,j,1,si)=min(lofs_swaths(i,j,1,si),tem)
           lofs_swaths(i,j,2,si)=min(lofs_swaths(i,j,2,si),tem)
      enddo
      enddo
      if(imove.eq.1)then
        weps = 10.0*epsilon
        call movesfc(-2000.0,dt,weps,uh,vh,lofs_swaths(ib,jb,2,si),dum1(ib,jb,1),dum1(ib,jb,2),dum1(ib,jb,3), &
                     reqs_s,sw31(1,1,1),sw32(1,1,1),se31(1,1,1),se32(1,1,1),               &
                            ss31(1,1,1),ss32(1,1,1),sn31(1,1,1),sn32(1,1,1))
      endif
endif

! ------------------  End of lofs_swaths ------------------- !

return
end subroutine do_lofs_swaths
