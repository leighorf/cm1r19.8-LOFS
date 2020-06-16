!ORF easiest way to switch to new communicator
module mpi_newcomm
use mpi
integer MPI_COMM_CM1
!2020-06-16 add iotime here
!that way it's always where you want it
!without lugging around lofs-mod
double precision :: iotime
end module mpi_newcomm
