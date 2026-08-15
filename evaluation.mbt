///|
/// Policy families used by the local benchmark harness.
pub(all) enum PolicyKind {
  ShortestPath
  GreedyGoal
  SeededRandom
  Stay
}

///|
/// One measured episode. The structure is deliberately small so callers can
/// store many records without depending on a logging framework.
pub struct EpisodeScore {
  scenario : String
  policy : String
  seed : Int
  steps : Int
  reward : Int
  success : Bool
  terminated : Bool
  truncated : Bool
  reachable : Int
  planned_steps : Int
}

///|
/// Aggregate result for one scenario and policy pair.
pub struct BenchmarkRow {
  scenario : String
  policy : String
  episodes : Int
  successes : Int
  total_steps : Int
  total_reward : Int
  min_steps : Int
  max_steps : Int
  reachable : Int
  planned_steps : Int
}

///|
/// Validation result used by CI and release checks.
pub struct ValidationReport {
  scenario : String
  valid : Bool
  reachable : Int
  planned_steps : Int
  checks : Int
  failures : Int
  message : String
}

///|
fn policy_name(policy : PolicyKind) -> String {
  match policy {
    ShortestPath => "shortest-path"
    GreedyGoal => "greedy-goal"
    SeededRandom => "seeded-random"
    Stay => "stay"
  }
}

///|
pub fn action_name(action : Action) -> String {
  match action {
    Up => "Up"
    Down => "Down"
    Left => "Left"
    Right => "Right"
    Stay => "Stay"
  }
}

///|
pub fn scenario_name(kind : ScenarioKind) -> String {
  match kind {
    GridWorld => "GridWorld"
    CliffWalking => "CliffWalking"
    Maze => "Maze"
    FrozenLakeLike => "FrozenLakeLike"
    RandomMaze => "RandomMaze"
    EmptyRoom => "EmptyRoom"
    FourRooms => "FourRooms"
  }
}

///|
fn next_policy_seed(seed : Int) -> (Int, Int) {
  let next = (seed * 1_664_525 + 1_013_904_223) % 2_147_483_647
  let fixed = if next < 0 { next + 2_147_483_647 } else { next }
  (fixed, fixed % 5)
}

///|
fn random_action(seed : Int) -> (Int, Action) {
  let (next, code) = next_policy_seed(seed)
  let action = match code {
    0 => Up
    1 => Down
    2 => Left
    3 => Right
    _ => Stay
  }
  (next, action)
}

///|
fn greedy_action(env : GridGym) -> Action {
  let dx = env.goal_x - env.agent_x
  let dy = env.goal_y - env.agent_y
  if dx > 0 {
    Right
  } else if dx < 0 {
    Left
  } else if dy > 0 {
    Down
  } else if dy < 0 {
    Up
  } else {
    Stay
  }
}

///|
fn policy_action(
  env : GridGym,
  policy : PolicyKind,
  state : Int,
) -> (Int, Action) {
  match policy {
    ShortestPath => {
      let plan = env.shortest_path()
      if plan.found && plan.actions.length() > 0 {
        (state, plan.actions[0])
      } else {
        (state, Stay)
      }
    }
    GreedyGoal => (state, greedy_action(env))
    SeededRandom => random_action(state)
    Stay => (state, Stay)
  }
}

///|
/// Run a policy with a hard safety cap. The cap prevents a faulty policy from
/// hanging a benchmark runner even when an environment is misconfigured.
pub fn run_policy(
  env : GridGym,
  policy : PolicyKind,
  seed : Int,
  max_steps : Int,
) -> EpisodeScore {
  let initial = env.reset()
  let plan = env.shortest_path()
  let reachable = env.reachable_cells()
  let mut current_seed = seed
  let mut steps = 0
  let mut reward = 0
  let mut terminated = false
  let mut truncated = false
  while steps < max_steps && !terminated && !truncated {
    let (next_seed, action) = policy_action(env, policy, current_seed)
    current_seed = next_seed
    let result = env.step(action)
    reward = reward + result.reward
    steps = steps + 1
    terminated = result.terminated
    truncated = result.truncated
  }
  let success = terminated &&
    env.agent_x == env.goal_x &&
    env.agent_y == env.goal_y
  EpisodeScore::{
    scenario: initial.kind,
    policy: policy_name(policy),
    seed,
    steps,
    reward,
    success,
    terminated,
    truncated,
    reachable,
    planned_steps: if plan.found {
      plan.steps
    } else {
      -1
    },
  }
}

///|
fn add_score(row : BenchmarkRow, score : EpisodeScore) -> BenchmarkRow {
  let min_steps = if score.steps < row.min_steps {
    score.steps
  } else {
    row.min_steps
  }
  let max_steps = if score.steps > row.max_steps {
    score.steps
  } else {
    row.max_steps
  }
  let success_count = if score.success { 1 } else { 0 }
  BenchmarkRow::{
    scenario: row.scenario,
    policy: row.policy,
    episodes: row.episodes + 1,
    successes: row.successes + success_count,
    total_steps: row.total_steps + score.steps,
    total_reward: row.total_reward + score.reward,
    min_steps,
    max_steps,
    reachable: score.reachable,
    planned_steps: score.planned_steps,
  }
}

///|
fn empty_row(env : GridGym, policy : PolicyKind) -> BenchmarkRow {
  let plan = env.shortest_path()
  BenchmarkRow::{
    scenario: env.summary(),
    policy: policy_name(policy),
    episodes: 0,
    successes: 0,
    total_steps: 0,
    total_reward: 0,
    min_steps: 2_147_483_647,
    max_steps: 0,
    reachable: env.reachable_cells(),
    planned_steps: if plan.found {
      plan.steps
    } else {
      -1
    },
  }
}

///|
fn row_label(row : BenchmarkRow) -> String {
  let builder = StringBuilder::new()
  builder.write_string(row.scenario)
  builder.write_string(" | ")
  builder.write_string(row.policy)
  builder.write_string(" | episodes=")
  builder.write_object(row.episodes)
  builder.write_string(" | success=")
  builder.write_object(row.successes)
  builder.write_string(" | steps=")
  builder.write_object(row.total_steps)
  builder.write_string(" | reward=")
  builder.write_object(row.total_reward)
  builder.to_string()
}

///|
/// Evaluate every bundled scenario using the deterministic planner and two
/// intentionally weaker baselines. Seeds make the output reproducible.
pub fn benchmark(seed : Int, episodes : Int) -> Array[BenchmarkRow] {
  let count = if episodes < 1 { 1 } else { episodes }
  let kinds = [
    GridWorld,
    CliffWalking,
    Maze,
    FrozenLakeLike,
    RandomMaze,
    EmptyRoom,
    FourRooms,
  ]
  let policies = [ShortestPath, GreedyGoal, SeededRandom]
  let rows = Array::new(capacity=kinds.length() * policies.length())
  for kind in kinds {
    for policy in policies {
      let env = new(kind, seed)
      let mut row = empty_row(env, policy)
      for episode = 0; episode < count; episode = episode + 1 {
        let score = run_policy(
          new(kind, seed + episode),
          policy,
          seed + episode,
          512,
        )
        row = add_score(row, score)
      }
      rows.push(row)
    }
  }
  rows
}

///|
pub fn benchmark_report(seed : Int, episodes : Int) -> String {
  let builder = StringBuilder::new()
  builder.write_string("MoonGridGym benchmark seed=")
  builder.write_object(seed)
  builder.write_string(" episodes=")
  builder.write_object(episodes)
  builder.write_char('\n')
  for row in benchmark(seed, episodes) {
    builder.write_string(row_label(row))
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
fn validation_message(failures : Int, reachable : Int, planned : Int) -> String {
  if failures == 0 {
    "ok"
  } else if reachable <= 0 {
    "start position is not reachable"
  } else if planned < 0 {
    "goal is unreachable"
  } else {
    "one or more invariant checks failed"
  }
}

///|
/// Validate invariants that matter before a scenario is used as benchmark
/// data: reset determinism, non-empty reachability, and a solvable goal.
pub fn validate(kind : ScenarioKind, seed : Int) -> ValidationReport {
  let env = new(kind, seed)
  let first = env.reset()
  let second = env.reset()
  let plan = env.shortest_path()
  let reachable = env.reachable_cells()
  let mut failures = 0
  if first.agent_x != second.agent_x || first.agent_y != second.agent_y {
    failures = failures + 1
  }
  if first.step_count != 0 || first.done {
    failures = failures + 1
  }
  if reachable <= 0 {
    failures = failures + 1
  }
  if !plan.found {
    failures = failures + 1
  }
  let checks = 4
  ValidationReport::{
    scenario: scenario_name(kind),
    valid: failures == 0,
    reachable,
    planned_steps: if plan.found {
      plan.steps
    } else {
      -1
    },
    checks,
    failures,
    message: validation_message(
      failures,
      reachable,
      if plan.found {
        plan.steps
      } else {
        -1
      },
    ),
  }
}

///|
pub fn validate_all(seed : Int) -> Array[ValidationReport] {
  let reports = Array::new(capacity=7)
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
    reports.push(validate(kind, seed))
  }
  reports
}

///|
pub fn validation_report(seed : Int) -> String {
  let builder = StringBuilder::new()
  builder.write_string("validation seed=")
  builder.write_object(seed)
  builder.write_char('\n')
  for report in validate_all(seed) {
    builder.write_string(report.scenario)
    builder.write_string(" | valid=")
    builder.write_object(report.valid)
    builder.write_string(" | checks=")
    builder.write_object(report.checks)
    builder.write_string(" | failures=")
    builder.write_object(report.failures)
    builder.write_string(" | ")
    builder.write_string(report.message)
    builder.write_char('\n')
  }
  builder.to_string()
}
