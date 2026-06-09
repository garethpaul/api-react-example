# Photo Thumbnail Credential Validation

status: completed

## Context

Thumbnail URL validation required parseable HTTPS URLs before rendering image
elements. HTTPS URLs with embedded username or password components were still
accepted and could place credential-bearing media URLs into the DOM.

## Objectives

- Preserve the existing JSONPlaceholder endpoint and all-or-error photo
  normalization behavior.
- Continue accepting ordinary HTTPS thumbnail URLs.
- Reject thumbnail URLs that include embedded credentials.
- Keep the guard covered by Jest and the source baseline checker.

## Work Completed

- Extended `normalizeHttpsUrl` to reject parsed URLs with `username` or
  `password` components.
- Added Jest coverage for credentialed thumbnail URLs.
- Extended `scripts/check-baseline.sh`.
- Updated README, VISION, and CHANGES notes.

## Verification

- `CI=true corepack yarn test --watchAll=false`
- `sh scripts/check-baseline.sh`
- `make check`
- `git diff --check`
