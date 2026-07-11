# MoonGridGym

MoonGridGym is a lightweight Gym-style environment suite written in MoonBit.
It bundles a small set of classic grid environments behind one consistent API:

- `GridWorld`
- `CliffWalking`
- `Maze`
- `FrozenLakeLike`
- `RandomMaze`

Each environment exposes the same three operations:

- `reset()`
- `step(action)`
- `render()`

The goal is to give MoonBit developers a clean, easy-to-test foundation for
simulation, planning, search, and reinforcement-learning demos.

## Why this is a good OSC2026 topic

- It is useful on its own, not just as a demo.
- It sits in a mature area, so the scope can grow without getting narrow.
- It is small enough to fit the contest's reference code-size range.
- It gives you good README, tests, and example material for review.

## Quick Start

```bash
moon check
moon test
moon run cmd/main
```

## API

Create a scenario with one of the convenience constructors:

- `new_grid_world(seed)`
- `new_cliff_walking(seed)`
- `new_maze(seed)`
- `new_frozen_lake_like(seed)`
- `new_random_maze(seed)`

Then use the same interface everywhere:

```mbt
let env = @moongridgym.new_grid_world(7)
let obs = env.reset()
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
- `CliffWalking` mirrors the classic control task with a harsh failure state.
- `Maze` is a fixed benchmark maze for deterministic examples.
- `FrozenLakeLike` adds slipping behavior and holes.
- `RandomMaze` generates a seeded maze for replayable experiments.

## Repository policy

- MoonBit is the primary implementation language.
- The code in this repository is original and written from scratch.
- No upstream source code is copied into this project.
- If you later port or reference another project, list the upstream source,
  license, and scope of reuse here before submission.

## Contest readiness checklist

- Public repository
- Clear README
- MIT license
- Runnable example
- Automated tests
- GitHub Actions CI
- Mooncakes.io publication before final submission

## Notes for submission

The OSC2026 guide requires the repository to be public, readable, and actively
maintained. It also expects the acceptance materials to show the repository link,
README, CI, tests, and Mooncakes publication.

If you publish this project to GitHub, replace the empty `repository` field in
`moon.mod` with the final URL.
