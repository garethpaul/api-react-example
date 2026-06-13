# Bound Photo Stream Buffer Overhead

Status: Planned

## Context

The photo reader limits streamed payload bytes to 2 MiB but retains every
received chunk in an array until the stream completes. A highly fragmented
response can therefore create an attacker-controlled number of arrays and
bookkeeping entries while remaining below the byte limit.

## Requirements

- R1. Retain at most one bounded destination byte buffer while reading a photo
  response stream; do not accumulate response chunks in an array.
- R2. Continue accepting valid JSON exactly at the 2 MiB limit and reject the
  first byte beyond it.
- R3. Cancel the reader on overflow and release its lock on success or failure.
- R4. Preserve declared-length checks, fallback `arrayBuffer` handling, strict
  UTF-8 decoding, content-type validation, request timeout, and photo schema
  normalization.
- R5. Add executable coverage for highly fragmented valid streams so the fix
  cannot regress to per-chunk retention.

## Implementation Units

### 1. Contiguous stream accumulation

Files:
- `src/components/Photos.jsx`

Allocate one buffer at the existing maximum, copy each accepted chunk at the
current offset, and parse only the populated view after releasing the reader.

### 2. Fragmentation-sensitive tests

Files:
- `src/App.test.jsx`

Cover a valid response split into many one-byte chunks, exact-limit parsing,
overflow cancellation, and reader-lock cleanup without weakening existing
fallback or malformed-byte tests.

### 3. Durable contracts and guidance

Files:
- `scripts/check-baseline.sh`
- `AGENTS.md`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`

Protect the one-buffer implementation, absence of chunk-array retention,
fragmented-stream test, documentation, and completed plan evidence.

## Verification

- Focused Vitest stream-reader tests.
- Full `corepack yarn verify` on the pinned Node/Yarn toolchain.
- Hostile mutations for chunk-array restoration, per-chunk push, fixed-buffer
  removal, copy-offset drift, populated-view removal, overflow cancellation or
  lock-release removal, fragmented-stream test removal, and stale plan evidence.
- Formatting, lint, build, `git diff --check`, generated-artifact inspection,
  and credential-shaped added-line scanning.
- Exact-head hosted Node matrix and code-scanning snapshot after push.

## Scope Boundaries

- Do not change the 2 MiB limit, endpoint, content types, request timeout, photo
  schema, render limit, or thumbnail policy.
- Do not add a dependency or replace Fetch/ReadableStream.
- Do not claim live endpoint or browser-network fragmentation coverage.
