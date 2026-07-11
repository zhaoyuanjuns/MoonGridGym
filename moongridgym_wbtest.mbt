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
  assert_eq(available_scenarios().length(), 5)
}
