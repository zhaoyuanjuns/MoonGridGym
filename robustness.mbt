///|
/// Boundary and regression counters used by release automation.
pub struct BoundaryScore {
  scenario : String
  tested_actions : Int
  blocked_actions : Int
  hazard_actions : Int
  goal_actions : Int
  stable : Bool
}

///|
/// Compare planner length with an executed trajectory.
pub struct PlanExecution {
  found : Bool
  planned_steps : Int
  executed_steps : Int
  reached_goal : Bool
  reward : Int
  exact : Bool
}

///|
/// A batch of deterministic snapshots for golden-file style testing.
pub struct SnapshotBatch {
  seed : Int
  values : Array[String]
  checksum : Int
}

///|
fn hash_text(text : String) -> Int {
  let mut value = 17
  for code in text.to_array() {
    value = (value * 31 + code.to_int()) % 1_000_003
  }
  value
}

///|
fn action_count(checks : Array[ActionCheck], hazard : Bool) -> Int {
  let mut total = 0
  for check in checks {
    if check.lands_in_hazard == hazard {
      total = total + 1
    }
  }
  total
}

///|
pub fn boundary_score(kind : ScenarioKind, seed : Int) -> BoundaryScore {
  let env = new(kind, seed)
  let _ = env.reset()
  let checks = env.action_checks()
  let blocked = 0
  let mut goals = 0
  for check in checks {
    if check.reaches_goal {
      goals = goals + 1
    }
  }
  BoundaryScore::{
    scenario: scenario_name(kind),
    tested_actions: checks.length(),
    blocked_actions: blocked +
    action_count(checks, false) -
    checks.length() +
    action_count(checks, true),
    hazard_actions: action_count(checks, true),
    goal_actions: goals,
    stable: checks.length() == 5,
  }
}

///|
/// Exercise all five actions from the initial state and return the outcome
/// counters. This explicitly covers boundary, wall, stay, and hazard paths.
pub fn boundary_report(seed : Int) -> String {
  let builder = StringBuilder::new()
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
    let score = boundary_score(kind, seed)
    builder.write_string(score.scenario)
    builder.write_string(" | actions=")
    builder.write_object(score.tested_actions)
    builder.write_string(" | blocked=")
    builder.write_object(score.blocked_actions)
    builder.write_string(" | hazards=")
    builder.write_object(score.hazard_actions)
    builder.write_string(" | stable=")
    builder.write_object(score.stable)
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
pub fn execute_plan(kind : ScenarioKind, seed : Int) -> PlanExecution {
  let env = new(kind, seed)
  let _ = env.reset()
  let plan = env.shortest_path()
  if !plan.found {
    PlanExecution::{
      found: false,
      planned_steps: -1,
      executed_steps: 0,
      reached_goal: false,
      reward: 0,
      exact: false,
    }
  } else {
    let stats = env.rollout(plan.actions)
    PlanExecution::{
      found: true,
      planned_steps: plan.steps,
      executed_steps: stats.steps,
      reached_goal: stats.terminated,
      reward: stats.reward_sum,
      exact: stats.steps == plan.steps && stats.terminated,
    }
  }
}

///|
pub fn execute_all_plans(seed : Int) -> Array[PlanExecution] {
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
    result.push(execute_plan(kind, seed))
  }
  result
}

///|
pub fn snapshot_batch(seed : Int) -> SnapshotBatch {
  let values = Array::new(capacity=7)
  let mut checksum = seed
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
    let value = snapshot(kind, seed)
    values.push(value)
    checksum = (checksum * 31 + hash_text(value)) % 1_000_003
  }
  SnapshotBatch::{ seed, values, checksum }
}

///|
pub fn snapshot_report(seed : Int) -> String {
  let batch = snapshot_batch(seed)
  let builder = StringBuilder::new()
  builder.write_string("snapshot seed=")
  builder.write_object(batch.seed)
  builder.write_string(" checksum=")
  builder.write_object(batch.checksum)
  builder.write_char('\n')
  for value in batch.values {
    builder.write_string(value)
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Return a stable action table for consumers that serialize actions by code.
pub fn action_table() -> Array[String] {
  ["0:Up", "1:Down", "2:Left", "3:Right", "4:Stay"]
}

///|
/// Return a stable scenario table for metadata and dataset headers.
pub fn scenario_table() -> Array[String] {
  [
    "0:GridWorld", "1:CliffWalking", "2:Maze", "3:FrozenLakeLike", "4:RandomMaze",
    "5:EmptyRoom", "6:FourRooms",
  ]
}

///|
/// Reject unsafe benchmark arguments while retaining a total, predictable API.
pub fn normalized_episode_count(episodes : Int) -> Int {
  if episodes < 1 {
    1
  } else if episodes > 10_000 {
    10_000
  } else {
    episodes
  }
}

///|
pub fn normalized_step_limit(limit : Int) -> Int {
  if limit < 1 {
    1
  } else if limit > 1_000_000 {
    1_000_000
  } else {
    limit
  }
}

///|
/// A short release gate message consumed by the example program and CI logs.
pub fn release_gate(seed : Int) -> String {
  let score = quality_score(seed)
  let mut exact = 0
  for result in execute_all_plans(seed) {
    if result.exact {
      exact = exact + 1
    }
  }
  let builder = StringBuilder::new()
  builder.write_string("valid=")
  builder.write_object(score.passed)
  builder.write_string(" | exact_plans=")
  builder.write_object(exact)
  builder.write_string("/6 deterministic scenarios")
  builder.to_string()
}
