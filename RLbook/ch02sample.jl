# code 2-1 

V(s::String, gamma=0.99) =
    R(s) + gamma * max_V_on_next_state(s)

function R(s::String)
    if s == "happy_end"
        1.0
    elseif s == "bad_end"
        -1.0
    else
        0.0
    end
end

function max_V_on_next_state(s::String)
    # If game end, expected value is 0
    if s in ["happy_end", "bad_end"]
        return 0
    end

    actions = ["up", "down"]
    values = []
    for a in actions
        transition_probs = transit_func(s, a)
        #println(transition_probs)
        v = 0
        for next_state in keys(transition_probs)
            prob = transition_probs[next_state]
            v += prob * V(next_state)
        end
        append!(values, v)
    end
    max(values...)
end    

# code 2-2

function transit_func(s, a)
    """
    Make next state by adding action str to state.
    ex: (s = "state", a = "up") => "state_up"
        (s = "state_up", a = "down") => "state_up_down"
    """
    actions = split(s, "_")
    LIMIT_GAME_COUNT = 5
    HAPPY_END_BORDER = 4
    MOVE_PROB = 0.9

    next_state(state, action) = join([state, action], "_")

    if length(actions) == LIMIT_GAME_COUNT
        up_count = sum([a == "up" ? 1 : 0 for a in actions])
        state = up_count >= HAPPY_END_BORDER ? "happy_end" : "bad_end"
        prob = 1.0
        Dict(state => prob)
    else
        opposite = a == "down" ? "up" : "down"
        Dict(
            next_state(s, a) => MOVE_PROB,
            next_state(s, opposite) => 1 - MOVE_PROB,
        )
    end
end    

function main()
    println(V("state"))
    println(V("state_up_up"))
    println(V("state_down_down"))
end

main()
