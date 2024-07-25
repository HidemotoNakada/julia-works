mutable struct A 
    a::Union{A,Nothing}
end    


a = A(A(A(nothing)))

##

a0 = A(nothing)

a0.a = a0

##
using Serialization
function stest(a)
    io = IOBuffer();
    s = Serializer(io)
    serialize(s, a)
    io
end

##
io = stest(a0)
seekstart(io)
a1 = deserialize(io)