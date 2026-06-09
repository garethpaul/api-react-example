---
title: Photo Thumbnail URL Validation
type: security
status: completed
date: 2026-06-09
---

# Photo Thumbnail URL Validation

## Problem Frame

The photo renderer validated that `thumbnailUrl` was non-empty text, but it did
not verify that the value was a parseable HTTPS URL before inserting it into an
image element. A malformed or insecure API record should use the existing error
state instead of rendering untrusted media URLs.

## Scope Boundaries

- Preserve the JSONPlaceholder photos endpoint and the existing photo list UI.
- Keep the all-or-error normalization behavior for malformed API records.
- Do not add a URL parsing dependency.
- Do not broaden validation to unused API fields in this pass.

## Implementation Units

### U1: Validate Thumbnail URL Protocol

Files:

- Modify `src/components/Photos.js`

Approach:

- Add a small URL validation helper using the platform `URL` parser.
- Require parsed thumbnail URLs to use the `https:` protocol.
- Continue to reject missing, blank, malformed, or non-object records through
  `isRenderablePhoto`.

### U2: Add Regression Coverage

Files:

- Modify `src/App.test.js`
- Modify `scripts/check-baseline.sh`

Approach:

- Add a Jest case proving an HTTP thumbnail URL renders the existing error
  state and does not render the card title.
- Extend the source baseline to require the HTTPS URL helper and test coverage.

### U3: Document The Contract

Files:

- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Record that rendered thumbnail URLs must parse as HTTPS.
- Keep future API work aligned with validating media URLs before DOM rendering.

## Verification

- `sh scripts/check-baseline.sh`
- `make check`
- `corepack yarn verify`
- `git diff --check`
