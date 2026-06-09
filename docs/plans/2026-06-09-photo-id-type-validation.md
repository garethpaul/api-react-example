---
title: Photo ID Type Validation
type: reliability
status: completed
date: 2026-06-09
---

# Photo ID Type Validation

## Problem Frame

The photo list already rejects missing and duplicate API IDs before rendering
cards, but it still accepted values that are not safe React keys, such as
objects or empty strings. Those values can make keys unstable or misleading
after JavaScript string coercion.

## Scope Boundaries

- Preserve the existing JSONPlaceholder endpoint and response cap.
- Keep the existing generic user-facing error state.
- Do not change title or thumbnail URL validation behavior.
- Keep the guard covered by Jest and the SDK-free source baseline.

## Implementation Units

### U1: Require Key-Safe Photo IDs

Files:

- Modify `src/components/Photos.js`

Approach:

- Add a focused ID validator that accepts only finite numbers and non-empty
  strings.
- Normalize accepted IDs before they are used for React keys.
- Use the normalized ID comparison in the duplicate-ID guard.

### U2: Cover Rejected ID Shapes

Files:

- Modify `src/App.test.js`

Approach:

- Add a Jest case for an object-valued photo ID.
- Assert that the generic error state appears and the malformed card is not
  rendered.

### U3: Document And Enforce The Contract

Files:

- Modify `scripts/check-baseline.sh`
- Modify `README.md`
- Modify `VISION.md`
- Modify `CHANGES.md`

Approach:

- Extend the source baseline with checks for ID validation, normalization, and
  this completed plan.
- Document the key-safe ID requirement alongside the existing photo rendering
  guardrails.

## Verification

- `scripts/check-baseline.sh`
- `make check`
- `git diff --check`
