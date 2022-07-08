import Base

function Base.open(cmds::Cmd, stdio::Base.Redirectable=devnull; write::Bool=false, read::Bool=!write, eread::Bool=false)
    err = eread ? Base.PipeEndpoint() : stderr
    if read && write
        stdio === devnull || throw(ArgumentError("no stream can be specified for `stdio` in read-write mode"))
        in = Base.PipeEndpoint()
        out = Base.PipeEndpoint()
        processes = Base._spawn(cmds, Any[in, out, err])
        processes.in = in
        processes.out = out
    elseif read
        out = Base.PipeEndpoint()
        processes = Base._spawn(cmds, Any[stdio, out, err])
        processes.out = out
    elseif write
        in = Base.PipeEndpoint()
        processes = Base._spawn(cmds, Any[in, stdio, err])
        processes.in = in
    else
        stdio === devnull || throw(ArgumentError("no stream can be specified for `stdio` in no-access mode"))
        processes = Base._spawn(cmds, Any[devnull, devnull, err])
    end
    if eread processes.err = err end
    return processes
end


function read_and_process(filename) 
    open(filename, "r") do f
        l = join(readlines(f), "\n")
        "\"" * replace(l, "\"" => "\\\"") * "\""
    end
end

l = read_and_process("remote-test.jl")
println(l)

proc = open(`ssh localhost julia -e $l`, read=true, eread=true)
println(readlines(proc.err))
println(readlines(proc.out))

