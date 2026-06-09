# Photo Render Field Normalization

Status: Completed
Date: 2026-06-09

## Goal

Keep accepted API photo fields clean before the component uses them in visible
headings, image alt text, and image sources.

## Changes

- Added thumbnail URL normalization that reuses the existing HTTPS parser and
  renders the canonical `href` value.
- Added photo normalization that trims accepted titles before rendering.
- Preserved full-response validation before the render limit is applied.
- Added Jest and SDK-free source-baseline coverage for normalized render fields.

## Verification

- `make check`
- `corepack yarn lint`
- `CI=true corepack yarn test --watchAll=false`
- `corepack yarn build`
- `git diff --check`
