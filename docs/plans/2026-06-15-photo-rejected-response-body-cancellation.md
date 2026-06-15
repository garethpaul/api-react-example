# Cancel Rejected Photo Response Bodies

Status: Completed

## Context

Photo responses rejected for status, redirects, or media type fail before
`readBoundedPhotoJson` registers the active stream reader. Their unread response
bodies are therefore never cancelled, leaving transport cleanup to browser
implementation details.

## Scope

- Initiate best-effort response-body cancellation before rejecting non-success,
  redirected, or non-JSON responses.
- Preserve the original validation error when cancellation throws or rejects.
- Preserve readable-stream requirements, bounded consumption, request timeout,
  unmount cancellation, and successful photo normalization.
- Add deterministic tests, fail-closed source contracts, and maintenance
  documentation for the pre-read cleanup boundary.

## Verification

- Run focused Vitest coverage plus repository and external-directory
  `make check`.
- Reject hostile mutations that remove cancellation, change rejection ordering,
  await cancellation, weaken cancellation-failure isolation, remove tests or
  documentation, or reopen the completed plan.
- Audit the exact diff, generated artifacts, credential patterns, and whitespace
  before commit.

## Risks

- Cancellation is intentionally best effort and is not awaited, so transport
  cleanup cannot delay or replace the original response validation error.
- Live endpoint and cross-browser response-body cancellation were not exercised.
- Existing stacked pull requests remain open and require explicit owner
  authorization before merge or closure.

## Verification Completed

- Focused `corepack yarn test src/App.test.jsx --run` passed all 36 component,
  response, stream, cancellation, lifecycle, and rendering tests.
- Ten hostile mutations were rejected for helper ownership, cancellation
  isolation, all three rejection branches, assertions, documentation, and
  completed-plan evidence.
- Repository and external-directory `make check` run the pinned lint, format,
  test, and production-build gate.
- Live endpoint and cross-browser response-body cancellation were not exercised.
