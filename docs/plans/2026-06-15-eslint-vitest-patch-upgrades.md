---
title: Upgrade ESLint and Vitest patch releases
date: 2026-06-15
status: completed
---

# Upgrade ESLint and Vitest Patch Releases

## Context

The runtime dependencies and most development tools are current, but the
registry reports two direct patch releases beyond the checked-in pins:
ESLint 10.5.0 instead of 10.4.1 and Vitest 4.1.9 instead of 4.1.8. The project
uses an exact Yarn Classic lockfile and verifies the same toolchain across Node
20, 22, and 24.

## Priorities

1. **P0 - Reproducible tooling:** update both exact direct pins and regenerate
   `yarn.lock` through the declared Yarn 1.22.22 package manager.
2. **P1 - Compatibility:** prove formatting, lint, all component tests,
   production build, and the portable repository baseline remain green.
3. **P2 - Durable evidence:** enforce the new direct versions and completed
   verification record so package metadata, lockfile, and documentation cannot
   drift independently.

## Scope

- Update `eslint` from 10.4.1 to 10.5.0 and `vitest` from 4.1.8 to 4.1.9 in
  `package.json` and `yarn.lock`.
- Update `scripts/check-baseline.sh` with exact direct-version, lockfile, and
  completed-plan contracts.
- Record the development-tool update in `README.md` and `CHANGES.md`.
- Keep React, Vite, application source, endpoint behavior, workflows, and
  runtime dependencies unchanged.

## Verification

- Confirm the installed binaries report ESLint 10.5.0 and Vitest 4.1.9.
- Run the focused lint and test gates, production build, `yarn verify`, and
  repository-root `make check`.
- Run `make check` through the absolute Makefile path from an
  external working directory.
- Run the production dependency audit and verify no known vulnerabilities.
- Reject isolated hostile mutations of either direct pin, lockfile resolution,
  maintained guidance, and completed-plan evidence.
- Audit the exact diff, generated artifacts, and credential-shaped additions.

## Risks

- Patch releases can introduce new lint diagnostics or test-runner behavior.
  Any incompatibility will be fixed at its source rather than suppressed.
- Registry availability remains external, while exact direct and transitive
  lockfile versions keep successful installations deterministic.

## Work Completed

- Updated the exact ESLint and Vitest direct pins and regenerated the Yarn
  Classic lockfile through Corepack with no runtime dependency changes.
- Added direct-version, lockfile, maintained-documentation, and completed-plan
  contracts to the portable baseline checker.
- Updated the README and changelog with the maintained tool versions.

## Verification Completed

- The installed binaries reported ESLint 10.5.0 and Vitest 4.1.9.
- ESLint passed, all 38 component tests passed, and the Vite production build
  completed successfully on Node 20.19.5.
- Frozen installation, `yarn verify`, repository-root `make check`, and the
  absolute Makefile gate from an external working directory passed.
- The production dependency audit reported zero known vulnerabilities.
- Six isolated hostile mutations of the ESLint pin, Vitest pin, ESLint
  lockfile selector, Vitest transitive selector, README guidance, and completed
  plan status were rejected.
- The exact diff, generated-artifact scan, and credential-shaped additions
  audit passed before commit.
