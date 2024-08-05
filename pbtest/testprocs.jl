using Distributed
using BenchmarkTools

Distributed.addprocs(2)

@everywhere begin
    acc = 0
    add(a) = begin 
        global acc
        acc += a; 
        acc 
    end
end

b = @benchmark begin
    f = @spawnat 2 add(1)
    fetch(f)
end
display(b)
##

@time begin
    for i in 1:1000
        fetch(@spawnat 2 add(1))
    end
end

##
@benchmark begin
    fetch(@spawnat 1 add(1))
end
##
@benchmark begin
    add(1)
end


##


##
using Serialization
io = IOBuffer();
s = Serializer(io)
a = message(1, [1, 2], 1)

@benchmark begin
    serialize($s, $a)
    seekstart($io)
    deserialize($io)
end

##
using BenchmarkTools

msg = message(1, [1, 2], 1)

@benchmark begin
    io = IOBuffer();
    write(io, msg)
    seekstart(io)
    a = read(io, message)
end