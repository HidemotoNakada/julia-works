using ProtoBuf
using BenchmarkTools

protojl("pbtest/test.proto", ".", "pbtest/output_dir")
include("output_dir/test_pb.jl")

##


function gen_tree(n) :: test_pb.Tree
    if n == 0
        return test_pb.Tree(test_pb.OneOf(:value, rand()))
    end
    return test_pb.Tree(test_pb.OneOf(:node, test_pb.Node(gen_tree(n-1), gen_tree(n-1))))
end

d = gen_tree(10)

##

function encode_test(d)
    io = IOBuffer();
    e = ProtoEncoder(io);
    encode(e, d)
    io
end

function decode_test(io, T)
    seekstart(io);
    d = ProtoDecoder(io);
    decode(d, T)
end

##

@benchmark io = encode_test(d)

##
io

@benchmark decode_test(io, test_pb.Tree)


##
io = IOBuffer();

e = ProtoEncoder(io);

##
using Serialization

function encode_seq(d)
    io = IOBuffer()
    e = Serializer(io);
    serialize(e, d)
    io
end    

function decode_seq(io)
    seekstart(io)
    deserialize(io)
end

##

println("ProtoBuf")
display(@benchmark io = encode_test(d))
display(@benchmark decode_test(io, test_pb.Tree))
println("Serializer")
display(@benchmark io = encode_seq(d))
display(@benchmark decode_seq(io))

##

depth_range = 1:2:15

result = zeros(size(depth_range)[1], 4)

for (i, depth) in enumerate(depth_range)
    d = gen_tree(depth)
    println("ProtoBuf")
    result[i, 1] = mean((@benchmark io = encode_test(d)).times)
    result[i, 2] = mean((@benchmark decode_test(io, test_pb.Tree)).times)
    println("Serializer")
    result[i, 3] = mean((@benchmark io = encode_seq(d)).times)
    result[i, 4] = mean((@benchmark decode_seq(io)).times)
end

##
using Plots

plot(depth_range, result[:, 1], label="ProtoBuf encode", color="blue", linewidth=3, linestyle=:solid, yscale=:log10)
plot!(depth_range, result[:, 2], label="ProtoBuf decode", color="blue", linewidth=3, linestyle=:dash)
plot!(depth_range, result[:, 3], label="Serialize encode", color="red", linewidth=3, linestyle=:solid)
plot!(depth_range, result[:, 4], label="Serialize decode", color="red", linewidth=3, linestyle=:dash)
plot!(legend=:topleft)
plot!(xlabel="Tree depth", ylabel="Time (ns)")

##
savefig("benchmark.svg")
##



