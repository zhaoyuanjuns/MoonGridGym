///|
/// A tiny showcase that exercises one environment end to end.
fn main {
  let env = @gym.new_random_maze(2026)
  let _ = env.reset()
  println(env.summary())
  println(env.render())
  let plan = env.shortest_path()
  println(plan.steps)
  println(env.route_string())
  let step1 = env.step(@gym.Action::Right)
  println(step1.info)
  println(step1.observation.ascii)
  let stats = env.auto_solve()
  println(stats.info)
  println(stats.final_render)
}
