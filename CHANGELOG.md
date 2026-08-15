# Changelog

## 0.1.1 - 2026-08-15

- Corrected the registry namespace to `zhaoyuanjuns/moongridgym`.
- Fixed the acceptance release metadata and documented the verified package
  namespace.

## 2026-08-15

- Aligned the MoonBit registry module name with the authenticated project
  account: `zhaoyuanjuns/moongridgym`.
- Fixed CliffWalking goal rewards so safe arrival is positive while cliff
  failure remains `-100`.
- Added regression coverage for goal rewards, hazards, seeded slipping,
  truncation, and deterministic reset behavior.
- Documented source acquisition and `moon add` usage in the README.

## 2026-07-12

- Reworked MoonGridGym into a contest-ready MoonBit environment suite.
- Added fixed environments, seeded random maze generation, BFS planning, and rollout helpers.
- Standardized the project layout for MoonBit tooling, tests, and CI.

## 2026-07-11

- Initial MoonGridGym implementation.
- Added the core grid environments, render/reset/step API, and contest-friendly documentation.
