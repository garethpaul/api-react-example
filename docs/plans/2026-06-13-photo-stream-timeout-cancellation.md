# Cancel Timed-Out Photo Streams

Status: Completed

## Context

The photo request timeout aborts Fetch when `AbortController` exists. In an
environment without abort support, a streamed response can remain blocked in
`reader.read()` after the timeout has already rendered the error state. That
leaves the response reader locked and the transport work pending.

## Requirements

- R1. Associate an acquired photo response reader with the active request.
- R2. Cancel the active reader on timeout and unmount even when
  `AbortController` is unavailable.
- R3. Clear reader ownership when streaming finishes and preserve lock release
  on success, overflow, cancellation, and parse failure.
- R4. Preserve the 2 MiB body limit, strict UTF-8 parsing, declared-length
  checks, content-type validation, and request-identity state guard.
- R5. Add a mutation-sensitive regression for a never-ending stream without
  abort support.

## Implementation Units

### 1. Request-owned reader cancellation

Files:

- `src/components/Photos.jsx`

Register the stream reader's cancellation function with the active request,
invoke it from shared request cancellation, and clear it only if the same
reader still owns the registration.

### 2. Timeout regression and durable contracts

Files:

- `src/App.test.jsx`
- `scripts/check-baseline.sh`

Prove that the no-abort timeout cancels and releases a pending reader, and
protect the source ordering and test with static baseline contracts.

### 3. Guidance and evidence

Files:

- `AGENTS.md`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Document the request-owned stream lifecycle and record completed local and
hosted verification after implementation.

## Verification

Verification: Completed

- Focused Vitest coverage passes the no-abort timeout and unmount stream
  cancellation regressions.
- ESLint, Prettier, all 31 Vitest tests, and the Vite production build pass on
  the pinned Yarn toolchain.
- Eight focused hostile mutations remove timeout or unmount cancellation,
  reader registration, callback forwarding, cancellation invocation, reader
  lock release, the lifecycle regression names, or completed plan status; every
  mutation is rejected.
- Full `make check`, exact-diff inspection, generated artifact review, and
  credential-shaped addition scanning are completed before the implementation
  commit.

## Work Completed

- Registered the acquired response reader's cancellation function with its
  owning photo request.
- Reused request cancellation for timeout and unmount cleanup, independently of
  `AbortController` availability.
- Cleared reader ownership before releasing the lock and preserved all bounded
  byte parsing behavior.
- Added deterministic timeout and unmount regressions for never-ending streams
  without abort support.

## Scope Boundaries

- Do not change the endpoint, timeout duration, response byte limit, accepted
  content types, photo schema, render limit, or thumbnail policy.
- Do not add a dependency or replace Fetch/ReadableStream.
- Do not claim live browser transport coverage.
