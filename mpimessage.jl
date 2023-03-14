using MPIClusterManagers, Distributed
import MPI

if length(ARGS) > 0 
    if ARGS[1] == "--hooked"
        include("hooks.jl")
    else
        println(stderr, "unknown arg $(ARGS[1])")
        exit()
    end
end

f(x) = x

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)

manager = MPIClusterManagers.start_main_loop(MPI_TRANSPORT_ALL) # does not return on worker

# Check whether a worker accidentally returned
@assert rank == 0



K=1024
M=K * K
Ns = [K, K, 10K, 100K, M, 10M, 100M]
n = 100

for N in Ns
    buf = zeros(UInt8, N)
    stats = @timed begin
        for _ in 1:n
            stats = @timed remotecall_fetch(f, 2, buf);
        end
    end
    println("$N $n $(stats.time) sec $(N*n*2/1024.0/1024.0/1024.0/stats.time) GBs")
end    

MPIClusterManagers.stop_main_loop(manager)
