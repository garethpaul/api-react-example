# Photo Late Response Cancellation

Status: Planned

## Problem

When `AbortController` is unavailable, a photo request can time out before
`fetch` resolves. Timeout handling clears request ownership, but a later fetch
response still enters status, header, and stream processing because ownership
is not checked at the response boundary. The expired request can therefore
consume an unread response body after the UI has already reported failure.

## Priorities

1. Reject a fetch response immediately when its request no longer owns the
   component load.
2. Cancel the unread late response body before status, redirect, header, or
   stream access.
3. Preserve active-request validation, bounded streaming, timeout behavior,
   and the generic user-facing error state.
4. Add a deterministic fake-timer regression and mutation-sensitive portable
   contracts for ownership and cleanup ordering.

## Requirements

- `fetchPhotos` must compare the resolved response's request with
  `activeRequest` before reading response metadata or body data.
- A response for an expired, unmounted, or superseded request must use the
  existing unread-body cancellation helper and then reject.
- The ownership check must precede `response.ok`, `response.redirected`, header
  access, and `readBoundedPhotoJson`.
- Existing timeout, stream cancellation, content-type, size, schema,
  thumbnail, and render-limit behavior must remain unchanged.
- Repository-root and external-directory verification must remain equivalent.

## Implementation Units

### 1. Reject late fetch responses

**File:** `src/components/Photos.jsx`

Add an ownership boundary immediately after `fetch` resolves. Cancel and reject
an unread response when the component no longer owns the originating request.

### 2. Cover response-after-timeout ordering

**File:** `src/App.test.jsx`

Use fake timers and deferred fetch resolution without `AbortController` to
prove the timeout renders the existing error, a later response body is
cancelled, and headers and stream readers are never touched.

### 3. Protect the contract

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the ownership/cancellation/rejection sequence before response metadata,
record the maintained lifecycle rule, and keep completed verification durable.

## Verification

- Run the focused late-response test and the portable baseline checker.
- Run the pinned full `make check` gate from the repository root and an
  unrelated working directory.
- Reject isolated missing ownership, missing cancellation, after-header
  ownership, missing regression-test, removed guidance, and reopened-plan
  mutations.
- Audit exact paths, generated artifacts, conflict markers, file modes,
  dependency and workflow drift, whitespace, and credential-shaped additions.

## Risks

- Response-body cancellation remains best effort and preserves the existing
  deterministic validation error if cancellation itself fails.
- Browser engines may differ in transport cleanup timing; the test proves
  application ownership and access ordering, not network-stack behavior.
- This pull request will be stacked on PR #17 and must retain base-first order.

## Out Of Scope

- Fetch replacement, service workers, retries, caching, or endpoint changes.
- Thumbnail URL policy, response size, media type, schema, render limits,
  dependencies, styling, or user-visible copy.
- Live endpoint or cross-browser transport testing.
