# Visible Photo Title Validation

## Status: Completed

## Goal

Prevent malformed API records from rendering effectively blank card headings
and image alternative text without damaging valid Unicode titles.

## Work

- Added a Unicode visible-character predicate for photo titles.
- Rejected format-only and combining-mark-only title values.
- Preserved decomposed visible text and emoji sequences.
- Added failing-first component regressions and portable source contracts.
- Updated maintained security, vision, agent, README, and change guidance.

## Verification

- Run the focused component suite and complete Vitest suite.
- Run `make check` from the repository root and an external directory.
- Run lint, Prettier, the Vite production build, and dependency audit.
- Reject isolated source, test, guidance, and plan mutations.
- Audit whitespace, generated artifacts, dependency drift, and secret-shaped
  additions.

## Completion Evidence

- Before implementation, both invisible-title regressions rendered photo cards
  and timed out waiting for the error state.
- After implementation, all 128 focused component cases passed under Node
  20.19 with pinned Yarn 1.22.22.
- Repository-root and external-directory `make check` passed under Node 20.19,
  including 77 workflow-policy fixtures, dependency-policy mutations, lint,
  Prettier, all 128 component cases, and the Vite production build.
- The pinned dependency audit reported zero vulnerabilities.
- Five isolated implementation, regex, fixture, guidance, and plan-status
  mutations were rejected.
- Shell syntax, whitespace, generated-artifact, and likely-secret audits
  passed. Hosted checks must pass on the exact pull request head before merge.

## Scope Boundaries

- Do not change request, response-stream, timeout, thumbnail, ID, or maximum
  photo behavior.
- Do not normalize away accepted Unicode characters or add dependencies.
