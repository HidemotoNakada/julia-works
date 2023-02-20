using MPIClusterManagers, Distributed
import MPI
transport = MPI_TRANSPORT_ALL
#transport = TCP_TRANSPORT_ALL

include("hooks.jl")

function f(x)
    println("f(x)= $x")
end

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)
manager = MPIClusterManagers.start_main_loop(TCP_TRANSPORT_ALL) # does not return on worker

@assert rank == 0

@time remotecall_fetch(f, 2, zeros(UInt8, 10));

MPIClusterManagers.stop_main_loop(manager)
