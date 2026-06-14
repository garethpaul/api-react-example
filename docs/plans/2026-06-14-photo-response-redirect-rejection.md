# Photo Response Redirect Rejection

Status: Planned

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
