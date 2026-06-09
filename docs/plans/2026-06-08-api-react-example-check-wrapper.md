# API React Example Check Wrapper

## Status: Completed

## Goal

Expose the React sample's source baseline, lint, tests, and production build
through the shared root `make check` command.

## Scope

- Preserve the existing Corepack-backed Yarn v1 workflow.
- Keep `scripts/check-baseline.sh` as the first lint-stage guard.
- Keep the CI test command non-watchable.
- Avoid changing React runtime behavior.

## Verification

- `make check`
- `git diff --check`
