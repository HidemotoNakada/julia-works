using MPIClusterManagers, Distributed
import MPI

MPI.Init()
rank = MPI.Comm_rank(MPI.COMM_WORLD)
size = MPI.Comm_size(MPI.COMM_WORLD)

#manager = MPIClusterManagers.start_main_loop(TCP_TRANSPORT_ALL) 
manager = MPIClusterManagers.start_main_loop(MPI_TRANSPORT_ALL) 

@everywhere import Distributed
println("rank=$rank, size=$size, workers=", workers())

@everywhere function host_and_id()
  strip(read(`hostname`, String)) * " : " * string(Distributed.myid())  
end  

futures = 
  [ @spawnat i host_and_id() for i in workers() ]

for f in futures
  println(fetch(f))
end

MPIClusterManagers.stop_main_loop(manager)

