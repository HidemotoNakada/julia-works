import Base

struct message
    function_id::Int64
    args::Vector{Int64}
    future_id::Int64
end

Base.write(conn::IO, msg::message) = begin
    write(conn, msg.function_id)
    write(conn, length(msg.args))
    for arg in msg.args
        write(conn, arg)
    end
    write(conn, msg.future_id)
end

Base.read(conn::IO, ::Type{message}) = begin
    function_id = read(conn, Int64)
    n = read(conn, Int64)
    args = [read(conn, Int64) for i in 1:n]
    future_id = read(conn, Int64)
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
