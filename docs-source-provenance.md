# Source Provenance

MoonGridGym is an original MoonBit implementation created for OSC2026 track 1.

## What is included

- Core grid environments
- Uniform `reset / step / render` API
- Seeded maze generation
- BFS shortest-path solver
- Rollout and auto-solve helpers

## What is not included

- No upstream code is copied into this repository.
- No third-party environment implementation is vendored here.
- No generated contributor is used as a fake author or maintainer.

## Maintenance note

The repository remains dependency-free and readable, while now including a
maintained benchmark harness, replay checks, numeric observation encoding,
offline trajectory export, policy comparisons, and executable acceptance
contracts. These are original MoonBit implementations, not copied line-count
fillers.
