
      subroutine stopcm1()
#ifdef MPI
      use mpi_newcomm !LOFS
#endif
      implicit none

#ifdef MPI
      integer :: errcode,ierr

      call mpi_abort( MPI_COMM_CM1, errcode , ierr )
#endif

      stop

      end subroutine stopcm1

