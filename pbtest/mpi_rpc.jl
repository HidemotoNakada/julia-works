using MPI
using Printf
using BenchmarkTools
MPI.Init()

include("myfuture.jl")
include("message2.jl")
include("monitored_async.jl")



add(a, b) = a + b
sub(a, b) = a - b

function_table = Dict(1 => add, 2 => sub)

invoke(message, function_table) = function_table[message.function_id](message.args...)



comm = MPI.COMM_WORLD
nprocs = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)
nthreads = Threads.nthreads()

@printf("rank = %d, %d\n", myrank, nthreads)

function handle_client(comm)
    while true
        (hasdata, stat) = MPI.Iprobe(MPI.ANY_SOURCE, 0, comm)
        if hasdata
            (msg, stat) = MPI.recv(comm, MPI.Status; source=MPI.ANY_SOURCE, tag=0)
#            println(stderr, "Received: $msg")
            if msg.function_id == -1
                break
            end
            result = invoke(msg, function_table)
            res = response(result, msg.future_id)
            MPI.send(res, comm; dest=stat.source, tag=0)
        else
            yield()
        end
    end
    println(stderr, "handler exit")
end


mutable struct client
    rank::Int64
    comm::MPI.Comm
    future_map::Dict{Int64, MyFuture{Int64}}
    future_counter::Int64

    client(rank, comm) = new(rank, comm, Dict{Int64, MyFuture{Int64}}(), 0)
end

function _allocate_future(c0::client)
    f0 = MyFuture{Int64}()
    future_id = c0.future_counter
    c0.future_counter += 1
    c0.future_map[future_id] = f0
    future_id, f0
end

function send_message(c0::client, msg::message)
    MPI.send(msg, c0.comm; dest=c0.rank, tag=0)
end

function client_loop(c0::client)
    while true
        (hasdata, stat) = MPI.Iprobe(MPI.ANY_SOURCE, 0, comm)
        if hasdata
            (res, stat) = MPI.recv(comm, MPI.Status; source=MPI.ANY_SOURCE, tag=0)
#            println(stderr, "Received: $res")
            ch = pop!(c0.future_map, res.future_id)
            put!(ch, res.result)
        
        else
            yield()
        end
    end
end


function call(c0::client, id::Int64, args::Vector{Int64}) 
    future_id, f0 = _allocate_future(c0)
    msg = message(id, args, future_id)
#    println(stderr, "Sending: $msg")
    send_message(c0, msg)
    yield()
    f0
end

function stop_server(c0::client)
    send_message(c0, STOP)
end


if myrank == 0
    c0 = client(1, comm)
    @monitored_async client_loop(c0)

    display(@benchmark begin
        f0 = call(c0, 1, [1, 2])
        fetch(f0)
    end)

    stop_server(c0)
else
    println("Rank $myrank: receive task invoking")
    @sync @async handle_client(comm)
end
