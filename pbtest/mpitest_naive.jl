using MPI
using Printf
using BenchmarkTools
MPI.Init()

comm = MPI.COMM_WORLD
nprocs = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)
nthreads = Threads.nthreads()

@printf("rank = %d, %d\n", myrank, nthreads)



function receive_loop(comm)
    while true
        (msg, stat) = MPI.recv(comm, MPI.Status; source=MPI.ANY_SOURCE, tag=0)
        if msg == -1
            break
        end
        MPI.send(100, comm; dest=stat.source, tag=0)
    end
end


function ping(comm, target)
    MPI.send(target, comm; dest=target, tag=0)
    MPI.recv(comm; source=target, tag=0)
end 


if myrank == 0
    i = 1
    display(@benchmark( ping(comm,i)))

    MPI.send(-1, comm; dest=i, tag=0)
else
    receive_loop(comm)
end
