# actor-test
# for mpiclusterManager


using MPIClusterManagers, Distributed
import MPI
transport = MPI_TRANSPORT_ALL

if length(ARGS) > 0 
    if ARGS[1] == "--hooked"
        include("hooks.jl")
    else
        println(stderr, "unknown arg $(ARGS[1])")
        exit()
    end
end
include("MyActor3.jl")
using .MyActor

#
size = 10 

struct Echo <: Actor 
    id::Integer
end

@remote function ping(a::Echo, v::Vector{UInt8}) 
    v
end

#function ping(ref::ActorRef, v::Vector{UInt8})
#    callOn(ref, (ping, (v,)))
#end


MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
manager = MPIClusterManagers.start_main_loop(transport)

K=1024
M=K * K
Ns = [K, K, 10K, 100K, M, 10M, 100M]
#Ns = [10]
n = 100

echo = @startat 2 Echo(0)

for N in Ns
    buf = zeros(UInt8, N)
    stats = @timed begin
        for _ in 1:n
            stats = @timed fetch(ping(echo, buf))
        end
    end
    println("$N $n $(stats.time) sec $(N*n*2/1024.0/1024.0/1024.0/stats.time) GBs")
end  


MPIClusterManagers.stop_main_loop(manager)



