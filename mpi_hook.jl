using MPIClusterManagers, Distributed
import MPI
transport = MPI_TRANSPORT_ALL
#transport = TCP_TRANSPORT_ALL

#include("hooks.jl")

function f(x)
#    println("$(myid()) : f(x)= $x")
    x
end

println("nthreads = $(Threads.nthreads())")

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)
manager = MPIClusterManagers.start_main_loop(transport) # does not return on worker

@assert rank == 0

println("rank = $rank" )
size = 10 * 1024 * 1024

for _ in range(1, 10)
    @time remotecall_fetch(f, 2, ones(UInt8, size))
end

#@time println("result = $(remotecall_fetch(f, 2, ones(UInt8, 10)))");
#@time remotecall_fetch(f, 2, ones(Float64, 10));


MPIClusterManagers.stop_main_loop(manager)
