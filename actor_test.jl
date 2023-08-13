using Distributed
addprocs(3)

@everywhere include("MyActor4.jl")
@everywhere using .MyActor


@everywhere begin

    struct A <: Actor
        b
    end

    mutable struct B <: Actor
        c
    end

    @remote function run(a::A, mes) 
        for i in 1:1000
            run(a.b, mes)
        end
    end

    @remote function run(b::B, mes)
        b.c += 1
    end

end


b_ref = @startat 1 B(0)
n = 2
as = [@startat i+1 A(b_ref) for i in 1:n]
futures = [run(a, "test") for a in as]
[fetch(f) for f in futures]

println(run(b_ref, "test") |> fetch)

