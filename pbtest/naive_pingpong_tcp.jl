using Sockets
using Serialization
using BenchmarkTools
import Base


send_bytes = 32
recv_bytes = 16

function handle_client(conn)
    s_buf = zeros(UInt8, send_bytes)
    r_buf = zeros(UInt8, send_bytes)
    while true
        readbytes!(conn, s_buf, send_bytes)
        write(conn, r_buf)

        #        mes = read(conn, Int64)
#        if mes == -1
#            break
#        end
#        mes = read(conn, Int64)
#        mes = read(conn, Int64)
#        mes = read(conn, Int64)
#        write(conn, mes)
#        write(conn, mes)
        flush(conn)
    end
    println("handler exit")
end

mutable struct client
    conn::TCPSocket
end

function call(c0::client, v::Int64)
    s_buf = zeros(UInt8, send_bytes)
    r_buf = zeros(UInt8, send_bytes)
    write(c0.conn, s_buf)
    readbytes!(c0.conn, r_buf, recv_bytes)

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
    serialize(c0.conn, -1)
end

function do_client(conn)
    c0 = client(conn)

    b = @benchmark begin
        v = call($c0, 1)
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
    println("Usage: julia naive_pingpong.jl server <port>")
    println("Usage: julia naive_pingpong.jl client <host> <port>")
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
        if length(args) != 3 usage() end
        host = getaddrinfo(args[2], IPv4)
        port = parse(Int64, args[3])
        println(stderr, "$host:$port")
        conn = connect(host, port)
#        Sockets.nagle(conn, false)
#        Sockets.quickack(conn, true)
        @sync do_client(conn)
        close(conn)
    else
        usage()
    end
end  

main(ARGS)