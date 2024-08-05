using Sockets
using Serialization
using BenchmarkTools
import Base


mutable struct MyFuture{A}
    lock::Threads.Condition
    v::Union{Some{A}, Nothing}

    MyFuture{A}() where {A} = 
        new{A}(Threads.Condition(), nothing)
end


Base.put!(f::MyFuture, v) = begin
    lock(f.lock)
    try 
        if !isnothing(f.v)
            error("Future already has a value")
        else
            f.v = Some(v)
            notify(f.lock)
        end
    finally
        unlock(f.lock)
    end
end

Base.take!(f::MyFuture) = begin
    while true
        lock(f.lock)
        try 
            if !isnothing(f.v)
                return f.v.value
            else
                wait(f.lock)
            end
        finally
            unlock(f.lock)
        end
    end
end


function handle_client(conn)
    while true
        mes = deserialize(conn)
        if mes == -1
            break
        end
        serialize(conn, mes)
    end
    println("handler exit")
end

invoke(message, function_table) = function_table[message.function_id](message.args...)


mutable struct client
    conn::TCPSocket
    future::MyFuture{Int64}
end

function _allocate_future(c0::client)
    f0 = MyFuture{Int64}()
    c0.future = f0
    f0
end

function call(c0::client, v::Int64)
    f0 = _allocate_future(c0)
    serialize(c0.conn, v)
    yield()
    f0
end

function stop_server(c0::client)
    serialize(c0.conn, -1)
end

function client_loop(c0::client)
    while true
        res = deserialize(c0.conn)
        put!(c0.future, res)
        yield()
    end
end

fetch(f) = take!(f)

function client(conn)
    c0 = client(conn, MyFuture{Int64}())
    @async client_loop(c0)

    b = @benchmark begin
        f0 = call($c0, 1)
        fetch(f0)
    end
    display(b)

    stop_server(c0)
end    

macro monitored_async(expr)
    quote
        @async begin
            t = @async $(esc(expr))
            try
                wait(t)
            catch
                display(t)
            end
        end
    end
end

function usage()
    println("Usage: julia simple_rpc_tcp.jl server <port>")
    println("Usage: julia simple_rpc_tcp.jl client <host> <port>")
end

function main(args)
    if length(args) < 1 
        usage()
    end
    if args[1] == "server" 
        if length(args) != 2 usage() end
        port = parse(Int64, args[2])
        server = listen(port)
        println(port)
        while true
            conn = accept(server)
            println("Accepted")
            @monitored_async handle_client(conn)
        end
    elseif args[1] == "client"
        if length(args) != 3 usage() end
        host = getaddrinfo(args[2], IPv4)
        port = parse(Int64, args[3])
        println("$host:$port")
        conn = connect(host, port)
        @sync client(conn)
        close(conn)
    else
        usage()
    end
end  

main(ARGS)