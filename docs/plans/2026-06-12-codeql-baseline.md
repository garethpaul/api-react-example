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
- Permit unrelated workflows only when their permissions and action graph pass
  the semantic workflow policy.
- Recursively inspect tracked local composite actions and local reusable
  workflows, reject cycles and symlinks, and reject all remote reusable
  workflows because their transitive behavior is outside this repository.
- Reject advanced CodeQL actions while allowing a SHA-pinned `upload-sarif`
  action with the narrowly required `security-events: write` permission.
- Preserve the existing frozen Yarn install and Node 20/22/24 `make check`
  workflow unchanged.
- Pass local verification and exact-head hosted Check and CodeQL gates.

## Scope And Verification

This unit changes only development-time policy code, static contracts,
repository guidance, and evidence.
Verification includes the untouched baseline, full `make check`,
external-working-directory execution, workflow parsing, hostile mutations,
and bounded exact-head hosted queries.

## Work Completed

- Recorded that GitHub default setup already analyzes `actions` and
  `javascript-typescript` on the repository.
- Removed the conflicting advanced CodeQL workflow after both of its jobs
  failed while the matching default-setup jobs succeeded on the same head.
- Replaced textual singleton-workflow checks with semantic YAML validation.
- Protected the canonical Check workflow as an exact semantic object, including
  read-only permissions, checkout credential handling, runner, matrix,
  conditions, environment, shells, action pins, and command values.
- Added bounded recursive inspection for tracked local composite actions and
  local reusable workflows. Remote reusable workflows and advanced CodeQL
  actions fail closed; pinned `upload-sarif` remains supported.
- Added the dependency-free `yaml@2.9.0` parser as an exact development-only
  dependency without changing the React runtime or production bundle behavior.

## Verification Completed

- The untouched baseline passed before implementation.
- `make check` passed the repository contracts, ESLint, Prettier, all 19
  Vitest tests, and the Vite production build.
- The same full gate passed from an external working directory.
- Focused hostile mutations reject writable permissions, credential-persisting
  checkout, authenticated command injection, job environment/default/condition
  changes, local action and reusable-workflow indirection, remote reusable
  workflows, Unicode ambiguity, duplicate keys, directives, unsupported tags,
  aliases, cycles, symlinks, and excessive SARIF permissions.
- Positive fixtures preserve unrelated read-only workflows, standard tagged
  scalars, local inspectable delegation, and narrowly permissioned
  `upload-sarif` workflows.
- Workflow parsing, `git diff --check`, and the secret-pattern scan passed.

## Trust Boundary

The in-tree checker proves the behavior of the exact reviewed patch and catches
uncoordinated workflow drift. It cannot authorize a future coordinated change
that weakens the checker, fixtures, Make wiring, and workflow together. That is
a human-review and branch-protection boundary, not a defect in this exact
policy implementation. Future policy changes require exact-patch review and
fresh hosted evidence.

The policy authenticates the tracked workflow and action graph; it does not
prove arbitrary application or test code executed by the canonical `make
check` command is benign. Changes to executable repository code remain a human
review boundary because such code runs inside the hosted job and can interact
with runner state. Unrelated workflows therefore cannot combine executable
steps with token-bearing remote actions, while the unchanged canonical workflow
is reviewed as one exact semantic contract.

## Hosted Verification

On head `7e92cdae08e44cebd804745a7182ebc1f04482b1`, Check run
`27441786600` and GitHub default-setup CodeQL run `27441784792` succeeded,
while duplicate advanced CodeQL run `27441786655` failed for both languages.
The advanced workflow was removed without reducing the successful default
setup coverage. Exact-head replacement evidence remains pending until the
remediation commit is pushed and all canonical checks are terminal green.
