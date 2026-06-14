# Photo Stream Chunk Validation

Status: In Progress

## Problem

The bounded photo stream reader assumes every `done: false` read returns a
nonempty `Uint8Array`. It currently coerces other values with `new Uint8Array`,
so empty or malformed chunks can make no byte progress while keeping the read
loop active until the outer request timeout.

## Requirements

1. Accept only nonempty `Uint8Array` chunks while a photo stream is active.
2. Cancel the reader before rejecting an invalid or zero-length chunk, while
   preserving the deterministic validation error if cancellation fails.
3. Release the reader lock and clear the request cancellation callback on every
   success or failure path.
4. Preserve valid fragmented streams, the 2 MiB byte limit, strict UTF-8 JSON
   parsing, declared-length handling, timeout cancellation, redirect/content
   type validation, and photo normalization.
5. Add focused executable tests for invalid chunk types, empty chunks,
   cancellation failure, and existing valid fragmentation.
6. Add mutation-sensitive source, test, documentation, and completed-plan
   contracts.

## Implementation Units

### U1: Reject Non-Progress Chunks

**File:** `src/components/Photos.jsx`

Validate the reader value before byte-limit arithmetic and centralize
best-effort cancellation for malformed and oversized chunks.

### U2: Add Focused Regression Tests

**File:** `src/App.test.jsx`

Verify rejection, cancellation, lock release, callback clearing, cancellation
failure precedence, and continued acceptance of valid one-byte fragmentation.

### U3: Protect And Document

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, this plan

Require validation before copying, focused test names, documentation, and
truthful verification evidence.

## Scope Boundaries

- Do not change the endpoint, response limit, timeout, content types, photo
  schema, render limit, thumbnail policy, dependencies, or UI.
- Do not replace Fetch or ReadableStream and do not claim live endpoint or
  browser-network behavior.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- Pending implementation and bounded validation.
