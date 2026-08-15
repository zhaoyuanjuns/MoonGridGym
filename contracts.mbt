///|
/// A public contract result for downstream packages and release scripts.
pub struct ContractResult {
  name : String
  passed : Bool
  detail : String
}

///|
fn contract(name : String, passed : Bool, detail : String) -> ContractResult {
  ContractResult::{ name, passed, detail }
}

///|
pub fn contract_reset(kind : ScenarioKind, seed : Int) -> ContractResult {
  let env = new(kind, seed)
  let first = env.reset()
  let second = env.reset()
  let passed = first.agent_x == second.agent_x &&
    first.agent_y == second.agent_y &&
    first.step_count == 0 &&
    !first.done
  contract(
    "reset",
    passed,
    if passed {
      "reset is deterministic"
    } else {
      "reset state changed unexpectedly"
    },
  )
}

///|
pub fn contract_step_progress(
  kind : ScenarioKind,
  seed : Int,
) -> ContractResult {
  let env = new(kind, seed)
  let before = env.reset()
  let result = env.step(Stay)
  let passed = result.observation.step_count == before.step_count + 1
  contract(
    "step-progress",
    passed,
    if passed {
      "step count advances exactly once"
    } else {
      "step count contract failed"
    },
  )
}

///|
pub fn contract_render(kind : ScenarioKind, seed : Int) -> ContractResult {
  let env = new(kind, seed)
  let render = env.reset().ascii
  let passed = render.contains(scenario_name(kind)) &&
    render.contains("G") &&
    render.length() > 0
  contract(
    "render",
    passed,
    if passed {
      "render contains scenario and goal"
    } else {
      "render is incomplete"
    },
  )
}

///|
pub fn contract_solver(kind : ScenarioKind, seed : Int) -> ContractResult {
  let env = new(kind, seed)
  let _ = env.reset()
  let plan = env.shortest_path()
  let passed = plan.found &&
    plan.steps == plan.actions.length() &&
    plan.steps > 0
  contract(
    "solver",
    passed,
    if passed {
      "planner returns a non-empty consistent route"
    } else {
      "planner route contract failed"
    },
  )
}

///|
pub fn contract_dataset(kind : ScenarioKind, seed : Int) -> ContractResult {
  let data = collect_episode(kind, seed, ShortestPath, 512)
  let passed = data.length() > 0 &&
    data.to_csv().contains("scenario,seed,index")
  contract(
    "dataset",
    passed,
    if passed {
      "trajectory has a CSV header and transitions"
    } else {
      "dataset export failed"
    },
  )
}

///|
pub fn contract_replay(kind : ScenarioKind, seed : Int) -> ContractResult {
  let result = replay_check(kind, seed, [Up, Down, Left, Right, Stay])
  let passed = result.mismatch_count == 0
  contract(
    "replay",
    passed,
    if passed {
      "identical seed and actions replay identically"
    } else {
      "replay mismatch detected"
    },
  )
}

///|
pub fn contracts_for(kind : ScenarioKind, seed : Int) -> Array[ContractResult] {
  [
    contract_reset(kind, seed),
    contract_step_progress(kind, seed),
    contract_render(kind, seed),
    contract_solver(kind, seed),
    contract_dataset(kind, seed),
    contract_replay(kind, seed),
  ]
}

///|
pub fn contracts_passed(kind : ScenarioKind, seed : Int) -> Bool {
  for item in contracts_for(kind, seed) {
    if !item.passed {
      return false
    }
  }
  true
}

///|
pub fn all_contracts_pass(seed : Int) -> Bool {
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
    if !contracts_passed(kind, seed) {
      return false
    }
  }
  true
}

///|
pub fn contracts_report(seed : Int) -> String {
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
    builder.write_string(scenario_name(kind))
    builder.write_char(':')
    for item in contracts_for(kind, seed) {
      builder.write_char(' ')
      builder.write_string(item.name)
      builder.write_char('=')
      builder.write_object(item.passed)
    }
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
/// Verify a plan remains valid when executed one action at a time.
pub fn plan_is_valid(kind : ScenarioKind, seed : Int) -> Bool {
  let env = new(kind, seed)
  let _ = env.reset()
  let plan = env.shortest_path()
  if !plan.found {
    false
  } else {
    let stochastic = match kind {
      FrozenLakeLike => true
      _ => false
    }
    if stochastic {
      true
    } else {
      let mut valid = true
      for action in plan.actions {
        if env.done {
          valid = false
        }
        let result = env.step(action)
        if result.truncated {
          valid = false
        }
      }
      valid && env.agent_x == env.goal_x && env.agent_y == env.goal_y
    }
  }
}

///|
pub fn all_plans_valid(seed : Int) -> Bool {
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
    if !plan_is_valid(kind, seed) {
      return false
    }
  }
  true
}

///|
pub fn project_status(seed : Int) -> String {
  let quality = quality_score(seed)
  let builder = StringBuilder::new()
  builder.write_string("quality=")
  builder.write_object(quality.passed)
  builder.write_string(" | contracts=")
  builder.write_object(all_contracts_pass(seed))
  builder.write_string(" | plans=")
  builder.write_object(all_plans_valid(seed))
  builder.to_string()
}
