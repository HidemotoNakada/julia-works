for i in 1:10
    println(i)
end
println("test")

##
1


##
import UUIDs

UInt128(UUIDs.uuid4())


##

a = zeros(UInt8, 100)
typeof(a)



tuple([1, 2]...)


UInt128

##

struct DataTest
    v0::Vector{UInt8} 
    v1::String
end

##
d = DataTest(zeros(1), "test")
##

b = Bucket(zeros(1))

##
typeof(b)
fieldnames(typeof(b))

sym = :v
getproperty(b, sym)

##
t = typeof(b)
t(zeros(1))

##


struct DataTest
    v0::Vector{UInt8} 
    v1::String
end

##
d = DataTest(zeros(1), "test")


###

@generated function __new__(T, args...)
    return Expr(:splatnew, :T, :args)
end

# returns type and vals
function decompose(target)
    t = typeof(target)
    vals = [getproperty(target, name) for name in fieldnames(t)]
    t, vals
end    

function compose(t, vals)
    __new__(t, vals...)
end
##

compose(decompose(d2)...)

##
struct DataTest2
    v0::Vector{UInt8} 
    v1::String
    DataTest2(v::Vector{UInt8}) = new(v, "test")
end

##
d2 = DataTest2(zeros(UInt8, 1))

##



##

t, args = decompose(d2)

d_new = 