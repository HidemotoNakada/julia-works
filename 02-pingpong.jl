using MPI
MPI.Init()

K=1024
M=K * K

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
Ns = [K, K, 10K, 100K, M, 10M, 100M]
n = 100

println(ENV["HOSTNAME"])
for N in Ns
#for N in [1024]
    mesg = Array{UInt8}(undef, N)
    if rank == 0 
        fill!(mesg, UInt8(1))
        stats = @timed begin
            for i in 1:n
                MPI.Send(mesg, comm; dest=1, tag=0)
                MPI.Recv!(mesg, comm)
            end
        end
        println("$N $n $(stats.time) sec $(N*n*2/1024.0/1024.0/1024.0/stats.time) GBs")
    else
        for i in 1:n
            MPI.Recv!(mesg, comm)
            MPI.Send(mesg, comm; dest=0, tag=0)
        end
    end

end

MPI.Barrier(comm)

MPI.Finalize()