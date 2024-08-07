# Autogenerated using ProtoBuf.jl v1.0.15 on 2024-07-24T12:25:27.937
# original file: /Users/nakada/Repos/julia-works/pbtest/test.proto (proto3 syntax)

module test_pb

import ProtoBuf as PB
using ProtoBuf: OneOf
using ProtoBuf.EnumX: @enumx

export MyMessage, DArray, Sub, Add, ActorMessage, A, Tree, Node

# Abstract types to help resolve mutually recursive definitions
abstract type var"##AbstractA" end
abstract type var"##AbstractTree" end
abstract type var"##AbstractNode" end


struct MyMessage
    a::Int32
    b::Vector{String}
    c::Dict{String,String}
end
PB.default_values(::Type{MyMessage}) = (;a = zero(Int32), b = Vector{String}(), c = Dict{String,String}())
PB.field_numbers(::Type{MyMessage}) = (;a = 1, b = 2, c = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:MyMessage})
    a = zero(Int32)
    b = PB.BufferedVector{String}()
    c = Dict{String,String}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            a = PB.decode(d, Int32, Val{:zigzag})
        elseif field_number == 2
            PB.decode!(d, b)
        elseif field_number == 3
            PB.decode!(d, c)
        else
            PB.skip(d, wire_type)
        end
    end
    return MyMessage(a, b[], c)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::MyMessage)
    initpos = position(e.io)
    x.a != zero(Int32) && PB.encode(e, 1, x.a, Val{:zigzag})
    !isempty(x.b) && PB.encode(e, 2, x.b)
    !isempty(x.c) && PB.encode(e, 3, x.c)
    return position(e.io) - initpos
end
function PB._encoded_size(x::MyMessage)
    encoded_size = 0
    x.a != zero(Int32) && (encoded_size += PB._encoded_size(x.a, 1, Val{:zigzag}))
    !isempty(x.b) && (encoded_size += PB._encoded_size(x.b, 2))
    !isempty(x.c) && (encoded_size += PB._encoded_size(x.c, 3))
    return encoded_size
end

struct DArray
    a::Vector{Float64}
end
PB.default_values(::Type{DArray}) = (;a = Vector{Float64}())
PB.field_numbers(::Type{DArray}) = (;a = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:DArray})
    a = PB.BufferedVector{Float64}()
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, wire_type, a)
        else
            PB.skip(d, wire_type)
        end
    end
    return DArray(a[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::DArray)
    initpos = position(e.io)
    !isempty(x.a) && PB.encode(e, 1, x.a)
    return position(e.io) - initpos
end
function PB._encoded_size(x::DArray)
    encoded_size = 0
    !isempty(x.a) && (encoded_size += PB._encoded_size(x.a, 1))
    return encoded_size
end

struct Sub
    a::Int32
end
PB.default_values(::Type{Sub}) = (;a = zero(Int32))
PB.field_numbers(::Type{Sub}) = (;a = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Sub})
    a = zero(Int32)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            a = PB.decode(d, Int32, Val{:zigzag})
        else
            PB.skip(d, wire_type)
        end
    end
    return Sub(a)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Sub)
    initpos = position(e.io)
    x.a != zero(Int32) && PB.encode(e, 1, x.a, Val{:zigzag})
    return position(e.io) - initpos
end
function PB._encoded_size(x::Sub)
    encoded_size = 0
    x.a != zero(Int32) && (encoded_size += PB._encoded_size(x.a, 1, Val{:zigzag}))
    return encoded_size
end

struct Add
    a::Int32
end
PB.default_values(::Type{Add}) = (;a = zero(Int32))
PB.field_numbers(::Type{Add}) = (;a = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Add})
    a = zero(Int32)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            a = PB.decode(d, Int32, Val{:zigzag})
        else
            PB.skip(d, wire_type)
        end
    end
    return Add(a)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Add)
    initpos = position(e.io)
    x.a != zero(Int32) && PB.encode(e, 1, x.a, Val{:zigzag})
    return position(e.io) - initpos
end
function PB._encoded_size(x::Add)
    encoded_size = 0
    x.a != zero(Int32) && (encoded_size += PB._encoded_size(x.a, 1, Val{:zigzag}))
    return encoded_size
end

struct ActorMessage
    op::Union{Nothing,OneOf{<:Union{Add,Sub,DArray}}}
end
PB.oneof_field_types(::Type{ActorMessage}) = (;
    op = (;add=Add, sub=Sub, array=DArray),
)
PB.default_values(::Type{ActorMessage}) = (;add = nothing, sub = nothing, array = nothing)
PB.field_numbers(::Type{ActorMessage}) = (;add = 1, sub = 2, array = 3)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:ActorMessage})
    op = nothing
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            op = OneOf(:add, PB.decode(d, Ref{Add}))
        elseif field_number == 2
            op = OneOf(:sub, PB.decode(d, Ref{Sub}))
        elseif field_number == 3
            op = OneOf(:array, PB.decode(d, Ref{DArray}))
        else
            PB.skip(d, wire_type)
        end
    end
    return ActorMessage(op)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::ActorMessage)
    initpos = position(e.io)
    if isnothing(x.op);
    elseif x.op.name === :add
        PB.encode(e, 1, x.op[]::Add)
    elseif x.op.name === :sub
        PB.encode(e, 2, x.op[]::Sub)
    elseif x.op.name === :array
        PB.encode(e, 3, x.op[]::DArray)
    end
    return position(e.io) - initpos
end
function PB._encoded_size(x::ActorMessage)
    encoded_size = 0
    if isnothing(x.op);
    elseif x.op.name === :add
        encoded_size += PB._encoded_size(x.op[]::Add, 1)
    elseif x.op.name === :sub
        encoded_size += PB._encoded_size(x.op[]::Sub, 2)
    elseif x.op.name === :array
        encoded_size += PB._encoded_size(x.op[]::DArray, 3)
    end
    return encoded_size
end

struct A <: var"##AbstractA"
    a::Union{Nothing,A}
end
PB.default_values(::Type{A}) = (;a = nothing)
PB.field_numbers(::Type{A}) = (;a = 1)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:A})
    a = Ref{Union{Nothing,A}}(nothing)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, a)
        else
            PB.skip(d, wire_type)
        end
    end
    return A(a[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::A)
    initpos = position(e.io)
    !isnothing(x.a) && PB.encode(e, 1, x.a)
    return position(e.io) - initpos
end
function PB._encoded_size(x::A)
    encoded_size = 0
    !isnothing(x.a) && (encoded_size += PB._encoded_size(x.a, 1))
    return encoded_size
end

struct Tree <: var"##AbstractTree"
    tree::Union{Nothing,OneOf{<:Union{var"##AbstractNode",Float64}}}
end
PB.oneof_field_types(::Type{Tree}) = (;
    tree = (;node=Node, value=Float64),
)
PB.default_values(::Type{Tree}) = (;node = nothing, value = zero(Float64))
PB.field_numbers(::Type{Tree}) = (;node = 1, value = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Tree})
    tree = nothing
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            tree = OneOf(:node, PB.decode(d, Ref{Node}))
        elseif field_number == 2
            tree = OneOf(:value, PB.decode(d, Float64))
        else
            PB.skip(d, wire_type)
        end
    end
    return Tree(tree)
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Tree)
    initpos = position(e.io)
    if isnothing(x.tree);
    elseif x.tree.name === :node
        PB.encode(e, 1, x.tree[]::Node)
    elseif x.tree.name === :value
        PB.encode(e, 2, x.tree[]::Float64)
    end
    return position(e.io) - initpos
end
function PB._encoded_size(x::Tree)
    encoded_size = 0
    if isnothing(x.tree);
    elseif x.tree.name === :node
        encoded_size += PB._encoded_size(x.tree[]::Node, 1)
    elseif x.tree.name === :value
        encoded_size += PB._encoded_size(x.tree[]::Float64, 2)
    end
    return encoded_size
end

struct Node <: var"##AbstractNode"
    left::Union{Nothing,Tree}
    right::Union{Nothing,Tree}
end
PB.default_values(::Type{Node}) = (;left = nothing, right = nothing)
PB.field_numbers(::Type{Node}) = (;left = 1, right = 2)

function PB.decode(d::PB.AbstractProtoDecoder, ::Type{<:Node})
    left = Ref{Union{Nothing,Tree}}(nothing)
    right = Ref{Union{Nothing,Tree}}(nothing)
    while !PB.message_done(d)
        field_number, wire_type = PB.decode_tag(d)
        if field_number == 1
            PB.decode!(d, left)
        elseif field_number == 2
            PB.decode!(d, right)
        else
            PB.skip(d, wire_type)
        end
    end
    return Node(left[], right[])
end

function PB.encode(e::PB.AbstractProtoEncoder, x::Node)
    initpos = position(e.io)
    !isnothing(x.left) && PB.encode(e, 1, x.left)
    !isnothing(x.right) && PB.encode(e, 2, x.right)
    return position(e.io) - initpos
end
function PB._encoded_size(x::Node)
    encoded_size = 0
    !isnothing(x.left) && (encoded_size += PB._encoded_size(x.left, 1))
    !isnothing(x.right) && (encoded_size += PB._encoded_size(x.right, 2))
    return encoded_size
end
end # module
