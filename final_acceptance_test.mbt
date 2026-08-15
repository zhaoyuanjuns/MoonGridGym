///|
test "cliffwalking_goal_has_positive_reward" {
  let env = @moongridgym.new_cliff_walking(2026)
  let _ = env.reset()
  let plan = env.shortest_path()
  assert_eq(plan.found, true)
  let stats = env.rollout(plan.actions)
  assert_eq(stats.terminated, true)
  assert_eq(stats.reward_sum > 0, true)
}

///|
test "cliffwalking_fall_keeps_negative_reward" {
  let env = @moongridgym.new_cliff_walking(2026)
  let _ = env.reset()
  let result = env.step(@moongridgym.Action::Right)
  assert_eq(result.reward, -100)
  assert_eq(result.terminated, true)
  assert_eq(result.info, "fell into cliff")
}

///|
test "frozenlake_slip_is_seeded_but_not_ignored" {
  let stay_seed = @moongridgym.new_frozen_lake_like(1)
  let move_seed = @moongridgym.new_frozen_lake_like(2)
  let _ = stay_seed.reset()
  let _ = move_seed.reset()
  let stayed = stay_seed.step(@moongridgym.Action::Right)
  let moved = move_seed.step(@moongridgym.Action::Right)
  assert_eq(stayed.observation.agent_x, 0)
  assert_eq(moved.observation.agent_x, 1)
}

///|
test "step_limit_truncates_without_termination" {
  let env = @moongridgym.new_grid_world(2026)
  let _ = env.reset()
  let mut last = env.step(@moongridgym.Action::Stay)
  for index = 1; index < 48; index = index + 1 {
    last = env.step(@moongridgym.Action::Stay)
  }
  assert_eq(last.truncated, true)
  assert_eq(last.terminated, false)
  assert_eq(last.info, "step limit reached")
}

///|
test "reset_restores_seeded_state" {
  let env = @moongridgym.new_frozen_lake_like(2026)
  let first = env.reset()
  let _ = env.step(@moongridgym.Action::Right)
  let second = env.reset()
  assert_eq(first.agent_x, second.agent_x)
  assert_eq(first.agent_y, second.agent_y)
  assert_eq(first.step_count, second.step_count)
  assert_eq(first.ascii, second.ascii)
}
