---
title: CodeQL Baseline
date: 2026-06-12
status: completed
execution: code
---

# CodeQL Baseline

## Summary

Add canonical static analysis for the repository's GitHub Actions and
JavaScript/TypeScript surfaces without changing the React sample runtime,
dependencies, existing Node matrix, or build behavior.

## Requirements

- Analyze `actions` and `javascript-typescript` on pushes, pull requests,
  scheduled runs, and manual dispatches.
- Pin checkout and CodeQL actions to reviewed immutable commit SHAs.
- Keep checkout credentials disabled, global permissions minimal, hosted jobs
  bounded, and superseded runs cancelled.
- Extend the SDK-free repository checker to reject workflow, permission,
  language, action-pin, and bypass drift.
- Preserve the existing frozen Yarn install and Node 20/22/24 `make check`
  workflow unchanged.
- Pass local verification and exact-head hosted Check and CodeQL gates.

## Scope And Verification

This unit changes only the new CodeQL workflow, static contracts, repository
guidance, and evidence. Verification includes the untouched baseline, full
`make check`, external-working-directory execution, workflow parsing, hostile
mutations, and bounded exact-head hosted queries.

## Work Completed

- Added canonical CodeQL analysis for `actions` and
  `javascript-typescript` using pinned checkout and CodeQL actions.
- Limited global permissions to read-only contents and security result upload,
  disabled checkout credential persistence, bounded runtime, and cancelled
  superseded runs.
- Extended the SDK-free checker and repository guidance without changing the
  existing Check workflow, package graph, or React runtime.

## Verification Completed

- The untouched baseline passed before implementation.
- `make check` passed the repository contracts, ESLint, Prettier, all 19
  Vitest tests, and the Vite production build.
- The same full gate passed from an external working directory.
- Focused hostile mutations rejected language, action pin, permission,
  bypass, documentation, and incomplete plan drift.
- Workflow parsing, `git diff --check`, and the secret-pattern scan passed.

## Hosted Verification

Exact-head Check and CodeQL evidence will be recorded after the implementation
commit is pushed. Tracker reconciliation remains pending until both canonical
events are terminal green on the same final head.
