# MoonGridGym

MoonGridGym is a lightweight Gym-style environment suite written in MoonBit.
It bundles a small set of classic grid environments behind one consistent API:

- `GridWorld`
- `CliffWalking`
- `Maze`
- `FrozenLakeLike`
- `RandomMaze`
- `EmptyRoom`
- `FourRooms`

Each environment exposes the same three operations:

- `reset()`
- `step(action)`
- `render()`

The suite also ships with a built-in shortest-path solver and rollout helpers
for quick demos and evaluation.

The goal is to provide a reusable, deterministic foundation for simulation,
planning, search, offline trajectory collection, and reinforcement-learning
experiments—not a one-off visual demo.

## Why this is a good OSC2026 topic

- It is useful on its own, not just as a demo.
- It sits in a mature area, so the scope can grow without getting narrow.
- It includes executable benchmark, validation, replay, and dataset tooling.
- It has fixed and seeded scenarios so results can be reproduced in CI.
- It exposes numeric observation encoding for downstream agents.

## Quick Start

Requires MoonBit Toolchain v0.10.3 or later.

To obtain the source and run the project locally:

```bash
git clone https://github.com/zhaoyuanjuns/MoonGridGym.git
cd MoonGridGym
moon check
moon test
moon run cmd/main
```

To use the published module from another MoonBit project after the release is
available:

```bash
moon add zhaoyuanjuns/moongridgym
```

The module name above matches the authenticated MoonBit account and the GitHub
repository owner: `zhaoyuanjuns/moongridgym`.

```bash
moon check
moon test
moon run cmd/main
```

For the strict local gate, also run:

```bash
moon fmt --check
moon info
moon check --deny-warn
moon test --deny-warn
```

## API

Create a scenario with one of the convenience constructors:

- `new_grid_world(seed)`
- `new_cliff_walking(seed)`
- `new_maze(seed)`
- `new_frozen_lake_like(seed)`
- `new_random_maze(seed)`
- `new_empty_room(seed)`
- `new_four_rooms(seed)`

Then use the same interface everywhere:

```mbt
let env = @moongridgym.new_grid_world(7)
let obs = env.reset()
println(env.summary())
println(obs.ascii)
let result = env.step(@moongridgym.Action::Right)
println(result.info)
println(result.observation.ascii)
```

### Actions

- `Up`
- `Down`
- `Left`
- `Right`
- `Stay`

### Scenarios

- `GridWorld` focuses on pathfinding with a simple obstacle layout.
- `CliffWalking` mirrors the classic control task with a harsh failure state
  and a positive terminal reward when the goal is reached safely.
- `Maze` is a fixed benchmark maze for deterministic examples.
- `FrozenLakeLike` adds slipping behavior and holes.
- `RandomMaze` generates a seeded maze for replayable experiments.
- `EmptyRoom` is a completely empty 7x7 room, ideal for basic random-walk agents.
- `FourRooms` is the classic Sutton's 4-rooms environment for hierarchical RL tests.

### Solver Helpers

- `shortest_path()` returns a BFS plan from the current agent position.
- `route_string()` formats that plan as a readable action sequence.
- `rollout(actions)` runs a batch of actions and summarizes the episode.
- `auto_solve()` runs the shortest-path plan when one exists.

### Evaluation and data helpers

- `benchmark(seed, episodes)` evaluates planner, greedy, and seeded-random
  policies across all seven scenarios.
- `validate_all(seed)` checks reset determinism, reachability, and solvability.
- `collect_episode(...)` returns replayable transitions and `to_csv()` exports
  an offline-RL-friendly dataset without external dependencies.
- `encode()` provides a numeric board representation and checksum.
- `action_checks()` and `legal_actions()` expose boundary and hazard behavior.
- `replay_check(...)` detects hidden-state or random-seed regressions.
- `quality_report`, `contracts_report`, and `release_gate` produce CI-friendly
  acceptance evidence.

The command-line example prints a scenario summary, a route, a reference
rollout, and the local release gate. The library itself remains dependency
free and can be embedded in another MoonBit package.

## Reproducible benchmark

```mbt
let rows = @moongridgym.benchmark(2026, 5)
let report = @moongridgym.benchmark_report(2026, 5)
let data = @moongridgym.collect_episode(
  @moongridgym.ScenarioKind::RandomMaze,
  2026,
  @moongridgym.PolicyKind::ShortestPath,
  512,
)
println(data.summary())
println(data.to_csv())
```

The seed is part of every benchmark and dataset record. `RandomMaze` is
generated from the seed, while `FrozenLakeLike` uses the seed for its slip
sequence. A repeated seed and action sequence must produce identical replay
results; this is covered by the test suite.

## Project boundaries

In scope: discrete 2-D grid environments, deterministic and seeded stochastic
transitions, rendering, shortest-path planning, baseline policy evaluation,
trajectory capture, numeric encoding, and validation utilities.

Out of scope: neural-network training, external simulators, network services,
and a claim of Gymnasium API binary compatibility. These boundaries keep the
package portable while leaving clear extension points for future MoonBit
agents.

## Current engineering evidence

- MoonBit is the primary implementation language.
- The repository contains more than 3,000 lines of maintained `.mbt` source
  and tests, including the environment core, planning, benchmark harness,
  dataset export, replay checks, and acceptance contracts.
- Seven scenarios, four policy families, seeded benchmark runs, boundary
  checks, deterministic replay checks, and 36 automated tests are included.
- CI runs formatting, package info, warning-denied checks, tests, and the
  runnable example.

## Repository policy

- MoonBit is the primary implementation language.
- The code in this repository is original and written from scratch.
- No upstream source code is copied into this project.
- If you later port or reference another project, list the upstream source,
  license, and scope of reuse here before submission.

## Official Mirrors

- GitLink: [https://gitlink.org.cn/zyjzyj78/MoonGridGym](https://gitlink.org.cn/zyjzyj78/MoonGridGym)
- GitHub: [https://github.com/zhaoyuanjuns/MoonGridGym](https://github.com/zhaoyuanjuns/MoonGridGym)

## Contribution Rules

- The default branch is `master`.
- The commit history is authored by a single contributor account.
- No virtual or secondary contributors are included.

## Contest readiness checklist

- Public repository
- Clear README
- MIT license
- Runnable example
- Automated tests
- GitHub Actions CI
- Mooncakes.io publication before final submission

## Mooncakes.io release checklist

Publishing is intentionally not performed by local development commands. After
the repository owner authorizes the external release, verify the default
branch, confirm the final GitHub/GitLink mirrors contain the same commit, and
then publish the module named `zhaoyuanjuns/moongridgym` from `moon.mod`.
The acceptance package should retain the published version, package page, and
the exact commit used for publication as evidence.

## Notes for submission

The OSC2026 guide requires the repository to be public, readable, and actively
maintained. It also expects the acceptance materials to show the repository link,
README, CI, tests, and Mooncakes publication.

The `repository` field in `moon.mod` is already set to the GitHub project URL.
Do not publish to GitHub, GitLink, or Mooncakes.io from an unreviewed local
working tree.
