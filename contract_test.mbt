///|
test "contracts_pass_for_every_scenario" {
  for
    kind in [
      @moongridgym.ScenarioKind::GridWorld,
      @moongridgym.ScenarioKind::CliffWalking,
      @moongridgym.ScenarioKind::Maze,
      @moongridgym.ScenarioKind::FrozenLakeLike,
      @moongridgym.ScenarioKind::RandomMaze,
      @moongridgym.ScenarioKind::EmptyRoom,
      @moongridgym.ScenarioKind::FourRooms,
    ] {
    assert_eq(contracts_passed(kind, 2026), true)
    assert_eq(plan_is_valid(kind, 2026), true)
  }
}

///|
test "contract_reports_include_each_name" {
  let report = contracts_report(2026)
  assert_eq(report.contains("reset=true"), true)
  assert_eq(report.contains("step-progress=true"), true)
  assert_eq(report.contains("render=true"), true)
  assert_eq(report.contains("solver=true"), true)
  assert_eq(report.contains("dataset=true"), true)
  assert_eq(report.contains("replay=true"), true)
}

///|
test "policy_comparison_is_complete" {
  let matrix = policy_comparison_matrix(2026)
  assert_eq(matrix.length(), 7)
  for row in matrix {
    assert_eq(row.best_policy.length() > 0, true)
    assert_eq(row.planner_reward != 0, true)
  }
}

///|
test "training_curve_has_one_record_per_episode" {
  let curve = train_curve(RandomMaze, ShortestPath, 2026, 4)
  assert_eq(curve.rewards.length(), 4)
  assert_eq(curve.successes.length(), 4)
  assert_eq(curve.successes(), 4)
  assert_eq(curve.report().contains("episodes=4"), true)
}

///|
test "histogram_counts_transitions" {
  let data = collect_episode(GridWorld, 2026, ShortestPath, 512)
  let hist = histogram(data)
  assert_eq(hist.total, data.length())
  assert_eq(
    hist.up + hist.down + hist.left + hist.right + hist.stay,
    hist.total,
  )
  assert_eq(histogram_report(data).contains("total="), true)
}

///|
test "regret_is_zero_for_planner" {
  assert_eq(total_regret(2026, ShortestPath), 0)
  assert_eq(all_planner_regrets(2026, ShortestPath).length(), 7)
}

///|
test "boundary_reports_have_all_scenarios" {
  let report = boundary_report(2026)
  assert_eq(report.contains("GridWorld"), true)
  assert_eq(report.contains("CliffWalking"), true)
  assert_eq(report.contains("FourRooms"), true)
  assert_eq(report.contains("actions=5"), true)
}

///|
test "snapshot_seed_changes_checksum" {
  let first = snapshot_batch(1)
  let second = snapshot_batch(2)
  assert_eq(first.values.length(), 7)
  assert_eq(first.checksum != second.checksum, true)
}

///|
test "quality_status_is_positive" {
  assert_eq(all_contracts_pass(9), true)
  assert_eq(all_plans_valid(9), true)
  assert_eq(project_status(9).contains("quality=true"), true)
  assert_eq(project_status(9).contains("contracts=true"), true)
  assert_eq(project_status(9).contains("plans=true"), true)
}

///|
test "stochastic_environment_is_seeded" {
  let actions = [
    @moongridgym.Action::Right,
    @moongridgym.Action::Down,
    @moongridgym.Action::Right,
    @moongridgym.Action::Up,
    @moongridgym.Action::Left,
    @moongridgym.Action::Stay,
    @moongridgym.Action::Down,
    @moongridgym.Action::Right,
  ]
  let first = replay_check(FrozenLakeLike, 42, actions)
  let second = replay_check(FrozenLakeLike, 42, actions)
  assert_eq(first.mismatch_count, 0)
  assert_eq(second.mismatch_count, 0)
  assert_eq(first.same_observation, true)
}

///|
test "encoded_dimensions_match_metadata" {
  for
    kind in [
      @moongridgym.ScenarioKind::GridWorld,
      @moongridgym.ScenarioKind::Maze,
      @moongridgym.ScenarioKind::RandomMaze,
      @moongridgym.ScenarioKind::FourRooms,
    ] {
    let env = new(kind, 2026)
    let _ = env.reset()
    let encoded = env.encode()
    assert_eq(encoded.cells.length(), encoded.width * encoded.height)
    assert_eq(encoded.width > 0, true)
    assert_eq(encoded.height > 0, true)
  }
}

///|
test "success_rate_and_mean_reward_are_bounded" {
  let rate = success_rate(RandomMaze, ShortestPath, 2026, 3)
  let reward = mean_reward(RandomMaze, ShortestPath, 2026, 3)
  assert_eq(rate, 100)
  assert_eq(reward > 0, true)
}
