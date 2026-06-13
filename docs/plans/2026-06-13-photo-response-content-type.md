---
title: Photo Response Content Type Validation
type: security
status: completed
date: 2026-06-13
---

# Photo Response Content Type Validation

## Status: Completed

## Problem Frame

The photo loader checks HTTP status and then calls `response.json()` for every
successful response. A proxy, captive portal, or misconfigured endpoint can
return HTML or another unexpected representation with a 2xx status. Parsing
that body as JSON obscures the protocol mismatch and leaves the expected
response media type unenforced.

## Scope Boundaries

- Preserve the JSONPlaceholder HTTPS endpoint, 10-second request timeout,
  abort behavior, request ownership, and generic user-facing error state.
- Preserve existing photo record validation, normalization, uniqueness, and
  12-card render limit.
- Do not add retries, endpoint fallback, or content sniffing.
- Accept standard JSON media types case-insensitively, including parameters and
  structured syntax suffixes such as `application/problem+json`.

## Implementation Units

### U1: Validate Successful Response Media Types

Files:

- Modify `src/components/Photos.jsx`

Approach:

- Add a small exported helper for JSON media-type recognition.
- Read `Content-Type` only after the HTTP status succeeds.
- Require `application/json` or an `application/*+json` subtype before calling
  `response.json()`.
- Treat missing, malformed, and non-JSON content types as request failures.

### U2: Add Component And Helper Coverage

Files:

- Modify `src/App.test.jsx`

Approach:

- Make successful fetch fixtures expose an `application/json` header.
- Cover case-insensitive JSON types with parameters and `+json` suffixes.
- Prove missing and HTML content types render the generic error state and never
  invoke the JSON parser.

### U3: Extend Static And Documentation Contracts

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `CHANGES.md`
- Modify `VISION.md`

Approach:

- Require header lookup, media-type validation before JSON parsing, named
  regression tests, documentation, and completed plan evidence.
- Record that successful responses must explicitly identify JSON content.

## Verification

- `make check` passed repository contracts, ESLint, Prettier, 22 Vitest tests,
  and the Vite production build.
- The absolute-path Makefile gate passed from `/tmp`.
- Focused `src/App.test.jsx` execution passed all 22 tests.
- `corepack yarn audit --json` reported zero info, low, moderate, high, or
  critical vulnerabilities across 251 dependencies.
- Ten isolated hostile mutations were rejected across media-type branches,
  header lookup, status/parser ordering, validation, named tests, and README
  evidence.
- `git diff --check` passed.
