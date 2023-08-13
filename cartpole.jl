using PyCall

gym = pyimport("gymnasium")

env = gym.make("CartPole-v1", render_mode="human")
observation, info = env.reset(seed=42)
for _ in 1:1000
    action = env.action_space.sample()
    observation, reward, terminated, truncated, info = env.step(action)
    env.render()
    if terminated | truncated
        observation, info = env.reset()
    end
end
env.close()