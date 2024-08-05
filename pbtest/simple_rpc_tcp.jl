
using Sockets
using Serialization
using BenchmarkTools
using Profile

include("myfuture.jl")
#include("message.jl")
include("message2.jl")
include("monitored_async.jl")

function handle_client(conn_in, conn_out)
    while true
#        println(stderr, "Receiving")
#        mes = deserialize(conn_in)
        mes = read(conn_in, message)
#        println(stderr, "Received: $mes")
        if mes.function_id == -1
            break
        end
        result = invoke(mes, function_table)
#        println(stderr, "Result: $result")
        res = response(result, mes.future_id)
        write(conn_out, res)
        #        serialize(conn_out, res)
        flush(conn_out)
    end
    close(conn_in)
    close(conn_out)
    println(stderr, "handler exit")
end

add(a, b) = a + b
sub(a, b) = a - b

function_table = Dict(1 => add, 2 => sub)

invoke(message, function_table) = function_table[message.function_id](message.args...)

mutable struct client
    conn_in
    conn_out
    future_map::Dict{Int64, MyFuture{Int64}}
    future_counter::Int64
end

function _allocate_future(c0::client)
    f0 = MyFuture{Int64}()
    future_id = c0.future_counter
    c0.future_counter += 1
    c0.future_map[future_id] = f0
    future_id, f0
end

function call(c0::client, id::Int64, args::Vector{Int64}) 
    future_id, f0 = _allocate_future(c0)
    msg = message(id, args, future_id)
#    println(stderr, "Sending: $msg")
    write(c0.conn_out, msg)
#    serialize(c0.conn_out, msg)
    flush(c0.conn_out)
    yield()
    f0
end

function stop_server(c0::client)
    write(c0.conn_out, STOP)
end

function client_loop(c0::client)
    while true
        res = read(c0.conn_in, response)
        #        res = deserialize(c0.conn_in)
        #        ch = c0.future_map[res.future_id]
        ch = pop!(c0.future_map, res.future_id)
        put!(ch, res.result)
    end
end

fetch(f) = take!(f)

function client(conn_in, conn_out)
    c0 = client(conn_in, conn_out, Dict{Int64, MyFuture{Int64}}(), 0)
    @async client_loop(c0)

#    @profile begin
        b = @benchmark begin
            f0 = call($c0, 1, [1, 2])
            fetch(f0)
        end
        display(b)
#    end
#    Profile.print(stdout)

    stop_server(c0)
end    

function usage()
    println(stderr, "Usage: julia simple_rpc_tcp.jl fork")
    println(stderr, "Usage: julia simple_rpc_tcp.jl forkworker")
    println(stderr, "Usage: julia simple_rpc_tcp.jl server <port>")
    println(stderr, "Usage: julia simple_rpc_tcp.jl client <host> <port>")
    exit(1)
end

function main(args)
    if length(args) < 1 
        usage()
    end
    if args[1] == "server" 
        if length(args) != 2 usage() end
        port = parse(Int64, args[2])
        server = listen(port)
        println(stderr, port)
        while true
            conn = accept(server)
            Sockets.nagle(conn, false)
            Sockets.quickack(conn, true)
            println(stderr, "Accepted")
            @monitored_async handle_client(conn, conn)
        end
    elseif args[1] == "client"
        if length(args) != 3 usage() end
        host = getaddrinfo(args[2], IPv4)
        port = parse(Int64, args[3])
        println(stderr, "$host:$port")
        conn = connect(host, port)
        Sockets.nagle(conn, false)
        Sockets.quickack(conn, true)
        @sync client(conn, conn)
        close(conn)
    elseif args[1] == "fork"
        if length(args) != 1 usage() end
        env = Dict{String,String}()
        cmd = `julia $PROGRAM_FILE forkworker`
        io = open(detach(setenv(addenv(cmd, env))), "r+")
        @sync client(io, io)

    elseif args[1] == "forkworker"
        if length(args) != 1 usage() end
        println(stderr, "forkworker starts")
        handle_client(stdin, stdout)
# @monitored_async 
    else
        usage()

    end  
end

main(ARGS)