///|
test "gridworld_reset_and_step" {
  let env = @moongridgym.new_grid_world(7)
  let obs = env.reset()
  assert_eq(obs.agent_x, 1)
  assert_eq(obs.agent_y, 1)
  assert_eq(obs.kind, "GridWorld")
  let plan = env.shortest_path()
  assert_eq(plan.found, true)
  assert_eq(plan.steps > 0, true)

  let result = env.step(@moongridgym.Action::Left)
  assert_eq(result.reward, -1)
  assert_eq(result.terminated, false)
  assert_eq(result.truncated, false)
  assert_eq(result.observation.agent_x, 1)
  assert_eq(result.observation.agent_y, 1)
}

///|
test "cliffwalking_falls_fast" {
  let env = @moongridgym.new_cliff_walking(3)
  let _ = env.reset()
  let result = env.step(@moongridgym.Action::Right)
  assert_eq(result.reward, -100)
  assert_eq(result.terminated, true)
  assert_eq(result.truncated, false)
  assert_eq(result.info, "fell into cliff")
}

///|
test "frozen_lake_renders_holes" {
  let env = @moongridgym.new_frozen_lake_like(99)
  let rendered = env.reset().ascii
  assert_eq(rendered.contains("~"), true)
  assert_eq(rendered.contains("FrozenLakeLike"), true)
}

///|
test "random_maze_can_auto_solve" {
  let env = @moongridgym.new_random_maze(2026)
  let plan = env.shortest_path()
  assert_eq(plan.found, true)
  assert_eq(plan.steps > 0, true)
  let stats = env.auto_solve()
  assert_eq(stats.terminated, true)
  assert_eq(stats.reward_sum > 0, true)
}
