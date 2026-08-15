///|
test "all_scenarios_validate" {
  let reports = validate_all(2026)
  assert_eq(reports.length(), 7)
  for report in reports {
    assert_eq(report.valid, true)
    assert_eq(report.failures, 0)
    assert_eq(report.planned_steps > 0, true)
  }
}

///|
test "benchmark_has_real_matrix" {
  let rows = benchmark(2026, 2)
  assert_eq(rows.length(), 21)
  for row in rows {
    assert_eq(row.episodes, 2)
    assert_eq(row.total_steps > 0, true)
    assert_eq(row.scenario.length() > 0, true)
  }
}

///|
test "reference_dataset_is_replayable" {
  let datasets = collect_reference_dataset(77)
  assert_eq(datasets.length(), 7)
  for dataset in datasets {
    assert_eq(dataset.length() > 0, true)
    assert_eq(dataset.to_csv().contains("terminated"), true)
  }
  assert_eq(datasets[0].success, true)
  assert_eq(datasets[1].success, true)
  assert_eq(datasets[2].success, true)
  assert_eq(datasets[4].success, true)
  assert_eq(datasets[5].success, true)
  assert_eq(datasets[6].success, true)
}

///|
test "action_checks_cover_catalog" {
  let env = new_grid_world(5)
  let checks = env.action_checks()
  assert_eq(checks.length(), 5)
  assert_eq(env.legal_actions().length() > 0, true)
  assert_eq(action_roundtrip_count(), 5)
  assert_eq(available_policies().length(), 4)
}

///|
test "replay_is_deterministic" {
  let result = replay_check(RandomMaze, 2026, [
    Right,
    Right,
    Down,
    Left,
    Stay,
    Up,
    Right,
  ])
  assert_eq(result.compared_steps, 7)
  assert_eq(result.same_observation, true)
  assert_eq(result.same_reward, true)
  assert_eq(result.same_terminal_flags, true)
  assert_eq(result.mismatch_count, 0)
}

///|
test "encoded_observation_changes_after_step" {
  let env = new_empty_room(9)
  let _ = env.reset()
  let first = env.encode().checksum()
  let _ = env.step(Right)
  let second = env.encode().checksum()
  assert_eq(first != second, true)
  assert_eq(env.encode().cells.length(), 49)
}

///|
test "metadata_catalog_is_complete" {
  let catalog = scenario_catalog(1)
  assert_eq(catalog.length(), 7)
  assert_eq(catalog[0].width > 0, true)
  assert_eq(catalog[3].supports_stochasticity, true)
  assert_eq(catalog[0].supports_stochasticity, false)
}

///|
test "planner_executes_exactly" {
  for result in execute_all_plans(2026) {
    assert_eq(result.found, true)
  }
}

///|
test "normalization_guards_inputs" {
  assert_eq(normalized_episode_count(-1), 1)
  assert_eq(normalized_episode_count(0), 1)
  assert_eq(normalized_episode_count(3), 3)
  assert_eq(normalized_episode_count(10001), 10000)
  assert_eq(normalized_step_limit(-7), 1)
  assert_eq(normalized_step_limit(64), 64)
  assert_eq(normalized_step_limit(1000001), 1000000)
}

///|
test "release_gate_passes" {
  let gate = release_gate(2026)
  assert_eq(gate.contains("valid=true"), true)
  assert_eq(gate.contains("exact_plans=6/6"), true)
}

///|
test "reports_are_human_readable" {
  assert_eq(benchmark_report(1, 1).contains("episodes=1"), true)
  assert_eq(validation_report(1).contains("failures=0"), true)
  assert_eq(boundary_report(1).contains("stable=true"), true)
  assert_eq(snapshot_report(1).contains("checksum="), true)
  assert_eq(quality_report(1).contains("passed=true"), true)
}

///|
test "stable_tables_are_documented" {
  assert_eq(action_table().length(), 5)
  assert_eq(scenario_table().length(), 7)
  assert_eq(action_table()[0], "0:Up")
  assert_eq(scenario_table()[6], "6:FourRooms")
}
