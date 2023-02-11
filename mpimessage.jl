using MPIClusterManagers, Distributed
import MPI

f(x) = x

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)

if length(ARGS) == 0
    println("Please specify a transport option to use [MPI|TCP]")
    MPI.Finalize()
    exit(1)
elseif ARGS[1] == "TCP"
    manager = MPIClusterManagers.start_main_loop(TCP_TRANSPORT_ALL) # does not return on worker
elseif ARGS[1] == "MPI"
    manager = MPIClusterManagers.start_main_loop(MPI_TRANSPORT_ALL) # does not return on worker
else
    println("Valid transport options are [MPI|TCP]")
    MPI.Finalize()
    exit(1)
end

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
