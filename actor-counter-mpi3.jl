# actor-test
# for mpiclusterManager


using MPIClusterManagers, Distributed
import MPI
transport = MPI_TRANSPORT_ALL

if length(ARGS) > 0 
    if ARGS[1] == "--hooked"
        include("hooks.jl")
    else
        println(stderr, "unknown arg $(ARGS[1])")
        exit()
    end
end
include("MyActor3.jl")
using .MyActor


# Actor の状態を表す構造体
mutable struct Counter <: Actor 
    v::Int64 
  end
    
  # @remote マクロを用いて通常の関数としてハンドラを定義
  @remote function add(c::Counter, v::Int64) 
    c.v += v
  end
    
  @remote function sub(c::Counter, v::Int64) 
    c.v -= v
  end
  


MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
manager = MPIClusterManagers.start_main_loop(transport)

##

  
# Actor をノード 2 に作成
counter = @startat 2 Counter(0)
  
  # 通常の関数呼び出しで Actor のメッセージハンドラを実行
println(fetch(add(counter, 10)))

MPIClusterManagers.stop_main_loop(manager)



