# actor-test
# with usual process

using Distributed
addprocs(1)

@everywhere include("MyActor2.jl")
@everywhere using .MyActor2

#
size = 10 * 1024
#
@everywhere begin
struct Echo <: Actor 
    id::Integer
end

struct Bucket <: Message v::Vector{UInt8} end

function MyActor2.handle(a::Echo, mes::Bucket) 
    mes.v
end
end


echo = @startat 2 Echo(0)

f = callOn(echo, Bucket(zeros(UInt8, size)))
println(length(fetch(f)))

##


