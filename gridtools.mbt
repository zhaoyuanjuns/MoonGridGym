///|
/// A path plan returned by the built-in grid solver.
pub struct PathPlan {
  found : Bool
  steps : Int
  actions : Array[Action]
}

///|
/// Summary information for a rollout or evaluation run.
pub struct EpisodeStats {
  steps : Int
  reward_sum : Int
  terminated : Bool
  truncated : Bool
  final_render : String
  info : String
}

fn filled_int_board(count : Int, value : Int) -> Array[Int] {
  let board = Array::new(capacity=count)
  for i = 0; i < count; i = i + 1 {
    board.push(value)
  }
  board
}

fn filled_bool_board(count : Int, value : Bool) -> Array[Bool] {
  let board = Array::new(capacity=count)
  for i = 0; i < count; i = i + 1 {
    board.push(value)
  }
  board
}

fn empty_actions(capacity : Int) -> Array[Action] {
  Array::new(capacity=capacity)
}

fn action_to_index(action : Action) -> Int {
  match action {
    Up => 0
    Down => 1
    Left => 2
    Right => 3
    Stay => 4
  }
}

fn action_from_index(code : Int) -> Action {
  match code {
    0 => Up
    1 => Down
    2 => Left
    3 => Right
    _ => Stay
  }
}

fn is_walkable_tile(tile : Int) -> Bool {
  tile != TILE_WALL && tile != TILE_CLIFF && tile != TILE_HOLE
}

fn reverse_actions(actions : Array[Action]) -> Array[Action] {
  let out = Array::new(capacity=actions.length())
  let mut i = actions.length() - 1
  while i >= 0 {
    out.push(actions[i])
    i = i - 1
  }
  out
}

fn grid_plan_from(env : GridGym, start_x : Int, start_y : Int, goal_x : Int, goal_y : Int) -> PathPlan {
  let width = env.width
  let height = env.height
  let total = width * height
  let start = board_index(width, start_x, start_y)
  let goal = board_index(width, goal_x, goal_y)
  let visited = filled_bool_board(total, false)
  let parent = filled_int_board(total, -1)
  let parent_action = filled_int_board(total, -1)
  let queue = Array::new(capacity=total)
  let mut head = 0

  queue.push(start)
  visited[start] = true

  while head < queue.length() {
    let idx = queue[head]
    head = head + 1

    if idx == goal {
      break
    }

    let x = idx % width
    let y = idx / width

    if in_bounds(width, height, x, y - 1) {
      let nidx = board_index(width, x, y - 1)
        if !visited[nidx] && is_walkable_tile(board_get(env.board, width, x, y - 1)) {
        visited[nidx] = true
        parent[nidx] = idx
        parent_action[nidx] = action_to_index(Up)
        queue.push(nidx)
      }
    }

    if in_bounds(width, height, x, y + 1) {
      let nidx = board_index(width, x, y + 1)
        if !visited[nidx] && is_walkable_tile(board_get(env.board, width, x, y + 1)) {
        visited[nidx] = true
        parent[nidx] = idx
        parent_action[nidx] = action_to_index(Down)
        queue.push(nidx)
      }
    }

    if in_bounds(width, height, x - 1, y) {
      let nidx = board_index(width, x - 1, y)
        if !visited[nidx] && is_walkable_tile(board_get(env.board, width, x - 1, y)) {
        visited[nidx] = true
        parent[nidx] = idx
        parent_action[nidx] = action_to_index(Left)
        queue.push(nidx)
      }
    }

    if in_bounds(width, height, x + 1, y) {
      let nidx = board_index(width, x + 1, y)
        if !visited[nidx] && is_walkable_tile(board_get(env.board, width, x + 1, y)) {
        visited[nidx] = true
        parent[nidx] = idx
        parent_action[nidx] = action_to_index(Right)
        queue.push(nidx)
      }
    }
  }

  if !visited[goal] {
    PathPlan::{
      found: false,
      steps: 0,
      actions: empty_actions(0),
    }
  } else {
    let reversed = empty_actions(total)
    let mut cur = goal
    while cur != start {
      let code = parent_action[cur]
      reversed.push(action_from_index(code))
      cur = parent[cur]
    }
    let actions = reverse_actions(reversed)
    PathPlan::{
      found: true,
      steps: actions.length(),
      actions,
    }
  }
}

///|
pub fn GridGym::shortest_path(self : GridGym) -> PathPlan {
  grid_plan_from(self, self.agent_x, self.agent_y, self.goal_x, self.goal_y)
}

///|
pub fn GridGym::reachable_cells(self : GridGym) -> Int {
  let width = self.width
  let height = self.height
  let total = width * height
  let start = board_index(width, self.agent_x, self.agent_y)
  let visited = filled_bool_board(total, false)
  let queue = Array::new(capacity=total)
  let mut head = 0
  let mut count = 0

  queue.push(start)
  visited[start] = true

  while head < queue.length() {
    let idx = queue[head]
    head = head + 1
    count = count + 1

    let x = idx % width
    let y = idx / width

    if in_bounds(width, height, x, y - 1) {
      let nidx = board_index(width, x, y - 1)
      if !visited[nidx] && is_walkable_tile(board_get(self.board, width, x, y - 1)) {
        visited[nidx] = true
        queue.push(nidx)
      }
    }

    if in_bounds(width, height, x, y + 1) {
      let nidx = board_index(width, x, y + 1)
      if !visited[nidx] && is_walkable_tile(board_get(self.board, width, x, y + 1)) {
        visited[nidx] = true
        queue.push(nidx)
      }
    }

    if in_bounds(width, height, x - 1, y) {
      let nidx = board_index(width, x - 1, y)
      if !visited[nidx] && is_walkable_tile(board_get(self.board, width, x - 1, y)) {
        visited[nidx] = true
        queue.push(nidx)
      }
    }

    if in_bounds(width, height, x + 1, y) {
      let nidx = board_index(width, x + 1, y)
      if !visited[nidx] && is_walkable_tile(board_get(self.board, width, x + 1, y)) {
        visited[nidx] = true
        queue.push(nidx)
      }
    }
  }

  count
}

///|
pub fn GridGym::route_string(self : GridGym) -> String {
  let plan = self.shortest_path()
  if !plan.found {
    "no path"
  } else {
    let builder = StringBuilder::new()
    let mut first = true
    for action in plan.actions {
      if !first {
        builder.write_string(" -> ")
      } else {
        first = false
      }
      match action {
        Up => builder.write_string("Up")
        Down => builder.write_string("Down")
        Left => builder.write_string("Left")
        Right => builder.write_string("Right")
        Stay => builder.write_string("Stay")
      }
    }
    builder.to_string()
  }
}

///|
pub fn GridGym::rollout(self : GridGym, actions : Array[Action]) -> EpisodeStats {
  let mut steps = 0
  let mut reward_sum = 0
  let mut terminated = false
  let mut truncated = false
  let mut last_info = "no actions"

  for action in actions {
    let result = self.step(action)
    steps = steps + 1
    reward_sum = reward_sum + result.reward
    terminated = result.terminated
    truncated = result.truncated
    last_info = result.info
    if terminated || truncated {
      break
    }
  }

  EpisodeStats::{
    steps,
    reward_sum,
    terminated,
    truncated,
    final_render: self.render(),
    info: last_info,
  }
}

///|
pub fn GridGym::auto_solve(self : GridGym) -> EpisodeStats {
  let plan = self.shortest_path()
  if plan.found {
    self.rollout(plan.actions)
  } else {
    EpisodeStats::{
      steps: 0,
      reward_sum: 0,
      terminated: false,
      truncated: false,
      final_render: self.render(),
      info: "no path",
    }
  }
}
