using ProtoBuf
using BenchmarkTools

protojl("pbtest/test.proto", ".", "pbtest/output_dir")

##

include("output_dir/test_pb.jl")
# Main.test_pb
a = Main.test_pb.A(nothing)
a.a = a


io = IOBuffer();
e = ProtoEncoder(io);
encode(e, a)