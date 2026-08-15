///|
/// A compact transition record suitable for offline RL and regression data.
pub struct Transition {
  scenario : String
  seed : Int
  index : Int
  x : Int
  y : Int
  action : String
  reward : Int
  next_x : Int
  next_y : Int
  terminated : Bool
  truncated : Bool
  info : String
}

///|
/// An in-memory episode dataset. It intentionally uses plain arrays so it is
/// easy to export, inspect, and feed into another MoonBit package.
pub struct EpisodeDataset {
  scenario : String
  seed : Int
  transitions : Array[Transition]
  total_reward : Int
  success : Bool
}

///|
fn transition_line(item : Transition) -> String {
  let builder = StringBuilder::new()
  builder.write_string(item.scenario)
  builder.write_char(',')
  builder.write_object(item.seed)
  builder.write_char(',')
  builder.write_object(item.index)
  builder.write_char(',')
  builder.write_object(item.x)
  builder.write_char(',')
  builder.write_object(item.y)
  builder.write_char(',')
  builder.write_string(item.action)
  builder.write_char(',')
  builder.write_object(item.reward)
  builder.write_char(',')
  builder.write_object(item.next_x)
  builder.write_char(',')
  builder.write_object(item.next_y)
  builder.write_char(',')
  builder.write_object(item.terminated)
  builder.write_char(',')
  builder.write_object(item.truncated)
  builder.write_char(',')
  builder.write_string(item.info)
  builder.to_string()
}

///|
/// Collect a replayable trajectory using any action policy.
pub fn collect_episode(
  kind : ScenarioKind,
  seed : Int,
  policy : PolicyKind,
  max_steps : Int,
) -> EpisodeDataset {
  let env = new(kind, seed)
  let _ = env.reset()
  let transitions = Array::new(capacity=max_steps)
  let mut state_seed = seed
  let mut total_reward = 0
  let mut done = false
  let mut index = 0
  while index < max_steps && !done {
    let before_x = env.agent_x
    let before_y = env.agent_y
    let (next_seed, action) = policy_action(env, policy, state_seed)
    state_seed = next_seed
    let result = env.step(action)
    transitions.push(Transition::{
      scenario: scenario_name(kind),
      seed,
      index,
      x: before_x,
      y: before_y,
      action: action_name(action),
      reward: result.reward,
      next_x: result.observation.agent_x,
      next_y: result.observation.agent_y,
      terminated: result.terminated,
      truncated: result.truncated,
      info: result.info,
    })
    total_reward = total_reward + result.reward
    done = result.terminated || result.truncated
    index = index + 1
  }
  EpisodeDataset::{
    scenario: scenario_name(kind),
    seed,
    transitions,
    total_reward,
    success: env.done && env.agent_x == env.goal_x && env.agent_y == env.goal_y,
  }
}

///|
pub fn EpisodeDataset::length(self : EpisodeDataset) -> Int {
  self.transitions.length()
}

///|
pub fn EpisodeDataset::to_csv(self : EpisodeDataset) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "scenario,seed,index,x,y,action,reward,next_x,next_y,terminated,truncated,info\n",
  )
  for item in self.transitions {
    builder.write_string(transition_line(item))
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
pub fn EpisodeDataset::summary(self : EpisodeDataset) -> String {
  let builder = StringBuilder::new()
  builder.write_string(self.scenario)
  builder.write_string(" | seed=")
  builder.write_object(self.seed)
  builder.write_string(" | transitions=")
  builder.write_object(self.transitions.length())
  builder.write_string(" | reward=")
  builder.write_object(self.total_reward)
  builder.write_string(" | success=")
  builder.write_object(self.success)
  builder.to_string()
}

///|
/// Collect one deterministic planner trajectory for every bundled scenario.
pub fn collect_reference_dataset(seed : Int) -> Array[EpisodeDataset] {
  let result = Array::new(capacity=7)
  for
    kind in [
      GridWorld,
      CliffWalking,
      Maze,
      FrozenLakeLike,
      RandomMaze,
      EmptyRoom,
      FourRooms,
    ] {
    result.push(collect_episode(kind, seed, ShortestPath, 512))
  }
  result
}
