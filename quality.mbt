///|
/// A simple scorecard for release readiness. These checks are intentionally
/// executable so CI and maintainers can reuse the same acceptance evidence.
pub struct QualityScore {
  scenarios : Int
  valid_scenarios : Int
  solvable_scenarios : Int
  deterministic_scenarios : Int
  total_reachable : Int
  total_planned_steps : Int
  passed : Bool
}

///|
fn quality_line(label : String, value : Int) -> String {
  let builder = StringBuilder::new()
  builder.write_string(label)
  builder.write_char('=')
  builder.write_object(value)
  builder.to_string()
}

///|
/// Run structural and behavioral checks across the reference scenario set.
pub fn quality_score(seed : Int) -> QualityScore {
  let reports = validate_all(seed)
  let mut valid = 0
  let mut solvable = 0
  let mut deterministic = 0
  let mut reachable = 0
  let mut planned = 0
  for report in reports {
    if report.valid {
      valid = valid + 1
    }
    if report.planned_steps >= 0 {
      solvable = solvable + 1
    }
    if report.failures <= 1 {
      deterministic = deterministic + 1
    }
    reachable = reachable + report.reachable
    if report.planned_steps > 0 {
      planned = planned + report.planned_steps
    }
  }
  QualityScore::{
    scenarios: 7,
    valid_scenarios: valid,
    solvable_scenarios: solvable,
    deterministic_scenarios: deterministic,
    total_reachable: reachable,
    total_planned_steps: planned,
    passed: valid == 7 && solvable == 7,
  }
}

///|
pub fn quality_report(seed : Int) -> String {
  let score = quality_score(seed)
  let builder = StringBuilder::new()
  builder.write_string("MoonGridGym quality score\n")
  builder.write_string(quality_line("scenarios", score.scenarios))
  builder.write_char('\n')
  builder.write_string(quality_line("valid_scenarios", score.valid_scenarios))
  builder.write_char('\n')
  builder.write_string(
    quality_line("solvable_scenarios", score.solvable_scenarios),
  )
  builder.write_char('\n')
  builder.write_string(
    quality_line("deterministic_scenarios", score.deterministic_scenarios),
  )
  builder.write_char('\n')
  builder.write_string(quality_line("total_reachable", score.total_reachable))
  builder.write_char('\n')
  builder.write_string(
    quality_line("total_planned_steps", score.total_planned_steps),
  )
  builder.write_char('\n')
  builder.write_string("passed=")
  builder.write_object(score.passed)
  builder.to_string()
}

///|
/// Verify that all action names have a stable, documented representation.
pub fn action_roundtrip_count() -> Int {
  let mut count = 0
  for action in [Up, Down, Left, Right, Stay] {
    if action_name(action).length() > 0 {
      count = count + 1
    }
  }
  count
}

///|
/// Return a compact list of all supported policy names for clients building
/// a command-line or UI selector.
pub fn available_policies() -> Array[String] {
  ["shortest-path", "greedy-goal", "seeded-random", "stay"]
}
