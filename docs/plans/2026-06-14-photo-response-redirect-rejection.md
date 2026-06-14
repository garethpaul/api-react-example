# Photo Response Redirect Rejection

Status: Completed

## Problem

The application fetches a fixed HTTPS photo endpoint but currently accepts the
browser's default redirect behavior. A redirect can move the final response to
an unreviewed origin while retaining the same success, content-type, body-size,
and record validation path.

## Requirements

1. Send every photo request with the Fetch API redirect mode set to `error`.
2. Preserve AbortController support while using the same request-options shape
   when AbortController is unavailable.
3. Reject any successful response marked as redirected before content-type or
   response-body parsing.
4. Add regressions for request options and redirected-response rejection.
5. Extend dependency-free contracts and completed verification evidence.

## Verification

- Run focused redirect tests, then the complete pinned `make check` gate.
- Run clean-install verification and dependency audit.
- Reject mutations that remove request-mode, response guard, ordering, tests,
  documentation, or completed-plan evidence.
- Audit generated artifacts, structured files, whitespace, exact diff, and
  changed-line credential patterns.

## Scope Boundaries

- Do not change the endpoint, timeout, request ownership, cancellation,
  content-type, body-size, UTF-8, photo-record, or rendering contracts.
- Do not add redirect following, manual redirect resolution, or origin
  allowlists beyond the existing fixed endpoint.
- Do not merge or close any pull request without explicit owner authorization.

## Work Completed

- Sent all photo requests with redirect mode `error`, with or without
  AbortController support.
- Rejected redirected successful responses before content-type or body reads.
- Added request-option, response-ordering, test, documentation, and completed
  plan contracts.

## Verification Results

- Installed the exact `yarn.lock` graph with lifecycle scripts disabled, then
  passed the dependency-free checker and two focused redirect tests.
- `make check` passed the baseline, ESLint, Prettier, all 33 Vitest tests, and
  the Vite production build.
- `yarn audit --level moderate` reported zero vulnerabilities across 251
  packages.
- The dependency-free checker rejected all 11 hostile mutations covering
  request mode, request options, response guard and ordering, regression tests,
  completed-plan evidence, and documentation.
- Exact-diff, whitespace, conflict-marker, JSON, YAML, generated-artifact, and
  changed-line credential-pattern audits passed. No changed SVG files required
  parsing; `gitleaks`, `jq`, and `xmllint` were unavailable.
