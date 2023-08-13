
include("MyActor4.jl")
using .MyActor
using PyCall
gym = pyimport("gymnasium")

mutable struct Counter <: Actor
    count::Int
end
@remote function inc(c::Counter)
    println("inc")
    c.count += 1
end
@remote function test(c::Counter)
    println("test")
    "testresult"
end

mutable struct QlDriver <: Actor
    env_name
    env
    agent::ActorRef
    digitize
    MAX_STEPS::Int
    NUM_EPISODES::Int
end

@remote function init(driver::QlDriver)
    println("QlDriver: init")
    driver.env = gym.make(driver.env_name)
end

@remote function test(driver::QlDriver)
    println("QlDriver: test")
    return "testresult"
end
        

struct QlFramework
    drivers::Vector{ActorRef}
    agentWrapper::ActorRef
end

function run!(framework::QlFramework)
    println("QlFramework: run!", typeof(framework.drivers[1]))
    futures = [run!(driver) for driver in framework.drivers]
    return [fetch(future) for future in futures]
end

mutable struct AgentWrapper <: Actor
    agent
end

@remote function get_action(wrapper::AgentWrapper, d_observation::Vector{Int}, step::Int)
#    println("AgentWrapper:get_action, ", step)
    return get_action(wrapper.agent, d_observation, step)
end

@remote function update(wrapper::AgentWrapper, d_observation::Vector{Int}, action::Int, reward, d_observation_next::Vector{Int})
    update(wrapper.agent, d_observation, action, reward, d_observation_next)
end

function QlConst(num_nodes::Int, env_name, agent_thunk, digitize, max_steps=500, num_episodes=10) 
    agent = @startat 1 AgentWrapper(agent_thunk())

    drivers = []
    for i in 1:num_nodes
        driver_ar = @startat i+1 QlDriver(env_name, nothing, agent, digitize, max_steps, num_episodes)
        init(driver_ar)
        push!(drivers, driver_ar) 
    end
    QlFramework(drivers, agent)
end


@remote function run!(driver::QlDriver)
    println("QlDriver: run!")
    step_list = []
    for episode in 1:driver.NUM_EPISODES
        observation, info = driver.env.reset(seed=42)
        d_observation = driver.digitize(observation)
        for step in 1:driver.MAX_STEPS
            action = get_action(driver.agent, d_observation, episode) |> fetch
            observeration_next, reward, terminated, truncated, info = driver.env.step(action - 1)
            d_observation_next = driver.digitize(observeration_next)
            if terminated
#                println(".")
                reward = -1
            elseif truncated
#                println("!")
                reward = 1
            else
                reward = 0
            end
            update(driver.agent, d_observation, action, reward, d_observation_next)
            d_observation = d_observation_next
            if terminated | truncated
                append!(step_list, step)
                break
            end
        end
    end
    return step_list
end


#env = gym.make("CartPole-v1")
#agent = Agent(convert(Int64, env.action_space.n))


macro QL(num_node, env_name, agent_expr, digitize_func, max_steps, num_episodes)
    agent_thunk = esc(:(()->($agent_expr)))
    quote
        QlConst($num_node, $env_name, $agent_thunk, $digitize_func, $max_steps, $num_episodes)
    end    
end