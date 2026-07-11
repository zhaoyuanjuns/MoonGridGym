///|
/// A tiny showcase that exercises one environment end to end.
fn main {
  let env = @gym.new_random_maze(2026)
  let _ = env.reset()
  println(env.render())
  let step1 = env.step(@gym.Action::Right)
  println(step1.info)
  println(step1.observation.ascii)
}
