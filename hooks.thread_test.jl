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
import Distributed.schedule_call
import Distributed.invokelatest
import Distributed.run_work_thunk
import Distributed.deliver_result
import Distributed.SyncTake
import Distributed.myid

import UUIDs

global grank = nothing
function mylog(val)
    global grank
    if isnothing(grank)
        grank = MPI.Comm_rank(MPI.COMM_WORLD)
    end
    println("$grank,$(myid()),$(Threads.threadid()): $val")
end

struct DataStub
    id::UInt128
    dummy::Any
    DataStub(d::Any) = new(UInt128(UUIDs.uuid4()), d)
end

##
function replace_arg(arg, target_rank)
    mylog("target = $(target_rank)")
    if isa(arg, Vector)
        return DataStub(arg)
    end
    arg
end

function recover_arg(arg)
    if isa(arg, DataStub)
        return arg.dummy
    end
    arg
end

function send_msg_hook(w::Worker, msg) 
    mylog("msg = $(msg)")
    if isa(msg, Distributed.CallMsg)
        if haskey(w.manager.j2mpi, w.id)
            target_rank = w.manager.j2mpi[w.id]
            typeparameter = typeof(msg).parameters[1]
            new_args = tuple([replace_arg(arg, target_rank) for arg in msg.args]...)
            msg = Distributed.CallMsg{typeparameter}(msg.f, new_args, msg.kwargs)
        end
    end
    msg
end    

function Distributed.handle_msg(msg::CallMsg{:call}, header, r_stream, w_stream, version)
    mylog("recv = $msg")
    args = [recover_arg(arg) for arg in msg.args]
    schedule_call(header.response_oid, ()->invokelatest(msg.f, args...; msg.kwargs...))
end

function Distributed.handle_msg(msg::CallMsg{:call_fetch}, header, r_stream, w_stream, version)
    mylog("recv = $msg")
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

function Distributed.send_msg_(w::Worker, header, msg, now::Bool)
    check_worker_state(w)
    msg = send_msg_hook(w, msg)
    if myid() != 1 && !isa(msg, IdentifySocketMsg) && !isa(msg, IdentifySocketAckMsg)
        wait(w.initialized)
    end
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


function MPIClusterManagers.start_send_event_loop(mgr::MPIManager, rank::Integer)
    try
        r_s = Base.BufferStream()
        w_s = Base.BufferStream()
        mgr.rank2streams[rank] = (r_s, w_s)

        # TODO: There is one task per communication partner -- this can be
        # quite expensive when there are many workers. Design something better.
        # For example, instead of maintaining two streams per worker, provide
        # only abstract functions to write to / read from these streams.
        @async begin
            rr = MPI.Comm_rank(mgr.comm)
            reqs = MPI.Request[]
            while !isready(mgr.initiate_shutdown)
                # When data are available, send them
                while bytesavailable(w_s) > 0
                    data = take!(w_s.buffer)
                    push!(reqs, MPI.Isend(data, rank, 0, mgr.comm))
                end
                if !isempty(reqs)
                    (indices, stats) = MPI.Testsome!(reqs)
                    filter!(req -> req != MPI.REQUEST_NULL, reqs)
                end
                # TODO: Need a better way to integrate with libuv's event loop
                yield()
            end
            put!(mgr.sending_done, nothing)
        end
        (r_s, w_s)
    catch e
        Base.show_backtrace(stdout, catch_backtrace())
        println(e)
        rethrow(e)
    end
end

function receive_core(mgr::MPIManager, ch::Channel)
    comm = MPI.COMM_WORLD
    rank = MPI.Comm_rank(comm)
    num_send_loops = 0
    while !isready(mgr.initiate_shutdown)
#        if rank == 0
#            (hasdata, stat) = MPI.Iprobe(isdefined(MPI, :ANY_SOURCE) ? MPI.ANY_SOURCE : MPI.MPI_ANY_SOURCE, 0, mgr.comm)
#        else 
            hasdata = true        
            stat = MPI.Probe(isdefined(MPI, :ANY_SOURCE) ? MPI.ANY_SOURCE : MPI.MPI_ANY_SOURCE, 0, mgr.comm)
#        end
        if hasdata
            mylog("recv stat = $stat")
            count = MPI.Get_count(stat, UInt8)
            buf = Array{UInt8}(undef, count)
            from_rank = MPI.Get_source(stat)
            MPI.Recv!(buf, from_rank, 0, mgr.comm)
            put!(ch, (from_rank, buf))
        else
            # TODO: Need a better way to integrate with libuv's event loop
            yield()
        end
    end
    close(ch)
    for i in 1:num_send_loops
        fetch(mgr.sending_done)
    end
end



# Event loop for receiving data, for the MPI_TRANSPORT_ALL case
function MPIClusterManagers.receive_event_loop(mgr::MPIManager)
    ch = Base.Channel()
    handle = Threads.@spawn receive_core(mgr, ch)
    @async begin
        while true 
#            try 
                (from_rank, buf) = take!(ch)
#            catch 
#                break
#            end
            mylog("get stream for $from_rank")
            streams = get(mgr.rank2streams, from_rank, nothing)
            mylog("get stream done")
            if streams == nothing
                # This is the first time we communicate with this rank.
                # Set up a new connection.
                mylog("start send loop")
                (r_s, w_s) = MPIClusterManagers.start_send_event_loop(mgr, from_rank)
                mylog("start send loop done")
                @async Distributed.process_messages(r_s, w_s)
                mylog("process_message done")
                num_send_loops += 1
            else
                (r_s, w_s) = streams
            end
            mylog("write to r_s")
            write(r_s, buf)
        end
    end

    Threads.wait(handle);
    put!(mgr.receiving_done, nothing)
end