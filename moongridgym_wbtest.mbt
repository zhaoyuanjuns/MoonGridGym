///|
test "maze_has_walls_and_goal" {
  let env = new_random_maze(42)
  let rendered = env.reset().ascii
  assert_eq(rendered.contains("RandomMaze"), true)
  assert_eq(rendered.contains("G"), true)
  assert_eq(rendered.contains("#"), true)
  let plan = env.shortest_path()
  assert_eq(plan.found, true)
  assert_eq(plan.steps > 0, true)
}

///|
test "action_catalog_is_stable" {
  assert_eq(available_actions().length(), 5)
  assert_eq(available_scenarios().length(), 7)
}

///|
test "summary_mentions_dimensions" {
  let env = new_grid_world(7)
  let summary = env.summary()
  assert_eq(summary.contains("size=7x7"), true)
  assert_eq(summary.contains("reachable="), true)
}
