///|
/// Actions shared by every environment.
pub(all) enum Action {
  Up
  Down
  Left
  Right
  Stay
}

///|
/// The bundled scenario kinds.
pub(all) enum ScenarioKind {
  GridWorld
  CliffWalking
  Maze
  FrozenLakeLike
  RandomMaze
  EmptyRoom
  FourRooms
}

///|
pub struct Observation {
  kind : String
  ascii : String
  agent_x : Int
  agent_y : Int
  step_count : Int
  done : Bool
}

///|
pub struct StepResult {
  observation : Observation
  reward : Int
  terminated : Bool
  truncated : Bool
  info : String
}

///|
pub struct GridGym {
  kind : ScenarioKind
  initial_seed : Int
  mut seed : Int
  width : Int
  height : Int
  start_x : Int
  start_y : Int
  goal_x : Int
  goal_y : Int
  mut agent_x : Int
  mut agent_y : Int
  mut step_count : Int
  step_limit : Int
  mut done : Bool
  board : Array[Int]
}

///|
priv struct Layout {
  width : Int
  height : Int
  start_x : Int
  start_y : Int
  goal_x : Int
  goal_y : Int
  board : Array[Int]
}

///|
const TILE_EMPTY = 0

///|
const TILE_WALL = 1

///|
const TILE_CLIFF = 2

///|
const TILE_HOLE = 3

///|
fn board_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

///|
fn in_bounds(width : Int, height : Int, x : Int, y : Int) -> Bool {
  x >= 0 && y >= 0 && x < width && y < height
}

///|
fn board_get(board : Array[Int], width : Int, x : Int, y : Int) -> Int {
  board[board_index(width, x, y)]
}

///|
fn board_set(
  board : Array[Int],
  width : Int,
  x : Int,
  y : Int,
  tile : Int,
) -> Unit {
  board[board_index(width, x, y)] = tile
}

///|
fn filled_board(width : Int, height : Int, tile : Int) -> Array[Int] {
  let board = Array::new(capacity=width * height)
  for i = 0; i < width * height; i = i + 1 {
    board.push(tile)
  }
  board
}

///|
fn next_rand(seed : Int) -> (Int, Int) {
  let next = (seed * 1103 + 12345) % 1_000_003
  let fixed = if next < 0 { next + 1_000_003 } else { next }
  (fixed, fixed)
}

///|
fn rand_below(seed : Int, upper : Int) -> (Int, Int) {
  let (new_seed, value) = next_rand(seed)
  (new_seed, value % upper)
}

///|
fn action_delta(action : Action) -> (Int, Int) {
  match action {
    Up => (0, -1)
    Down => (0, 1)
    Left => (-1, 0)
    Right => (1, 0)
    Stay => (0, 0)
  }
}

///|
fn turn_left(action : Action) -> Action {
  match action {
    Up => Left
    Left => Down
    Down => Right
    Right => Up
    Stay => Stay
  }
}

///|
fn turn_right(action : Action) -> Action {
  match action {
    Up => Right
    Right => Down
    Down => Left
    Left => Up
    Stay => Stay
  }
}

///|
fn kind_name(kind : ScenarioKind) -> String {
  match kind {
    GridWorld => "GridWorld"
    CliffWalking => "CliffWalking"
    Maze => "Maze"
    FrozenLakeLike => "FrozenLakeLike"
    RandomMaze => "RandomMaze"
    EmptyRoom => "EmptyRoom"
    FourRooms => "FourRooms"
  }
}

///|
fn tile_char(tile : Int) -> Char {
  match tile {
    TILE_WALL => '#'
    TILE_CLIFF => 'X'
    TILE_HOLE => '~'
    _ => '.'
  }
}

///|
fn reward_for_goal(kind : ScenarioKind) -> Int {
  match kind {
    GridWorld => 12
    CliffWalking => -100
    Maze => 25
    FrozenLakeLike => 20
    RandomMaze => 25
    EmptyRoom => 10
    FourRooms => 30
  }
}

///|
fn layout_from_ascii(lines : Array[String]) -> Layout {
  let height = lines.length()
  let width = lines[0].length()
  let board = filled_board(width, height, TILE_EMPTY)
  let mut start_x = 0
  let mut start_y = 0
  let mut goal_x = width - 1
  let mut goal_y = height - 1

  for y = 0; y < height; y = y + 1 {
    let line = lines[y]
    for x = 0; x < width; x = x + 1 {
      let ch = line.code_unit_at(x).to_char()
      match ch {
        Some('#') => board_set(board, width, x, y, TILE_WALL)
        Some('X') => board_set(board, width, x, y, TILE_CLIFF)
        Some('H') => board_set(board, width, x, y, TILE_HOLE)
        Some('S') => {
          start_x = x
          start_y = y
        }
        Some('G') => {
          goal_x = x
          goal_y = y
        }
        _ => ()
      }
    }
  }

  Layout::{ width, height, start_x, start_y, goal_x, goal_y, board }
}

///|
fn make_env_from_layout(
  kind : ScenarioKind,
  seed : Int,
  layout : Layout,
  step_limit : Int,
) -> GridGym {
  GridGym::{
    kind,
    initial_seed: seed,
    seed,
    width: layout.width,
    height: layout.height,
    start_x: layout.start_x,
    start_y: layout.start_y,
    goal_x: layout.goal_x,
    goal_y: layout.goal_y,
    agent_x: layout.start_x,
    agent_y: layout.start_y,
    step_count: 0,
    step_limit,
    done: false,
    board: layout.board,
  }
}

///|
fn make_grid_world(seed : Int) -> GridGym {
  let layout = layout_from_ascii([
    "#######", "#S....#", "#..#..#", "#.....#", "#..#..#", "#....G#", "#######",
  ])
  make_env_from_layout(GridWorld, seed, layout, 48)
}

///|
fn make_cliff_walking(seed : Int) -> GridGym {
  let layout = layout_from_ascii([
    "............", "............", "............", "SXXXXXXXXXXG",
  ])
  make_env_from_layout(CliffWalking, seed, layout, 120)
}

///|
fn make_frozen_lake_like(seed : Int) -> GridGym {
  let layout = layout_from_ascii([
    "S.....", ".H..H.", "..H...", ".H.H..", "...H..", ".....G",
  ])
  make_env_from_layout(FrozenLakeLike, seed, layout, 72)
}

///|
fn make_empty_room(seed : Int) -> GridGym {
  let layout = layout_from_ascii([
    "#######", "#S....#", "#.....#", "#.....#", "#.....#", "#....G#", "#######",
  ])
  make_env_from_layout(EmptyRoom, seed, layout, 48)
}

///|
fn make_four_rooms(seed : Int) -> GridGym {
  let layout = layout_from_ascii([
    "###########", "#S...#....#", "#....#....#", "#....#....#", "#....#....#", "##.#####.##",
    "#.........#", "#....#....#", "#....#....#", "#....#...G#", "###########",
  ])
  make_env_from_layout(FourRooms, seed, layout, 120)
}

///|
fn carve_maze(
  seed : Int,
  width : Int,
  height : Int,
) -> (Array[Int], Int, Int, Int, Int, Int) {
  let board = filled_board(width, height, TILE_WALL)
  let start_x = 1
  let start_y = 1
  let goal_x = width - 2
  let goal_y = height - 2
  let mut cur_seed = seed % 1_000_003
  for x = start_x; x <= goal_x; x = x + 1 {
    board_set(board, width, x, start_y, TILE_EMPTY)
  }

  for y = start_y; y <= goal_y; y = y + 1 {
    board_set(board, width, goal_x, y, TILE_EMPTY)
  }

  for x = start_x + 1; x < goal_x; x = x + 1 {
    let (next_seed, roll) = rand_below(cur_seed, 4)
    cur_seed = next_seed
    if roll <= 1 && start_y + 1 < goal_y {
      board_set(board, width, x, start_y + 1, TILE_EMPTY)
      if roll == 1 && start_y + 2 < goal_y {
        board_set(board, width, x, start_y + 2, TILE_EMPTY)
      }
    }
  }

  for y = start_y + 1; y < goal_y; y = y + 1 {
    let (next_seed, roll) = rand_below(cur_seed, 4)
    cur_seed = next_seed
    if roll <= 1 && goal_x - 1 > start_x {
      board_set(board, width, goal_x - 1, y, TILE_EMPTY)
      if roll == 1 && goal_x - 2 > start_x {
        board_set(board, width, goal_x - 2, y, TILE_EMPTY)
      }
    }
  }

  board_set(board, width, start_x, start_y, TILE_EMPTY)
  board_set(board, width, goal_x, goal_y, TILE_EMPTY)

  (board, width, height, start_x, start_y, goal_x)
}

///|
fn make_maze_like(
  seed : Int,
  width : Int,
  height : Int,
  kind : ScenarioKind,
) -> GridGym {
  let (board, board_w, board_h, start_x, start_y, goal_x) = carve_maze(
    seed, width, height,
  )
  GridGym::{
    kind,
    initial_seed: seed,
    seed,
    width: board_w,
    height: board_h,
    start_x,
    start_y,
    goal_x,
    goal_y: board_h - 2,
    agent_x: start_x,
    agent_y: start_y,
    step_count: 0,
    step_limit: board_w * board_h * 4,
    done: false,
    board,
  }
}

///|
pub fn new(kind : ScenarioKind, seed : Int) -> GridGym {
  match kind {
    GridWorld => make_grid_world(seed)
    CliffWalking => make_cliff_walking(seed)
    Maze => make_maze_like(11, 11, 11, Maze)
    FrozenLakeLike => make_frozen_lake_like(seed)
    RandomMaze => make_maze_like(seed, 13, 13, RandomMaze)
    EmptyRoom => make_empty_room(seed)
    FourRooms => make_four_rooms(seed)
  }
}

///|
pub fn new_grid_world(seed : Int) -> GridGym {
  make_grid_world(seed)
}

///|
pub fn new_cliff_walking(seed : Int) -> GridGym {
  make_cliff_walking(seed)
}

///|
pub fn new_maze(seed : Int) -> GridGym {
  make_maze_like(seed, 11, 11, Maze)
}

///|
pub fn new_frozen_lake_like(seed : Int) -> GridGym {
  make_frozen_lake_like(seed)
}

///|
pub fn new_random_maze(seed : Int) -> GridGym {
  make_maze_like(seed, 13, 13, RandomMaze)
}

///|
pub fn new_empty_room(seed : Int) -> GridGym {
  make_empty_room(seed)
}

///|
pub fn new_four_rooms(seed : Int) -> GridGym {
  make_four_rooms(seed)
}

///|
fn GridGym::render_cell(self : GridGym, x : Int, y : Int) -> Char {
  if x == self.agent_x && y == self.agent_y {
    '@'
  } else if x == self.start_x && y == self.start_y {
    'S'
  } else if x == self.goal_x && y == self.goal_y {
    'G'
  } else {
    tile_char(board_get(self.board, self.width, x, y))
  }
}

///|
pub fn GridGym::render(self : GridGym) -> String {
  let builder = StringBuilder::new()
  builder.write_string(kind_name(self.kind))
  builder.write_string(" | step=")
  builder.write_object(self.step_count)
  builder.write_string(" | done=")
  builder.write_object(self.done)
  builder.write_char('\n')

  for y = 0; y < self.height; y = y + 1 {
    for x = 0; x < self.width; x = x + 1 {
      builder.write_char(self.render_cell(x, y))
    }
    if y + 1 < self.height {
      builder.write_char('\n')
    }
  }

  builder.to_string()
}

///|
fn GridGym::observation(self : GridGym) -> Observation {
  Observation::{
    kind: kind_name(self.kind),
    ascii: self.render(),
    agent_x: self.agent_x,
    agent_y: self.agent_y,
    step_count: self.step_count,
    done: self.done,
  }
}

///|
pub fn GridGym::reset(self : GridGym) -> Observation {
  self.seed = self.initial_seed
  self.agent_x = self.start_x
  self.agent_y = self.start_y
  self.step_count = 0
  self.done = false
  self.observation()
}

///|
fn GridGym::resolve_action(self : GridGym, action : Action) -> Action {
  match self.kind {
    FrozenLakeLike => {
      let (next_seed, roll) = rand_below(self.seed, 4)
      self.seed = next_seed
      match roll {
        0 => Stay
        1 => turn_left(action)
        2 => turn_right(action)
        _ => action
      }
    }
    _ => action
  }
}

///|
pub fn GridGym::step(self : GridGym, action : Action) -> StepResult {
  if self.done {
    StepResult::{
      observation: self.observation(),
      reward: 0,
      terminated: true,
      truncated: false,
      info: "episode already finished",
    }
  } else {
    let chosen_action = self.resolve_action(action)
    let (dx, dy) = action_delta(chosen_action)
    let mut next_x = self.agent_x + dx
    let mut next_y = self.agent_y + dy
    let mut reward = -1
    let mut terminated = false
    let mut truncated = false
    let mut info = "moved"

    if !in_bounds(self.width, self.height, next_x, next_y) {
      next_x = self.agent_x
      next_y = self.agent_y
      info = "hit boundary"
    } else {
      let tile = board_get(self.board, self.width, next_x, next_y)
      if tile == TILE_WALL {
        next_x = self.agent_x
        next_y = self.agent_y
        info = "hit wall"
      } else if tile == TILE_CLIFF {
        reward = -100
        terminated = true
        info = "fell into cliff"
      } else if tile == TILE_HOLE {
        reward = -50
        terminated = true
        info = "fell into hole"
      } else if next_x == self.goal_x && next_y == self.goal_y {
        reward = reward_for_goal(self.kind)
        terminated = true
        info = "goal reached"
      }
    }

    self.agent_x = next_x
    self.agent_y = next_y
    self.step_count = self.step_count + 1

    if self.step_count >= self.step_limit && !terminated {
      truncated = true
      self.done = true
      info = "step limit reached"
    }

    if terminated {
      self.done = true
    }

    StepResult::{
      observation: self.observation(),
      reward,
      terminated,
      truncated,
      info,
    }
  }
}

///|
pub fn available_actions() -> Array[String] {
  ["Up", "Down", "Left", "Right", "Stay"]
}

///|
pub fn available_scenarios() -> Array[String] {
  [
    "GridWorld", "CliffWalking", "Maze", "FrozenLakeLike", "RandomMaze", "EmptyRoom",
    "FourRooms",
  ]
}
