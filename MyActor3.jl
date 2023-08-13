module MyActor
export Actor, Message, Context, start, ActorRef, callOn, @startat, stop, _Rep, mergeFuture, @remote
import Distributed
using MacroTools


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

abstract type Actor end
abstract type Message end
abstract type Context end
const MessagePair = Tuple{Message, Distributed.RRID}

struct _Rep <: Message end
struct _Stop <: Message end
function handle(a::Actor, m::Message) println("should not be called") end
function handle(a::Actor, m::_Rep) println(a) end

macro remote(fdef) 
    d = splitdef(fdef)
    original = combinedef(d)

    if (! (typeof(d[:args][1]) <: Expr )) ||   # check the first argument type
                d[:args][1].head != :(::) # ||  # cannot eval in a macro 
#                !(eval(:($(d[:args][1].args[2]))) <: Actor)
        println(stderr, "the first argument should be Actor")
        original
    else 
        (arg_name, arg_type, is_splat, default) = splitarg(d[:args][1])
#        d[:args][1].args[2] = :ActorRef
#        d[:args][1] = combinearg(arg_name, Expr(:curly, :ActorRef, arg_type), is_splat, default)
        d[:args][1] = combinearg(arg_name, :ActorRef, is_splat, default)
        name = d[:name]
        args = [typeof(arg) <: Expr ? arg.args[1] : arg for arg in d[:args][2:end]]
        argtuple = Expr(:tuple, args...)
        d[:body] = :(callOn($arg_name, ($name, $argtuple)) ) 
        remoteCall = combinedef(d)
        quote
            $(esc(original))
            $(esc(remoteCall))
        end
    end
end
##
function taskLoop(cn::AbstractChannel, target::Actor)
    while true
        t, arity, rrid = take!(cn)
        println("takeLoop: t, arity = $t, $arity")
        if !(arity isa Int)
            println("arity is not int! $(typeof(arity))")
            continue
        end
        args = [take!(cn) for _ in range(1, arity)]
        #println("composing: $t, $args")

        fcn = Distributed.lookup_ref(rrid)
        if t == _Stop
            put!(fcn, nothing)
            break
        end
        try 
            res = t(target, args...)
            put!(fcn, res)
        catch e
            println(e)
            put!(fcn, e)
        end
    end
end
##
function createLoop(actorCons)
    cn = Channel()
    @async taskLoop(cn, actorCons())
    return cn
end

function start(actorCons, node=1) 
    cn = Distributed.RemoteChannel(()->createLoop(actorCons), node)
    ActorRef(cn, node)
end

macro startat(id, expr)
    thunk = esc(:(()->($expr)))
    quote
        start($thunk, $(esc(id)))
    end
end

##
struct ActorRef
    cn::Distributed.RemoteChannel
    w::Integer
end
#ActorRef(cn::Distributed.RemoteChannel, id::Integer) = 
#    ActorRef(cn, Distributed.worker_from_id(id))

function callOn(ref::ActorRef, mes_tuple)
    rr = Distributed.Future(ref.w)
    RRID = Distributed.remoteref_id(rr)
    t, args = mes_tuple
    put!(ref.cn, (t, length(args), RRID))
    for arg in args        # send args one by one
        put!(ref.cn, arg)
    end
    return rr
end

function stop(ref::ActorRef)
    callOn(ref, (_Stop,))
    close(ref.cn)
end

function mergeFuture(futures)
    cn = Channel()
    counter = length(futures)
    for (i, f) in enumerate(futures)
        @async begin
            put!(cn, fetch(f)); 
            counter-=1; 
            if counter == 0 
                close(cn) 
            end
        end
    end
    cn
end

end ## module
