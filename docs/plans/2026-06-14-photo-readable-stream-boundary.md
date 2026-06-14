# Photo Readable Stream Boundary

Status: Planned

## Problem

The photo response reader enforces its 2 MiB ceiling incrementally when a
readable byte stream is available. Its compatibility fallback calls
`response.arrayBuffer()` and can only inspect the resulting length after the
browser has already allocated the complete response. A false or missing
`Content-Length` therefore bypasses the intended pre-allocation memory bound.

## Requirements

1. Require successful photo responses to expose a readable byte stream before
   body consumption.
2. Reject an unavailable or unusable stream through the existing generic error
   state without calling `arrayBuffer()`, `text()`, or `json()`.
3. Preserve declared-length rejection, the 2 MiB incremental byte ceiling,
   strict UTF-8 decoding, invalid-chunk cancellation, lock release, timeout and
   unmount cancellation ownership, and photo normalization.
4. Add mutation-sensitive tests and baseline contracts for the fail-closed
   boundary.
5. Correct documentation that currently describes the allocating fallback as
   bounded.

## Implementation

- Remove the `arrayBuffer()` fallback from `readBoundedPhotoJson` and require a
  `body.getReader()` function.
- Make successful fetch fixtures use readable streams and replace fallback
  acceptance tests with an explicit unstreamable-response rejection test.
- Extend `scripts/check-baseline.sh` to reject restored whole-body fallbacks and
  require the named regression.
- Update repository guidance, security notes, vision, changelog, and this plan
  with completed verification evidence.

## Validation

- Run the focused Vitest component suite.
- Run isolated hostile mutations for stream requirement, fallback restoration,
  and named regression removal.
- Run `make check` from the repository and an external working directory.
- Audit the exact diff, generated artifacts, credential patterns, and branch
  state before committing and pushing.

## Scope

- Do not change the endpoint, request timeout, render limit, UI, dependencies,
  or hosted Node matrix.
- Do not add buffering libraries or claim live browser transport validation.
