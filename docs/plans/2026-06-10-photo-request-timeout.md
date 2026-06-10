# Photo Request Timeout

Status: Completed

## Goal

Prevent a stalled photo endpoint from leaving the sample in its loading state
indefinitely while preserving the existing unmount and user-visible error
behavior.

## Requirements

- Bound each photo request to 10 seconds.
- Start the full fetch, status, and JSON parsing operation concurrently with the
  deadline.
- Abort the request at the deadline when `AbortController` is available.
- Reject into the existing generic photo error state even without abort support.
- Clear the timer after success, failure, or unmount.
- Keep unmounted components from receiving late state updates.
- Cover timeout abort and error rendering with deterministic fake timers.
- Keep root and hosted verification location- and runner-stable.

## Implementation

- Added `PHOTO_REQUEST_TIMEOUT_MS` and raced the complete fetch/parse operation
  against a timeout promise.
- Reused the active abort controller at the deadline.
- Added centralized timeout cleanup to completion and unmount paths.
- Added Vitest fake-timer regressions for abort/error rendering and stalled JSON
  parsing without abort support.
- Rooted Makefile commands at the repository and pinned hosted verification to
  Ubuntu 24.04 with superseded-run cancellation.

## Verification

- `make check`
- `make -f /absolute/path/to/Makefile check` from outside the repository
- timeout, cleanup, Makefile, and CI mutation checks
- `corepack yarn lint`
- `corepack yarn format:check`
- `corepack yarn test`
- `corepack yarn build`
- `git diff --check`

Verification completed on Node 20.19.5 with ESLint and Prettier clean, 17
Vitest tests passing, and a successful Vite production build.
