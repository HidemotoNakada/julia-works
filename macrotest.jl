module Test
export @mylog

macro mylog(expr)
    return :(_mylog($(esc(expr))))
end

function _mylog(val)
    println("$val")
end 

end

##
using .Test

a = "value"
@macroexpand @mylog("test $a")
@mylog("test $a")



###
struct A <: Actor end

struct Mes <: Message 
    x
    y
end

function MyActor2.handle(a::Echo, Mes::mes) 
    mes.x+mes.y
end


##
using MacroTools

macro add_name_2(fdef) 
    d = splitdef(fdef)
    d[:name] = Symbol(string(d[:name]) * "_2")
    combinedef(d)
end

macro defineTwice(fdef) 
    d = splitdef(fdef)
    original = combinedef(d)
    d[:name] = Symbol(string(d[:name]) * "_2")
    with2 = combinedef(d)
    quote
        $(esc(with2))
        $(esc(original))
    end

end

##
using MacroTools
abstract type Actor end
struct A <: Actor offset end
struct ActorRef end

macro remote(fdef) 
    d = splitdef(fdef)
    original = combinedef(d)

    if (! (typeof(d[:args][1]) <: Expr )) || 
                d[:args][1].head != :(::) || 
                !(eval(d[:args][1].args[2]) <: Actor)
        println(stderr, "the first argument should be Actor")
        original
    else 
        ar_var = d[:args][1].args[1]      # ここにチェックを書いて Actor でなければエラーを返す
        d[:args][1].args[2] = :ActorRef
        name = d[:name]
        args = [typeof(arg) <: Expr ? arg.args[1] : arg for arg in d[:args][2:end]]
        argtuple = Expr(:tuple, args...)
        d[:body] = :(callOn($ar_var, ($name, $args)) ) 
        remoteCall = combinedef(d)
        quote
            $(esc(original))
            $(esc(remoteCall))
        end
    end
end



##

@macroexpand @remote function fname(a::A, x, y) 
    x+y
end


##
expr = :(
    function fname(a::A, x, y) 
        x+y
    end
)
## 
splitted = splitdef(expr)
##
first = splitted[:args][1]
##
first.head
first.args[2]

first.args[2] = :b
first

##

include("MyActor3.jl")
using .MyActor
import Revise

struct Echo <: Actor 
    id::Integer
end

@remote function ping(a::Echo, v::Vector{UInt8}) 
    v
end
##

function ping(a::ActorRef{Echo}, v::Vector{UInt8}) 
    v
end

##


abstract type A end
struct B <: A end

struct R{T} end


:( function f(x::A) x end )

using MacroTools

f = :( function f(x::R{A}) x end )
function fun(x::R{B}) x end 

tmp = R{B}()

fun(tmp)

##
tmp  = A

test = R{tmp}()

test