using Distributions
NUM_DIZITIZED = 8
GAMMA = 0.99  # 時間割引率
ETA = 0.5  # 学習係数

spaces = [
    collect(range(-2.4, 2.4, length=7)),
    collect(range(-3.0, 3.0, length=7)),
    collect(range(-0.5, 0.5, length=7)),
    collect(range(-2.0, 2.0, length=7)),
]
function digitize_state(observation)
    return [searchsortedfirst(spaces[i], observation[i]) for i in 1:4]
end

struct Agent
    num_actions::Int
    q_table::Array{Float32, 5}
    Agent(num_actions::Int) = new(num_actions, 
        zeros(Float32, (num_actions, NUM_DIZITIZED, NUM_DIZITIZED, NUM_DIZITIZED, NUM_DIZITIZED)))
    #        rand(Uniform(-1, 1), (NUM_DIZITIZED, NUM_DIZITIZED, NUM_DIZITIZED, NUM_DIZITIZED, num_actions)))
end    

function get_action(agent::Agent, d_observation::Vector{Int}, step::Int)
    epsilon = 0.5 * (1 / (step + 1))
    if epsilon <= rand()
        return argmax(agent.q_table[:, d_observation...])
    else
        return rand(1:agent.num_actions)
    end
end

function update(agent::Agent, d_observation::Vector{Int}, action::Int, reward, d_observation_next::Vector{Int})
    Max_Q_next = maximum(agent.q_table[:, d_observation_next...])
    agent.q_table[action, d_observation...] = agent.q_table[action, d_observation...] + ETA * (reward + GAMMA * Max_Q_next - agent.q_table[action, d_observation...])
end
