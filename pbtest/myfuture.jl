import Base

mutable struct MyFuture{A}
    lock::Threads.Condition
    v::Union{Some{A}, Nothing}

    MyFuture{A}() where {A} = 
        new{A}(Threads.Condition(), nothing)
end


Base.put!(f::MyFuture, v) = begin
    lock(f.lock)
    try 
        if !isnothing(f.v)
            error("Future already has a value")
        else
            f.v = Some(v)
            notify(f.lock)
        end
    finally
        unlock(f.lock)
    end
end

Base.take!(f::MyFuture) = begin
    lock(f.lock)
    while true
        if !isnothing(f.v)
            unlock(f.lock)
            return f.v.value
        else
            wait(f.lock)
        end
    end
    unlock(f.lock)
end

fetch(f) = take!(f)