using Distributed
Distributed.addprocs(1)

@everywhere begin
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
end

##
function send_msg_hook(msg) 
    if isa(msg, Distributed.CallMsg{:call})
        println("msg = $msg")
        msg = Distributed.CallMsg{:call}(msg.f, msg.args, msg.kwargs)
    end
    msg
end    

##

function Distributed.handle_msg(msg::CallMsg{:call}, header, r_stream, w_stream, version)
    println("recv = $msg")
    schedule_call(header.response_oid, ()->invokelatest(msg.f, msg.args...; msg.kwargs...))
end


function Distributed.send_msg_(w::Worker, header, msg, now::Bool)
    check_worker_state(w)
    msg = send_msg_hook(msg)
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


##



##
f = remotecall((x,y)->x+y, 2, 10, 10)
fetch(f)


##
@spawnat 2 remotecall((x)->x, 1, 10)
