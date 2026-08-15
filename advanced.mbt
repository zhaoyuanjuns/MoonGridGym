///|
/// A rectangular observation encoding for agents that prefer numeric input.
pub struct EncodedObservation {
  width : Int
  height : Int
  agent_x : Int
  agent_y : Int
  goal_x : Int
  goal_y : Int
  step : Int
  done : Bool
  cells : Array[Int]
}

///|
/// Summary of an action's immediate safety without changing the environment.
pub struct ActionCheck {
  action : String
  legal : Bool
  moves : Bool
  reaches_goal : Bool
  lands_in_hazard : Bool
  reason : String
}

///|
/// Difference between two deterministic runs of the same environment.
pub struct ReplayComparison {
  same_observation : Bool
  same_reward : Bool
  same_terminal_flags : Bool
  compared_steps : Int
  mismatch_count : Int
}

///|
/// Static metadata helps applications build scenario pickers without
/// hard-coding descriptions outside the library.
pub struct ScenarioMetadata {
  kind : String
  description : String
  width : Int
  height : Int
  step_limit : Int
  supports_stochasticity : Bool
  recommended_use : String
}

///|
fn cell_code(tile : Int) -> Int {
  match tile {
    TILE_WALL => 1
    TILE_CLIFF => 2
    TILE_HOLE => 3
    _ => 0
  }
}

///|
pub fn GridGym::encode(self : GridGym) -> EncodedObservation {
  let cells = Array::new(capacity=self.width * self.height)
  for y = 0; y < self.height; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      let mut code = cell_code(board_get(self.board, self.width, x, y))
      if x == self.agent_x && y == self.agent_y {
        code = 4
      }
      if x == self.goal_x && y == self.goal_y {
        code = 5
      }
      cells.push(code)
    }
  }
  EncodedObservation::{
    width: self.width,
    height: self.height,
    agent_x: self.agent_x,
    agent_y: self.agent_y,
    goal_x: self.goal_x,
    goal_y: self.goal_y,
    step: self.step_count,
    done: self.done,
    cells,
  }
}

///|
pub fn EncodedObservation::checksum(self : EncodedObservation) -> Int {
  let mut value = self.width * 31 + self.height
  value = value * 31 + self.agent_x
  value = value * 31 + self.agent_y
  value = value * 31 + self.goal_x
  value = value * 31 + self.goal_y
  value = value * 31 + self.step
  for cell in self.cells {
    value = (value * 31 + cell) % 1_000_003
  }
  value
}

///|
fn check_destination(env : GridGym, action : Action) -> ActionCheck {
  let (dx, dy) = action_delta(action)
  let x = env.agent_x + dx
  let y = env.agent_y + dy
  let name = action_name(action)
  if !in_bounds(env.width, env.height, x, y) {
    ActionCheck::{
      action: name,
      legal: false,
      moves: false,
      reaches_goal: false,
      lands_in_hazard: false,
      reason: "boundary",
    }
  } else {
    let tile = board_get(env.board, env.width, x, y)
    if tile == TILE_WALL {
      ActionCheck::{
        action: name,
        legal: false,
        moves: false,
        reaches_goal: false,
        lands_in_hazard: false,
        reason: "wall",
      }
    } else if tile == TILE_CLIFF || tile == TILE_HOLE {
      ActionCheck::{
        action: name,
        legal: true,
        moves: true,
        reaches_goal: false,
        lands_in_hazard: true,
        reason: "hazard",
      }
    } else {
      ActionCheck::{
        action: name,
        legal: true,
        moves: x != env.agent_x || y != env.agent_y,
        reaches_goal: x == env.goal_x && y == env.goal_y,
        lands_in_hazard: false,
        reason: "open",
      }
    }
  }
}

///|
pub fn GridGym::action_checks(self : GridGym) -> Array[ActionCheck] {
  let result = Array::new(capacity=5)
  for action in [Up, Down, Left, Right, Stay] {
    result.push(check_destination(self, action))
  }
  result
}

///|
pub fn GridGym::legal_actions(self : GridGym) -> Array[Action] {
  let result = Array::new(capacity=5)
  for check in self.action_checks() {
    if check.legal {
      let action = match check.action {
        "Up" => Up
        "Down" => Down
        "Left" => Left
        "Right" => Right
        _ => Stay
      }
      result.push(action)
    }
  }
  result
}

///|
fn same_observation(left : Observation, right : Observation) -> Bool {
  left.kind == right.kind &&
  left.ascii == right.ascii &&
  left.agent_x == right.agent_x &&
  left.agent_y == right.agent_y &&
  left.step_count == right.step_count &&
  left.done == right.done
}

///|
/// Replay an action sequence twice from the same seed and compare every
/// result. This catches accidental hidden state and stochastic reset bugs.
pub fn replay_check(
  kind : ScenarioKind,
  seed : Int,
  actions : Array[Action],
) -> ReplayComparison {
  let left = new(kind, seed)
  let right = new(kind, seed)
  let _ = left.reset()
  let _ = right.reset()
  let mut same_obs = true
  let mut same_reward = true
  let mut same_flags = true
  let mut mismatches = 0
  let mut compared = 0
  for action in actions {
    let a = left.step(action)
    let b = right.step(action)
    let obs_ok = same_observation(a.observation, b.observation)
    let reward_ok = a.reward == b.reward
    let flags_ok = a.terminated == b.terminated && a.truncated == b.truncated
    if !obs_ok || !reward_ok || !flags_ok {
      mismatches = mismatches + 1
    }
    same_obs = same_obs && obs_ok
    same_reward = same_reward && reward_ok
    same_flags = same_flags && flags_ok
    compared = compared + 1
  }
  ReplayComparison::{
    same_observation: same_obs,
    same_reward,
    same_terminal_flags: same_flags,
    compared_steps: compared,
    mismatch_count: mismatches,
  }
}

///|
fn metadata(kind : ScenarioKind, env : GridGym) -> ScenarioMetadata {
  let description = match kind {
    GridWorld => "obstacle navigation with a compact fixed board"
    CliffWalking => "risk-sensitive navigation with terminal cliffs"
    Maze => "fixed-size seeded maze benchmark"
    FrozenLakeLike => "slippery navigation with terminal holes"
    RandomMaze => "replayable generated maze for planning experiments"
    EmptyRoom => "low-obstacle baseline for random-walk agents"
    FourRooms => "room-crossing benchmark for hierarchical planning"
  }
  let use_case = match kind {
    CliffWalking => "risk-sensitive policy evaluation"
    FrozenLakeLike => "stochastic control and robustness tests"
    FourRooms => "hierarchical reinforcement learning"
    _ => "path planning and regression testing"
  }
  let stochastic = match kind {
    FrozenLakeLike => true
    _ => false
  }
  ScenarioMetadata::{
    kind: scenario_name(kind),
    description,
    width: env.width,
    height: env.height,
    step_limit: env.step_limit,
    supports_stochasticity: stochastic,
    recommended_use: use_case,
  }
}

///|
pub fn scenario_catalog(seed : Int) -> Array[ScenarioMetadata] {
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
    result.push(metadata(kind, new(kind, seed)))
  }
  result
}

///|
pub fn scenario_catalog_report(seed : Int) -> String {
  let builder = StringBuilder::new()
  for item in scenario_catalog(seed) {
    builder.write_string(item.kind)
    builder.write_string(" | ")
    builder.write_object(item.width)
    builder.write_char('x')
    builder.write_object(item.height)
    builder.write_string(" | limit=")
    builder.write_object(item.step_limit)
    builder.write_string(" | stochastic=")
    builder.write_object(item.supports_stochasticity)
    builder.write_string(" | ")
    builder.write_string(item.recommended_use)
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Measure how often a baseline reaches the target within its safety cap.
pub fn success_rate(
  kind : ScenarioKind,
  policy : PolicyKind,
  seed : Int,
  episodes : Int,
) -> Int {
  let count = if episodes < 1 { 1 } else { episodes }
  let mut successes = 0
  for index = 0; index < count; index = index + 1 {
    let score = run_policy(new(kind, seed + index), policy, seed + index, 512)
    if score.success {
      successes = successes + 1
    }
  }
  successes * 100 / count
}

///|
/// Compute the mean reward using integer hundredths, avoiding floating-point
/// dependencies in small embedded targets.
pub fn mean_reward(
  kind : ScenarioKind,
  policy : PolicyKind,
  seed : Int,
  episodes : Int,
) -> Int {
  let count = if episodes < 1 { 1 } else { episodes }
  let mut total = 0
  for index = 0; index < count; index = index + 1 {
    let score = run_policy(new(kind, seed + index), policy, seed + index, 512)
    total = total + score.reward
  }
  total * 100 / count
}

///|
/// A compact benchmark row for a single seed, useful for snapshot tests.
pub fn snapshot(kind : ScenarioKind, seed : Int) -> String {
  let env = new(kind, seed)
  let encoded = env.reset()
  let code = env.encode().checksum()
  let plan = env.shortest_path()
  let builder = StringBuilder::new()
  builder.write_string(encoded.kind)
  builder.write_string(" | checksum=")
  builder.write_object(code)
  builder.write_string(" | path=")
  builder.write_object(if plan.found { plan.steps } else { -1 })
  builder.to_string()
}
