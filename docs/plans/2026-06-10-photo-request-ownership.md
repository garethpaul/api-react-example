# Photo Request Ownership

Status: Completed

## Context

The component stored its abort controller and timeout in shared instance fields.
React Strict Mode can mount, run cleanup, and mount the same component instance
again during development. A rejection from the first aborted request could then
observe `isActive` restored to true, overwrite the new request's state, clear
the new timeout, and discard the new abort controller.

## Changes

- Give each photo load a request object containing its own abort controller and
  timeout ID.
- Require request identity as well as mounted state before applying results or
  errors.
- Cancel only the active request during unmount or replacement.
- Clear only the completing request's timer and active slot.
- Add a regression test that remounts one component instance, completes the new
  request, then rejects the superseded request and verifies no second state
  update occurs.
- Extend the static baseline and project documentation with request ownership
  contracts.

## Verification

- `make check`
- Mutation checks for removed request identity and shared timeout cleanup
- `corepack yarn lint`
- `corepack yarn format:check`
- `corepack yarn test`
- `corepack yarn build`
- `git diff --check`
