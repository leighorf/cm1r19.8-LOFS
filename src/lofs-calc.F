
!Don't bother with openmp parallelization here. For some reason I am getting
!some blocky weirdness in this field.

     subroutine calc_thrho_pert(th0,tha,qa,qv0,dum1,thrhopert)

     real, dimension(ibm:iem,jbm:jem,kbm:kem,numq), intent(in) :: qa
     real, dimension(ib:ie,jb:je,kb:ke), intent(in) :: th0,tha,qv0
     real, dimension(ib:ie,jb:je,kb:ke), intent(inout) :: dum1
     real, dimension(1:ni,1:nj,1:nk), intent(inout) :: thrhopert
     integer i,j,k,n

imoist1:  if (imoist.eq.1) then

     dum1=0
     do n=nql1,nql2
       do k=1,nk
         do j=1,nj
           do i=1,ni
             dum1(i,j,k)=dum1(i,j,k)+qa(i,j,k,n)
           enddo
         enddo
       enddo
     enddo

     if(iice.eq.1)then

       do n=nqs1,nqs2
         do k=1,nk
           do j=1,nj
             do i=1,ni
               dum1(i,j,k)=dum1(i,j,k)+qa(i,j,k,n)
             enddo
           enddo
         enddo
       enddo

   endif

    do k=1,nk
    do j=1,nj
    do i=1,ni
      thrhopert(i,j,k)=((th0(i,j,k)+tha(i,j,k))*(1.+reps*qa(i,j,k,nqv))/(1.+qa(i,j,k,nqv)+dum1(i,j,k))) - &
             (th0(i,j,k)*(1.+reps*(qv0(i,j,k)))/(1.+qv0(i,j,k)))
                       
     enddo
     enddo
     enddo
 else
     thrhopert(1:ni,1:nj,1:nk)=tha(1:ni,1:nj,1:nk)
 endif imoist1
 return
 end subroutine calc_thrho_pert

