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

import UUIDs

struct DataStub
    id::UInt128
    dummy::Any
    DataStub(d::Any) = new(UInt128(UUIDs.uuid4()), d)
end

##
function replace_arg(arg)
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
    println("msg = $(msg)")
    if isa(msg, Distributed.CallMsg)
        typeparameter = typeof(msg).parameters[1]
        new_args = tuple([replace_arg(arg) for arg in msg.args]...)
        msg = Distributed.CallMsg{typeparameter}(msg.f, new_args, msg.kwargs)
    end
    msg
end    

function Distributed.handle_msg(msg::CallMsg{:call}, header, r_stream, w_stream, version)
    println("recv = $msg")
    args = [recover_arg(arg) for arg in msg.args]
    schedule_call(header.response_oid, ()->invokelatest(msg.f, args...; msg.kwargs...))
end

function Distributed.handle_msg(msg::CallMsg{:call_fetch}, header, r_stream, w_stream, version)
    println("recv = $msg")
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