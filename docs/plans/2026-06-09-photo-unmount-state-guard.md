# Photo Unmount State Guard

Status: Completed
Date: 2026-06-09

## Goal

Prevent pending API photo loads from updating component state after the
`Photos` component unmounts.

## Changes

- Tracked whether the `Photos` component is still active after mount.
- Routed async photo load state changes through a helper that checks active
  component state before calling `setState`.
- Added Jest coverage for unmounting while the API JSON payload is still
  pending.
- Added SDK-free source-baseline coverage for the unmount guard.

## Verification

- `make check`
- `corepack yarn lint`
- `CI=true corepack yarn test --watchAll=false`
- `corepack yarn build`
- `git diff --check`
