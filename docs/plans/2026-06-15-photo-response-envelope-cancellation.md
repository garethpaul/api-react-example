---
title: Photo Response Envelope Cancellation
type: reliability
status: planned
date: 2026-06-15
---

# Photo Response Envelope Cancellation

## Problem Frame

Rejected status, redirect, and media-type responses already cancel unread
bodies. Two later envelope failures do not: a declared `Content-Length` above
the byte limit and a response body without a readable-stream reader. Both paths
throw before reading, leaving a provided response body open until the transport
or runtime reclaims it.

## Requirements

- Cancel an unread response body before rejecting an oversized declared
  `Content-Length`.
- Cancel an unread response body before rejecting a body without `getReader`.
- Preserve the deterministic validation error when cancellation throws or
  returns a rejected promise.
- Preserve byte limits, fatal UTF-8 decoding, stream-reader cancellation,
  request timeout and unmount cancellation, response normalization, and UI
  behavior.
- Add focused tests and mutation-sensitive portable contracts for both envelope
  rejection paths.
- Synchronize contributor, security, vision, readme, and change guidance.

## Implementation Units

### 1. Cancel unread envelope failures

**Files:** `src/components/Photos.jsx`

Reuse the existing best-effort unread-response cancellation helper immediately
before both pre-read envelope errors.

### 2. Prove cleanup and error authority

**Files:** `src/App.test.jsx`, `scripts/check-baseline.sh`

Assert cancellation for oversized declarations and unstreamable bodies,
including rejected cancellation promises, while preserving the original
validation messages. Enforce source ordering before each throw.

### 3. Document the response cleanup boundary

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`

Record that every pre-read photo response envelope rejection attempts body
cancellation without replacing validation errors.

## Verification

- Run the focused Vitest cases for response body limits and readable-stream
  requirements.
- Run the repository package gate from the repository root and an external
  directory.
- Reject hostile mutations that remove either cancellation call, move cleanup
  after the throw, or weaken completed-plan evidence.
- Audit the exact diff, generated artifacts, whitespace, and changed lines for
  credential material before committing.

## Risks And Mitigations

- **Cancellation failures:** retain the existing best-effort helper that absorbs
  synchronous throws and rejected promises so validation errors stay stable.
- **Double cancellation:** these paths reject before reader ownership exists;
  later request cleanup sees no reader cancel callback.
- **Stacked delivery:** base the pull request on the rejected-response body
  cancellation branch and retain base-first merge ordering.

## Out Of Scope

- Changing endpoint, rendering, photo limits, timeout duration, or retry policy.
- Adding a whole-body fallback for unstreamable responses.
- Live endpoint or cross-browser transport testing.
