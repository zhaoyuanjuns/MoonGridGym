///|
/// Per-policy comparison used to choose a baseline before adding a learner.
pub struct PolicyComparison {
  scenario : String
  seed : Int
  best_policy : String
  best_reward : Int
  planner_reward : Int
  greedy_reward : Int
  random_reward : Int
  stay_reward : Int
  planner_success : Bool
  greedy_success : Bool
  random_success : Bool
  stay_success : Bool
}

///|
/// Counted action distribution for a collected trajectory.
pub struct ActionHistogram {
  up : Int
  down : Int
  left : Int
  right : Int
  stay : Int
  total : Int
}

///|
/// A compact training curve with reward and success observations per episode.
pub struct TrainingCurve {
  scenario : String
  policy : String
  rewards : Array[Int]
  successes : Array[Bool]
  cumulative_reward : Int
}

///|
fn score_for(
  kind : ScenarioKind,
  policy : PolicyKind,
  seed : Int,
) -> EpisodeScore {
  run_policy(new(kind, seed), policy, seed, 512)
}

///|
fn best_policy_name(
  planner : EpisodeScore,
  greedy : EpisodeScore,
  random : EpisodeScore,
  stay : EpisodeScore,
) -> String {
  let mut name = planner.policy
  let mut reward = planner.reward
  if greedy.reward > reward {
    name = greedy.policy
    reward = greedy.reward
  }
  if random.reward > reward {
    name = random.policy
    reward = random.reward
  }
  if stay.reward > reward {
    name = stay.policy
  }
  name
}

///|
pub fn compare_policies(kind : ScenarioKind, seed : Int) -> PolicyComparison {
  let planner = score_for(kind, ShortestPath, seed)
  let greedy = score_for(kind, GreedyGoal, seed)
  let random = score_for(kind, SeededRandom, seed)
  let stay = score_for(kind, Stay, seed)
  PolicyComparison::{
    scenario: scenario_name(kind),
    seed,
    best_policy: best_policy_name(planner, greedy, random, stay),
    best_reward: if planner.reward > greedy.reward &&
      planner.reward > random.reward &&
      planner.reward > stay.reward {
      planner.reward
    } else if greedy.reward > random.reward && greedy.reward > stay.reward {
      greedy.reward
    } else if random.reward > stay.reward {
      random.reward
    } else {
      stay.reward
    },
    planner_reward: planner.reward,
    greedy_reward: greedy.reward,
    random_reward: random.reward,
    stay_reward: stay.reward,
    planner_success: planner.success,
    greedy_success: greedy.success,
    random_success: random.success,
    stay_success: stay.success,
  }
}

///|
fn histogram_add(hist : ActionHistogram, action : String) -> ActionHistogram {
  let up = if action == "Up" { hist.up + 1 } else { hist.up }
  let down = if action == "Down" { hist.down + 1 } else { hist.down }
  let left = if action == "Left" { hist.left + 1 } else { hist.left }
  let right = if action == "Right" { hist.right + 1 } else { hist.right }
  let stay = if action == "Stay" { hist.stay + 1 } else { hist.stay }
  ActionHistogram::{ up, down, left, right, stay, total: hist.total + 1 }
}

///|
pub fn histogram(dataset : EpisodeDataset) -> ActionHistogram {
  let mut result = ActionHistogram::{
    up: 0,
    down: 0,
    left: 0,
    right: 0,
    stay: 0,
    total: 0,
  }
  for item in dataset.transitions {
    result = histogram_add(result, item.action)
  }
  result
}

///|
pub fn histogram_report(dataset : EpisodeDataset) -> String {
  let hist = histogram(dataset)
  let builder = StringBuilder::new()
  builder.write_string(dataset.scenario)
  builder.write_string(" | total=")
  builder.write_object(hist.total)
  builder.write_string(" | Up=")
  builder.write_object(hist.up)
  builder.write_string(" | Down=")
  builder.write_object(hist.down)
  builder.write_string(" | Left=")
  builder.write_object(hist.left)
  builder.write_string(" | Right=")
  builder.write_object(hist.right)
  builder.write_string(" | Stay=")
  builder.write_object(hist.stay)
  builder.to_string()
}

///|
pub fn train_curve(
  kind : ScenarioKind,
  policy : PolicyKind,
  seed : Int,
  episodes : Int,
) -> TrainingCurve {
  let count = normalized_episode_count(episodes)
  let rewards = Array::new(capacity=count)
  let successes = Array::new(capacity=count)
  let mut cumulative = 0
  for index = 0; index < count; index = index + 1 {
    let score = score_for(kind, policy, seed + index)
    rewards.push(score.reward)
    successes.push(score.success)
    cumulative = cumulative + score.reward
  }
  TrainingCurve::{
    scenario: scenario_name(kind),
    policy: policy_name(policy),
    rewards,
    successes,
    cumulative_reward: cumulative,
  }
}

///|
pub fn TrainingCurve::successes(self : TrainingCurve) -> Int {
  let mut count = 0
  for success in self.successes {
    if success {
      count = count + 1
    }
  }
  count
}

///|
pub fn TrainingCurve::report(self : TrainingCurve) -> String {
  let builder = StringBuilder::new()
  builder.write_string(self.scenario)
  builder.write_string(" | policy=")
  builder.write_string(self.policy)
  builder.write_string(" | episodes=")
  builder.write_object(self.rewards.length())
  builder.write_string(" | successes=")
  builder.write_object(self.successes())
  builder.write_string(" | cumulative_reward=")
  builder.write_object(self.cumulative_reward)
  builder.to_string()
}

///|
/// Produce a comparison matrix with one row per scenario.
pub fn policy_comparison_matrix(seed : Int) -> Array[PolicyComparison] {
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
    result.push(compare_policies(kind, seed))
  }
  result
}

///|
pub fn policy_comparison_report(seed : Int) -> String {
  let builder = StringBuilder::new()
  for item in policy_comparison_matrix(seed) {
    builder.write_string(item.scenario)
    builder.write_string(" | best=")
    builder.write_string(item.best_policy)
    builder.write_string(" | best_reward=")
    builder.write_object(item.best_reward)
    builder.write_string(" | planner=")
    builder.write_object(item.planner_reward)
    builder.write_string(" | greedy=")
    builder.write_object(item.greedy_reward)
    builder.write_string(" | random=")
    builder.write_object(item.random_reward)
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// A conservative regret estimate relative to the built-in planner.
pub fn planner_regret(
  kind : ScenarioKind,
  policy : PolicyKind,
  seed : Int,
) -> Int {
  let planner = score_for(kind, ShortestPath, seed)
  let candidate = score_for(kind, policy, seed)
  planner.reward - candidate.reward
}

///|
pub fn all_planner_regrets(seed : Int, policy : PolicyKind) -> Array[Int] {
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
    result.push(planner_regret(kind, policy, seed))
  }
  result
}

///|
pub fn total_regret(seed : Int, policy : PolicyKind) -> Int {
  let mut total = 0
  for value in all_planner_regrets(seed, policy) {
    total = total + value
  }
  total
}
