# Cancel Timed-Out Photo Streams

Status: In Progress

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

Verification: Pending

- Run focused Vitest coverage for the no-abort streamed timeout.
- Run the complete pinned `make check` gate with an explicit timeout.
- Run focused hostile mutations against reader registration, timeout
  cancellation, ownership cleanup, regression coverage, and plan status.
- Inspect the exact diff, generated artifacts, and credential-shaped additions.

## Scope Boundaries

- Do not change the endpoint, timeout duration, response byte limit, accepted
  content types, photo schema, render limit, or thumbnail policy.
- Do not add a dependency or replace Fetch/ReadableStream.
- Do not claim live browser transport coverage.
