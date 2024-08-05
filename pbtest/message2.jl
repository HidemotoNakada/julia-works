import Base

struct message
    function_id::Int64
    args::Vector{Int64}
    future_id::Int64
end

Base.write(conn::IO, msg::message) = begin
    io = IOBuffer();
    write(io, msg.function_id)
    write(io, length(msg.args))
    for arg in msg.args
        write(io, arg)
    end
    write(io, msg.future_id)
#    println(stderr, "Size: $(io.size)")    
    write(conn, io.size)
    seekstart(io)
    wrote = write(conn, io)
#    println(stderr, "Wrote: $wrote")
    flush(conn)
end

Base.read(conn::IO, ::Type{message}) = begin
    size = read(conn, Int64)
    buf = read(conn, size)
    io = IOBuffer(buf; read=true, sizehint=size)
    function_id = read(io, Int64)
    n = read(io, Int64)
    args = [read(io, Int64) for i in 1:n]
    future_id = read(io, Int64)
    message(function_id, args, future_id)
end

STOP = message(-1, [], -1)


struct response
    result::Int64
    future_id::Int64
end

Base.write(conn::IO, res::response) = begin
    write(conn, res.result)
    write(conn, res.future_id)
end

Base.read(conn::IO, ::Type{response}) = begin
    result = read(conn, Int64)
    future_id = read(conn, Int64)
    response(result, future_id)
end
