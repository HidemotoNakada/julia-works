using Sockets
using Serialization
using BenchmarkTools
import Base

include("monitored_async.jl")

send_bytes = 32
recv_bytes = 16

function handle_client(conn)
    while true
        mes = read(conn, Int64)
        if mes == -1
            break
        end
        for _ in range(1, mes)
            write(conn, 1)
        end
        flush(conn)
    end
    println("handler exit")
end

mutable struct client
    conn::TCPSocket
end

function call(c0::client, num_items::Int64)
    write(c0.conn, num_items)

    for _ in range(1, num_items)
        _ = read(c0.conn, Int64)
    end

#    readbytes!(c0.conn, r_buf, recv_bytes)

    #    println(stderr, "Sending")
#    write(c0.conn, v)
#    write(c0.conn, v)
#    write(c0.conn, v)
#    write(c0.conn, v)
#    flush(c0.conn)
    #    println(stderr, "Receiving")
#    read(c0.conn, Int64)
#    read(c0.conn, Int64)
end

function stop_server(c0::client)
    write(c0.conn, -1)
end

function do_client(conn, num_items)
    c0 = client(conn)

    b = @benchmark begin
        v = call($c0, $num_items)
    end
    display(b)

    stop_server(c0)
end    


function usage()
    println("Usage: julia naive_pingpong.jl server <port>")
    println("Usage: julia naive_pingpong.jl client <host> <port> num_items")
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
#            Sockets.nagle(conn, false)
#            Sockets.quickack(conn, true)
            println("Accepted")
            @monitored_async handle_client(conn)
        end
    elseif args[1] == "client"
        if length(args) != 4 usage() end
        host = getaddrinfo(args[2], IPv4)
        port = parse(Int64, args[3])
        num_items = parse(Int64, args[4])
        println(stderr, "$host:$port")
        conn = connect(host, port)
#        Sockets.nagle(conn, false)
#        Sockets.quickack(conn, true)
        @sync do_client(conn, num_items)
        close(conn)
    else
        usage()
    end
end  

main(ARGS)