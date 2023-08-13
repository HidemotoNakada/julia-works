using Distributed

if length(ARGS) < 2 
    println("USAGE: num_workers num_episodes_in_total")
    exit()    
end
num_workers = parse(Int, ARGS[1])
num_episodes_in_total = parse(Int, ARGS[2])
num_episode = num_episodes_in_total / num_workers

procs = addprocs(num_workers)

@everywhere begin
    using PyCall
    gym = pyimport("gymnasium")
    
    include("ql_framework.jl")
    include("cart_pole_agent.jl")
end


#fw = QlFramework(env, agent, digitize_state)

# to compile
fw = @QL(num_workers, "CartPole-v1", Agent(2), digitize_state, 1, 1)
step_lists = run!(fw)

# for real run
fw = @QL(num_workers, "CartPole-v1", Agent(2), digitize_state, 500, num_episode)
@time step_lists = run!(fw)

println(size(step_lists))