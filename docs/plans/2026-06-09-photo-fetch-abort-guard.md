# Photo Fetch Abort Guard

status: completed

## Context

The photo component already ignored late state updates after unmount, but the
underlying request could still continue in browsers that support request
aborting. That leaves unnecessary network work after navigation away from the
sample.

## Plan

- Create an `AbortController` for photo requests when the runtime supports it.
- Pass the controller signal into `fetch`.
- Abort the pending photo request during `componentWillUnmount` while retaining
  the existing mounted-state guard.
- Add React test coverage and SDK-free baseline checks for the abort lifecycle.

## Verification

- `sh scripts/check-baseline.sh`
- `git diff --check`
- `make check`
