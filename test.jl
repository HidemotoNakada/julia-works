##
a = 0x000000001
typeof(a)


##
module MPI_helper
export AT, encode, decode

struct AT
    id::UInt8
    t::DataType
    l::UInt64
end

##
types = [UInt8, UInt32, Int32, UInt64, Int64, Float32, Float64]

rev_types = Dict{DataType, UInt8}()
for (index, type) in enumerate(types) 
    rev_types[type] = UInt8(index)
end

function encode(at::AT) :: UInt64 
    at.l | 
    (UInt64(at.id) << 53) | 
    (UInt64(rev_types[at.t]) << 61)
end    

##

function decode(v::UInt64) :: AT 
    mask = UInt64(7) << 61
    id_mask = UInt64(255) << 53
    t = types[(v & mask)  >> 61]
    id = (v & id_mask) >> 53
    l = (~(mask | id_mask)) & v
    AT(id, t, l)
end
end

decode(encode(AT(255, UInt32, 0x1010101010)))