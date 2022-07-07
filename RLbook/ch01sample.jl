module rl


using StatsBase, DataStructures
export State, Action, Environment, row_length, column_length, actions

# code 1-1

mutable struct State
    row::Int
    column::Int  
    State(row = -1, column = -1) = new(row, column)
end
Base.copy(s::State) = State(s.row, s.column)
Base.hash(s::State, h::UInt) = hash(s.row) + hash(s.column)
Base.:(==)(s1::State, s2::State) = (s1.row == s2.row && s1.column == s2.column)
#Base.show(io::Core.IO, s::State) = print(io, "[$(s.row), $(s.column))")

@enum Action begin
    UP = 1
    DOWN = -1
    LEFT = 2
    RIGHT = -2
end

# code 1-2

mutable struct Environment
    grid
    agent_state::State
    default_reward::Float64
    move_prob::Float64
    Environment(grid, move_prob=0.8) = new(grid, State(0, 0), -0.04, move_prob)
end

row_length(env::Environment)    = size(env.grid)[1]
column_length(env::Environment) = size(env.grid)[2]
actions(env::Environment)       = [UP, DOWN, LEFT, RIGHT]

function states(env::Environment)
    [State(r, c) for r in 1:row_length(env) for c in 1:column_length(env) if env.grid[r,c] != 9]
end

function Base.show(io::IO, env::Environment)
    for y in 1:row_length(env)
        for x in 1:column_length(env)
            print(io, env.grid[y,x])
            print(io, " ")
        end
        print(io, "\n")
    end
end

# code 1-3

function transit_func(env::Environment, state::State, action::Action)
    transition_probs = DefaultDict{State, Float64}(0.0)
    if ! can_action_at(env, state)
        return transition_probs
    end
    oppsite_direction = Action(Int(action) * -1)

    for a in actions(env)
        prob = 0.0
        if a == action
            prob = env.move_prob
        elseif a != oppsite_direction
            prob = (1.0 - env.move_prob) /2.0
        end

        next_state = _move(env, state, a)
        transition_probs[next_state] += prob
    end
    transition_probs
end


can_action_at(env::Environment, state::State) = (env.grid[state.row, state.column] == 0)

function _move(env::Environment, state::State, action::Action)
    if ! can_action_at(env, state) 
        error("Can't move from here!")
    end
    next_state = copy(state)
    if action == UP
        next_state.row -= 1
    elseif action == DOWN
        next_state.row += 1
    elseif action == LEFT
        next_state.column -= 1
    else # RIGHT
        next_state.column += 1
    end
    if ! (1 <= next_state.row <= row_length(env))
        next_state = state
    end
    if ! (1 <= next_state.column <= column_length(env))
        next_state = state
    end
    if env.grid[next_state.row, next_state.column] == 9
        next_state = state
    end
    next_state
end

# code 1-4
function reward_func(env::Environment, state::State)
    attribute = env.grid[state.row, state.column]
    if attribute == 1
        1, true
    elseif attribute == -1
        -1, true
    else
        env.default_reward, false
    end
end

# code 1-5

function reset(env::Environment)
    env.agent_state = State(row_length(env), 2)
    env.agent_state
end

function step(env::Environment, action::Action)
    next_state, reward, done = transit(env, env.agent_state, action)
    if ! isnothing(next_state)
        env.agent_state = next_state
    end
    next_state, reward, done
end

function transit(env::Environment, state::State, action::Action)
    transition_probs = transit_func(env, state, action)
    if length(transition_probs) == 0
        nothing, 0, true
    else
        next_state = collect(keys(transition_probs))
        probs = collect(values(transition_probs))
        #println("next_state = $next_state, probs = $probs")
        next_state =  sample(next_state, ProbabilityWeights(probs))
        reward, done = reward_func(env, next_state)
        next_state, reward, done
    end
end

end
##
import Revise
using Main.rl

# code 1-6

module rl_test
import StatsBase
using Main.rl

export main

mutable struct Agent
    actions
    Agent(env::Environment) = new(actions(env))
end

policy(agent::Agent) =StatsBase.sample(agent.actions)

function main()
    grid = [0 0 0  0
            0 0 0 -1
            0 0 0 0
            1 0 9 0] 
    println(grid)
    env = Environment(grid)
    println(env)
    agent = Agent(env)

    for i in 1:10
        state = rl.reset(env)
        total_reward = 0
        done = false

        while ! done
            action = policy(agent)
            next_state, reward, done = rl.step(env, action)
            #println("$state, $next_state, $done")
            total_reward += reward
            state = next_state
        end
        println("Eposode $(i): Agent gets $(total_reward)")
    end
end

end
##

using Main.rl_test

main()




##