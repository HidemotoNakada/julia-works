using MPIClusterManagers, Distributed
using BenchmarkTools
import MPI

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)

manager = MPIClusterManagers.start_main_loop(TCP_TRANSPORT_ALL) # does not return on worker

##
b = @benchmark begin
    f = @spawnat 2 return(1)
    fetch(f)
end

display(b)

MPIClusterManagers.stop_main_loop(manager)
MPI.Finalize()


