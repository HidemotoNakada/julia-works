using ProtoBuf
using BenchmarkTools

protojl("pbtest/test.proto", ".", "pbtest/output_dir")

##

include("output_dir/test_pb.jl")
# Main.test_pb

io = IOBuffer();

e = ProtoEncoder(io);

#encode(e, test_pb.ActorMessage(test_pb.OneOf(:add, test_pb.Add(1))))
encode(e, test_pb.ActorMessage(test_pb.OneOf(:array, test_pb.DArray(rand(1000)))))

# encode(e, test_pb.MyMessage(-1, ["a", "b"], Dict("a" => "A", "b" => "A")))
##
io

##

@benchmark begin
    seekstart(io);
    d = ProtoDecoder(io);
    decode(d, test_pb.ActorMessage)
end


##
using Serialization
io2 = IOBuffer();
s = Serializer(io2)
serialize(s, test_pb.ActorMessage(test_pb.OneOf(:add, test_pb.DArray(rand(1000)))))
io2

##

@benchmark begin
    seekstart(io2);
    _ = deserialize(io2)
end



## 
using Serialization
using Printf
io3 = IOBuffer();
serialize(io3, Int32(32))
for i in 1:io3.size
    @printf("%02x ", io3.data[i])
end

##
using Plots
x = range(0, 10, length=100)
y = sin.(x)
plot(x, y)