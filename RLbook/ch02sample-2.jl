using Revise

include("ch01sample.jl")
using Main.rl

abstract type Planner end

# env
# log::Vector{string}


function initialize(pl::Planner)
    rl.reset(pl.env);
    pl.log = []
end

function plan(planner::Planner, gamma=0.0, threshold=0.0001)
    error("not implemented")
end    

function transitions_at(planner::Planner, state::State, action::Action)
    transition_probs = ql.transit_func(planner.env, state, action)
    r = [(prob, next_state, ql.reward_func(planner.env, next_state)[1])
        for (next_state, prob) in transition_probs]
    r
end    

function dict_to_grid(planner::Planner, state_reward_dict::Dict)
    grid = zeros(ql.row_length(planner.env), ql.column_length(planner.env))
    for (s, reward) in state_reward_dict
        grid[s.row, s.column] = reward
    end
    grid
end



