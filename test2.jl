abstract type AST end

struct ASTree <: AST
    op::String
    args::Vector{AST}
end

struct ASTLiteral <: AST
    value::Any
end

tree = ASTree("add", [ASTLiteral(1),ASTLiteral(2)])

##
io = IOBuffer();

using Serialization

serialize(io, tree)

##
buf = take!(io)
##
buf[1]


##
struct data
    a::UInt8
    b::UInt64
end
##
d1 = data(1, 0x1010101010)
d2 = data(1, 0x1010101010)
io = IOBuffer()
serialize(io, Vector{data}([d1, d2, d1]))
buf = take!(io)
##
buf