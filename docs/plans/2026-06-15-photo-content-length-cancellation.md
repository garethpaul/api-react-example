---
title: Photo Content-Length Cancellation
type: security
status: planned
date: 2026-06-15
---

# Photo Content-Length Cancellation

## Problem

Successful photo responses reject malformed and unsafe-range `Content-Length`
values before reading the body. Those parser failures currently escape before
the unread response body is cancelled, unlike oversized declarations and other
pre-read envelope rejections. A rejected envelope can therefore leave its
transport body open until browser cleanup.

## Priorities

1. P0: Initiate best-effort unread-body cancellation when declared length
   parsing rejects the response envelope.
2. P1: Preserve the existing malformed and unsafe-range validation errors even
   when cancellation throws or rejects.
3. P2: Keep broader HTTP parsing and networking-client modernization outside
   this focused cleanup boundary.

## Requirements

- Cancel the unread response body before propagating malformed numeric-format
  and unsafe-range `Content-Length` errors.
- Preserve missing, valid, boundary-sized, and oversized length behavior.
- Preserve the existing deterministic validation messages and ensure cleanup
  failures cannot replace them.
- Add focused regressions for malformed and unsafe-range declared lengths,
  including rejected cancellation promises.
- Add mutation-sensitive source, test, maintained-guidance, and completed-plan
  contracts.

## Implementation Units

### U1: Declared-Length Cleanup Boundary

**File:** `src/components/Photos.jsx`

Catch only declared-length parsing failures at the response-envelope boundary,
initiate the existing best-effort unread-body cancellation, and rethrow the
original validation error unchanged.

### U2: Malformed-Length Regressions

**File:** `src/App.test.jsx`

Exercise a nonnumeric declaration and an integer outside JavaScript's safe
range. Assert body cancellation and the existing exact error messages, with at
least one cleanup rejection to prove validation-error authority.

### U3: Portable Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require ordered parse-failure cleanup, scoped regression evidence, synchronized
maintenance guidance, completed status, and truthful verification evidence.

## Verification

- Run the focused malformed-length tests and complete Vitest suite.
- Run ESLint, Prettier, the Vite production build, and `yarn audit` using the
  lockfile-installed toolchain.
- Run repository-root and external-directory `make check`.
- Reject isolated source, error-authority, test-fixture, guidance, and
  plan-completion mutations.
- Audit exact intended paths, generated artifacts, conflict markers,
  dependency/workflow drift, whitespace, and credential-shaped additions.

## Scope Boundaries

- Do not change byte limits, stream buffering, UTF-8 or JSON parsing, status,
  redirect, media-type, timeout, request ownership, normalization, or rendering
  behavior.
- Do not add dependencies or claim live endpoint or cross-browser transport
  verification.
- Keep this pull request stacked on PR #11 and preserve base-first ordering.
