# Reject Local-Use NAT64 Thumbnail Literals

Status: Completed

## Problem

The thumbnail URL policy rejects private, non-unicast, and selected
special-purpose address literals before rendering an image. It still accepts
IPv6 literals in `64:ff9b:1::/48`, which IANA designates as the IPv4-IPv6
translation prefix for local use and marks non-global. A backend response can
therefore cause the browser to request a non-global literal such as
`https://[64:ff9b:1::1]/thumbnail.jpg`.

## Priorities

1. P0: Reject the complete local-use translation prefix before image render.
2. P1: Preserve the distinct globally routable well-known translation prefix
   `64:ff9b::/96` and ordinary public IPv6 literals.
3. P1: Make prefix removal and accidental broadening mutation-visible.

## Requirements

- R1. Add `64:ff9b:1::/48` to the numeric special-purpose IPv6 prefix table.
- R2. Reject representative lower and upper literals inside the prefix.
- R3. Preserve literals immediately outside the prefix and the separate
  `64:ff9b::/96` well-known prefix.
- R4. Extend portable static contracts and maintained security guidance.
- R5. Record only verification actually completed and keep DNS-answer and
  connected-peer enforcement explicitly outside this browser-only boundary.

## Implementation

- Update `src/components/Photos.jsx` with the exact `/48` prefix.
- Add table-driven blocked and accepted controls in `src/App.test.jsx`.
- Extend `scripts/check-baseline.sh` so removal of the prefix, fixtures,
  guidance, or completed plan evidence fails the repository gate.
- Update `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, and `CHANGES.md`
  with the narrow literal-address policy.

## Verification

- Demonstrate the new blocked fixture fails before implementation.
- Run the focused Vitest matrix and the complete package gate from the
  repository and an external working directory with explicit timeouts.
- Run production dependency audit and isolated hostile mutations for prefix
  presence, `/48` length, blocked boundaries, accepted controls, guidance,
  and plan completion evidence.
- Audit exact diff, generated artifacts, dependencies/workflows, secrets,
  conflict markers, file modes, and whitespace before commit.

## Scope Boundaries

- Do not block the separate `64:ff9b::/96` well-known prefix.
- Do not add DNS resolution, connected-peer inspection, proxying, or network
  dependencies; browser application JavaScript cannot bind image requests to
  prevalidated DNS answers.
- Do not merge or close stacked pull requests without owner authorization.

## Source

- IANA IPv6 Special-Purpose Address Space registry, entry
  `64:ff9b:1::/48` (IPv4-IPv6 Translat., last changed April 2024), with
  `Globally Reachable` set to False:
  `https://www.iana.org/assignments/iana-ipv6-special-registry/`

## Completion Record

- Before implementation, the two new `64:ff9b:1::/48` blocked fixtures
  failed because the component rendered image elements for both literals.
- After implementation, the focused blocked/accepted IPv6 matrix passed 25
  cases and the complete Vitest suite passed all 118 tests.
- ESLint, Prettier, and the production Vite build passed.
- The production-only Yarn audit reported zero vulnerabilities across three
  runtime dependencies.
- Both repository and external-directory package gates passed the baseline checker, ESLint,
  Prettier, all 118 Vitest cases, and the production build.
- Eleven isolated hostile mutations were rejected across prefix presence,
  `/48` narrowing and broadening, lower and upper blocked fixtures, well-known
  and adjacent accepted controls, maintained guidance, plan status, and
  verification evidence.
- Final artifact, secret, dependency/workflow, conflict-marker, file-mode,
  whitespace, and exact-diff audits are recorded before commit.
