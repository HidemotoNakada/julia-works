using MPI
using Printf
using BenchmarkTools
MPI.Init()

comm = MPI.COMM_WORLD
nprocs = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)
nthreads = Threads.nthreads()

@printf("rank = %d, %d\n", myrank, nthreads)




function receive_loop(comm, ch; echo::Bool = true)
    while true
        (hasdata, stat) = MPI.Iprobe(MPI.ANY_SOURCE, 0, comm)
        if hasdata
            (msg, stat) = MPI.recv(comm, MPI.Status; source=MPI.ANY_SOURCE, tag=0)
            if msg == -1
                if echo
                    MPI.send(-1, comm; dest=stat.source, tag=0)
                end
                break
            end
            if ch != nothing
                put!(ch, msg)
            end
            if echo
                MPI.send(100, comm; dest=stat.source, tag=0)
            end
        else
            yield()
        end
    end
end

if myrank == 0
    ch = Channel{Int}(32)
    t = @async receive_loop(comm, ch; echo=false)
    i = 1
    display(@benchmark begin
            MPI.send(i, comm; dest=i, tag=0)
            take!(ch)
    end)
    MPI.send(-1, comm; dest=i, tag=0)
    wait(t)
else
    ch = nothing
    t = @async receive_loop(comm, ch;echo=true)
    println("Rank $myrank: receive task invoked")
    wait(t) 
end
