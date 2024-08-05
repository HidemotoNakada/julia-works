
include("myfuture.jl")

test() = begin
@sync begin
    f = MyFuture{Int64}()
    f2 = MyFuture{Int64}()
    @async begin
        sleep(1)
        put!(f, 100)
    end
    @async begin
        println("1: $(take!(f))")
        put!(f2, 200)
    end
    @async begin
        println("2: $(take!(f2))")
    end

end
end

using BenchmarkTools
@benchmark begin
    f = MyFuture{Int64}()
    @sync begin
        @async take!(f)
        @async begin
            put!(f, 100)
        end
    end
end

