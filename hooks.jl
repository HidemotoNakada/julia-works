import Distributed.Worker
import Distributed.IdentifySocketAckMsg
import Distributed.IdentifySocketMsg
import Distributed.MSG_BOUNDARY
import Distributed.check_worker_state
import Distributed.reset_state
import Distributed.serialize_hdr_raw
import Distributed.invokelatest
import Distributed.serialize_msg
import Distributed.CallMsg
import Distributed.ResultMsg
import Distributed.schedule_call
import Distributed.invokelatest
import Distributed.run_work_thunk
import Distributed.deliver_result
import Distributed.SyncTake
import Distributed.myid
import Distributed.lookup_ref
import UUIDs


module MPI_helper
export AT, encode, decode, DataStub, rcvDict, @mylog
import MPI
import Distributed.myid

global grank = nothing

function get_grank()
    global grank
    if isnothing(grank)
        grank = MPI.Comm_rank(MPI.COMM_WORLD)
    end
    grank
end

macro mylog(expr) 
    return :()
#    return :(_mylog($(esc(expr))))
end

function _mylog(val)
    grank = get_grank()
    println("$grank,$(myid()),$(Threads.threadid()): $val")
end 

rcvDict = Dict{Tuple{UInt32, UInt8}, Any}()  # key: tuple of rank and mes id

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

struct DataStub
    id::UInt8
    rank::UInt32
end

global stubCounter::UInt64 = 0

function DataStub(d::Any) 
    global stubCounter
    d = DataStub(UInt8(stubCounter & 0xff), get_grank())
    stubCounter += 1
    d
end
end

using .MPI_helper;
##
function replace_arg(arg, mgr, target_rank)
    if isa(arg, Vector)
        d = DataStub(arg)
        et = typeof(arg).parameters[1]
        at = AT(d.id, et, length(arg))
        buf = [encode(at)]
        @mylog("sending by MPI: $(length(arg))")
        MPI.Send(buf, mgr.comm, dest=target_rank, tag=1)
        MPI.Send(arg, mgr.comm, dest=target_rank, tag=2)
        return d
    end
    arg
end

function recover_arg(arg)
    if isa(arg, DataStub)
        if haskey(rcvDict, (arg.rank, arg.id))
            return pop!(rcvDict, (arg.rank, arg.id))
        else
            return arg.id
        end
    end
    arg
end

function send_msg_hook(w::Worker, msg) 
    @mylog("msg = $msg")
    if isa(msg, Distributed.CallMsg)
        if haskey(w.manager.j2mpi, w.id)
            target_rank = w.manager.j2mpi[w.id]
            typeparameter = typeof(msg).parameters[1]
            new_args = tuple([replace_arg(arg, w.manager, target_rank) for arg in msg.args]...)
            msg = Distributed.CallMsg{typeparameter}(msg.f, new_args, msg.kwargs)
        end
    elseif isa(msg, Distributed.ResultMsg)
        @mylog("resultmsg = $msg")
        if haskey(w.manager.j2mpi, w.id)
            target_rank = w.manager.j2mpi[w.id]
        else
            target_rank = w.id - 1  # hope this is enough
        end
        msg = Distributed.ResultMsg(replace_arg(msg.value, w.manager, target_rank))

    end
    msg
end    

function Distributed.handle_msg(msg::CallMsg{:call}, header, r_stream, w_stream, version)
    @mylog("recv = CallMsg :call")
    args = [recover_arg(arg) for arg in msg.args]
    schedule_call(header.response_oid, ()->invokelatest(msg.f, args...; msg.kwargs...))
end

function Distributed.handle_msg(msg::CallMsg{:call_fetch}, header, r_stream, w_stream, version)
    @mylog("recv = CallMsg :call_fetch")
    args = [recover_arg(arg) for arg in msg.args]
    errormonitor(@async begin
        v = run_work_thunk(()->invokelatest(msg.f, args...; msg.kwargs...), false)
        if isa(v, SyncTake)
            try
                deliver_result(w_stream, :call_fetch, header.notify_oid, v.v)
            finally
                unlock(v.rv.synctake)
            end
        else
            deliver_result(w_stream, :call_fetch, header.notify_oid, v)
        end
        nothing
    end)
end

function Distributed.handle_msg(msg::ResultMsg, header, r_stream, w_stream, version)
    value = recover_arg(msg.value)
    put!(lookup_ref(header.response_oid), value)
end

function Distributed.send_msg_(w::Worker, header, msg, now::Bool)
    check_worker_state(w)
    if myid() != 1 && !isa(msg, IdentifySocketMsg) && !isa(msg, IdentifySocketAckMsg)
        wait(w.initialized)
    end
    msg = send_msg_hook(w, msg)
    io = w.w_stream
    lock(io)
    try
        reset_state(w.w_serializer)
        serialize_hdr_raw(io, header)
        invokelatest(serialize_msg, w.w_serializer, msg)  # io is wrapped in w_serializer
        write(io, MSG_BOUNDARY)

        if !now && w.gcflag
            flush_gc_msgs(w)
        else
            flush(io)
        end
    finally
        unlock(io)
    end
end


import MPI
import MPI.ANY_SOURCE
import MPIClusterManagers
import MPIClusterManagers.start_send_event_loop

# Event loop for receiving data, for the MPI_TRANSPORT_ALL case
function MPIClusterManagers.receive_event_loop(mgr::MPIManager)
    num_send_loops = 0
    while !isready(mgr.initiate_shutdown)
        (hasdata, stat) = MPI.Iprobe(isdefined(MPI, :ANY_SOURCE) ? MPI.ANY_SOURCE : MPI.MPI_ANY_SOURCE, MPI.ANY_TAG, mgr.comm)
        if hasdata
            from_rank = MPI.Get_source(stat)
            @macroexpand @mylog("stat = $stat, tag = $(stat.tag)")
            @mylog("stat = $stat, tag = $(stat.tag)")
            if stat.tag == 1   # Receive outbound messages
                buf = [UInt64(0)]
                MPI.Recv!(buf, from_rank, 1, mgr.comm)
                at = decode(buf[1])
                @mylog("mes $(UInt64(buf[1])), $(decode(buf[1]))")
                data_buf = Vector{at.t}(undef, at.l)
                MPI.Recv!(data_buf, from_rank, 2, mgr.comm)
                @mylog("data")
                rcvDict[(UInt32(from_rank), at.id)] = data_buf
            else
                count = MPI.Get_count(stat, UInt8)
                buf = Array{UInt8}(undef, count)
                MPI.Recv!(buf, from_rank, 0, mgr.comm)
                streams = get(mgr.rank2streams, from_rank, nothing)
                if streams == nothing
                    # This is the first time we communicate with this rank.
                    # Set up a new connection.
                    (r_s, w_s) = start_send_event_loop(mgr, from_rank)
                    Distributed.process_messages(r_s, w_s)
                    num_send_loops += 1
                else
                    (r_s, w_s) = streams
                end
                write(r_s, buf)
            end
        else
            # TODO: Need a better way to integrate with libuv's event loop
            yield()
        end
    end

    for i in 1:num_send_loops
        fetch(mgr.sending_done)
    end
    put!(mgr.receiving_done, nothing)
end


function Distributed.manage(mgr::MPIManager, id::Integer, config::WorkerConfig, op::Symbol)
    @mylog("manage : op= $op")
    if op == :register
        # Retrieve MPI rank from worker
        # TODO: Why is this necessary? The workers already sent their rank.
        rank = remotecall_fetch(()->MPI.Comm_rank(MPI.COMM_WORLD), id)
        mgr.j2mpi[id] = rank
        mgr.mpi2j[rank] = id

        if length(mgr.j2mpi) == mgr.np
            # All workers registered
            mgr.initialized = true
            notify(mgr.cond_initialized)
            if mgr.mode != MPI_ON_WORKERS
                # Set up mapping for the manager
                mgr.j2mpi[1] = 0
                mgr.mpi2j[0] = 1
            end
        end
    elseif op == :deregister
        @info("pid=$(getpid()) id=$id op=$op")
        # TODO: Sometimes -- very rarely -- Julia calls this `deregister`
        # function, and then outputs a warning such as """error in running
        # finalizer: ErrorException("no process with id 3 exists")""". These
        # warnings seem harmless; still, we should find out what is going wrong
        # here.
    elseif op == :interrupt
        # TODO: This should never happen if we rmprocs the workers properly
        @info("pid=$(getpid()) id=$id op=$op")
        @assert false
    elseif op == :finalize
        # This is called from within a finalizer after deregistering; do nothing
    else
        @info("pid=$(getpid()) id=$id op=$op")
        @assert false # Unsupported operation
    end
end