---
title: Photo Response Body Limit
type: security
status: completed
date: 2026-06-13
---

# Photo Response Body Limit

## Status: Completed

## Priority

The gallery validates HTTP status, JSON media type, record shape, and a
12-photo render limit, but `response.json()` still buffers and parses the
entire response first. A compromised or malfunctioning endpoint can therefore
consume excessive browser memory and CPU before any application limit applies.

The live JSONPlaceholder `/photos` response measured 1,071,472 bytes on
2026-06-13. A 2 MiB response ceiling preserves the current sample with useful
headroom while establishing a deterministic resource boundary.

## Requirements

- **R1:** Reject declared or streamed photo response bodies larger than
  2,097,152 bytes before JSON parsing completes.
- **R2:** Count raw bytes, not JavaScript string code units, and decode JSON as
  strict UTF-8 without replacement.
- **R3:** Cancel an active response reader when the limit is crossed and always
  release its lock.
- **R4:** Support environments without a readable response stream through a
  bounded `response.arrayBuffer()` fallback.
- **R5:** Preserve request timeout/abort ownership, content-type validation,
  photo normalization, the 12-photo display cap, and the generic error UI.
- **R6:** Add focused tests, fail-closed checker contracts, documentation,
  hostile mutation coverage, and truthful hosted evidence.

## Implementation Units

### U1: Read JSON Through A Byte Ceiling

**File:** `src/components/Photos.jsx`

Add a 2 MiB constant and a response reader that first rejects an oversized
valid `Content-Length`. When `response.body.getReader()` is available, consume
chunks while tracking `Uint8Array.byteLength`, cancel on overflow, decode with a
fatal UTF-8 `TextDecoder`, and parse only after the stream ends. Otherwise read
an `ArrayBuffer`, enforce its authoritative byte length, and use the same strict
decoder before parsing. A text fallback is intentionally excluded because
replacement decoding could already have hidden malformed bytes.

### U2: Cover Streaming And Fallback Boundaries

**File:** `src/App.test.jsx`

Update successful response fixtures to exercise the array-buffer fallback. Add focused
tests for a declared oversized body, streamed overflow and cancellation,
fallback overflow, malformed UTF-8, and an accepted body exactly at the byte
limit. Preserve existing timeout, content-type, normalization, and rendering
tests.

### U3: Protect The Contract

**File:** `scripts/check-baseline.sh`

Require the exact byte limit, status/content-type/read ordering, stream
cancellation and lock release, fatal UTF-8 decoding, fallback byte counting,
named tests, documentation, and completed plan evidence.

### U4: Document The Boundary

**Files:**

- `AGENTS.md`
- `README.md`
- `SECURITY.md`
- `VISION.md`
- `CHANGES.md`
- `docs/plans/2026-06-13-photo-response-body-limit.md`

Document the bounded JSON body contract and record exact validation evidence.

## Test Scenarios

- The current endpoint-sized response remains accepted below 2 MiB.
- A declared `Content-Length` above 2 MiB is rejected before body reading.
- A streamed body crossing 2 MiB is cancelled and rejected.
- The stream reader lock is released after success and failure.
- A non-streaming array-buffer response crossing 2 MiB is rejected by raw bytes.
- Malformed UTF-8 is rejected instead of replacement-decoded.
- A body exactly at the byte ceiling can be decoded and parsed.
- Existing timeout, stale-request, unmount, media-type, and record-validation
  behavior remains unchanged.

## Scope Boundaries

- Do not change the endpoint, display count, UI composition, dependencies,
  Node matrix, or request timeout.
- Do not trust `Content-Length` as the sole boundary; streaming/fallback byte
  accounting remains authoritative.
- Do not add retries, pagination, caching, service workers, or endpoint proxying
  in this focused change.

## Verification

- The live JSONPlaceholder response measured 1,071,472 bytes before selecting
  the 2 MiB ceiling.
- The initial implementation design changed the non-stream fallback from
  `response.text()` to a declared-length-gated `response.arrayBuffer()` because
  text decoding could already have replaced malformed bytes.
- Focused Vitest execution passed all 28 component tests, including declared,
  streamed, fallback, exact-limit, cleanup, and malformed UTF-8 cases.
- `make check` passed in an isolated tracked-file copy: baseline contracts,
  ESLint, Prettier, all 28 tests, and the Vite production build succeeded.
- Twelve hostile mutations were rejected for limit, comparison, cancellation,
  lock release, fatal decoding, text fallback, fallback precheck, array-buffer,
  named test, documentation, and plan-evidence regressions.
- `make check` then passed from the canonical worktree and through `make -C`
  from an external working directory.
- Live browser transport was not exercised; stream/fallback behavior is covered
  with deterministic response-reader fixtures and production build validation.
- A 2026-06-14 follow-up superseded the allocating `arrayBuffer()` fallback:
  successful responses now require a readable byte stream because a whole-body
  API cannot enforce the ceiling before allocation.

## Sources

- Fetch Standard response body model:
  https://fetch.spec.whatwg.org/
- Encoding Standard fatal UTF-8 decoding:
  https://encoding.spec.whatwg.org/
