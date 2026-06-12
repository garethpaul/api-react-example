---
title: CodeQL Baseline
date: 2026-06-12
status: completed
execution: code
---

# CodeQL Baseline

## Summary

Document and guard the repository's existing GitHub CodeQL default setup for
the GitHub Actions and JavaScript/TypeScript surfaces without changing the
React sample runtime, dependencies, existing Node matrix, or build behavior.

## Requirements

- Preserve GitHub default setup analysis for `actions` and
  `javascript-typescript` as the repository-owned external security setting.
- Do not add an advanced CodeQL workflow while default setup is active because
  GitHub rejects the conflicting configuration modes.
- Keep the existing Check workflow credential-free, immutable, read-only,
  bounded, and cancellation-aware.
- Extend the SDK-free repository checker to reject extra workflows, including
  any duplicate advanced CodeQL workflow.
- Preserve the existing frozen Yarn install and Node 20/22/24 `make check`
  workflow unchanged.
- Pass local verification and exact-head hosted Check and CodeQL gates.

## Scope And Verification

This unit changes only static contracts, repository guidance, and evidence.
Verification includes the untouched baseline, full `make check`,
external-working-directory execution, workflow parsing, hostile mutations,
and bounded exact-head hosted queries.

## Work Completed

- Recorded that GitHub default setup already analyzes `actions` and
  `javascript-typescript` on the repository.
- Removed the conflicting advanced CodeQL workflow after both of its jobs
  failed while the matching default-setup jobs succeeded on the same head.
- Extended the SDK-free checker to reject extra and advanced CodeQL workflows
  without changing the existing Check workflow, package graph, or React
  runtime.

## Verification Completed

- The untouched baseline passed before implementation.
- `make check` passed the repository contracts, ESLint, Prettier, all 19
  Vitest tests, and the Vite production build.
- The same full gate passed from an external working directory.
- Focused hostile mutations rejected duplicate CodeQL and extra workflows,
  missing default-setup and advanced-workflow plan contracts, stale repository
  guidance, and incomplete plan drift.
- Workflow parsing, `git diff --check`, and the secret-pattern scan passed.

## Hosted Verification

On head `7e92cdae08e44cebd804745a7182ebc1f04482b1`, Check run
`27441786600` and GitHub default-setup CodeQL run `27441784792` succeeded,
while duplicate advanced CodeQL run `27441786655` failed for both languages.
The advanced workflow was removed without reducing the successful default
setup coverage. Exact-head replacement evidence remains pending until the
remediation commit is pushed and all canonical checks are terminal green.
