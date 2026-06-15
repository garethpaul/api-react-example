# Photo Thumbnail Shared Address Boundary

Status: Completed

## Problem

Thumbnail URLs are validated before rendering, but the explicit-literal policy
still accepts IPv4 shared address space in `100.64.0.0/10`. Browsers on managed
or carrier networks may route that range internally, contradicting the current
non-public literal boundary.

## Priorities

1. Reject explicit shared-address thumbnail hosts before rendering.
2. Cover both range boundaries, adjacent public controls, URL-normalized numeric
   forms, and IPv4-mapped IPv6.
3. Preserve public literals, DNS-style hosts, HTTPS normalization, response
   cancellation, rendering, dependencies, and build behavior.

## Requirements

- Extend `isBlockedIpv4Address` with the exact `100.64.0.0/10` range.
- Add rejected fixtures at the range boundaries and mapped IPv6 representation.
- Add accepted controls immediately below and above the range.
- Keep DNS-style hosts unresolved and retain the documented rebinding limit.
- Add mutation-sensitive source, fixture, guidance, and completion contracts.

## Implementation Units

### 1. Extend thumbnail host policy

**File:** `src/components/Photos.jsx`

Classify the shared range alongside existing blocked IPv4 literals.

### 2. Add executable and static regressions

**Files:** `src/App.test.jsx`, `scripts/check-baseline.sh`

Exercise range boundaries, adjacent controls, mapped IPv6, maintained guidance,
and completed-plan evidence.

### 3. Synchronize guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

## Verification

- Prove a hostile shared-address fixture fails before implementation.
- Run focused Vitest coverage and full repository/external `make check` gates.
- Reject isolated range, boundary, mapped-address, public-control, guidance,
  and incomplete-plan mutations.
- Audit exact paths, generated artifacts, conflict markers, dependency/workflow
  drift, whitespace, and credential-shaped additions.

## Risks

- An incorrect range check could reject adjacent public IPs; executable boundary
  controls must remain.
- DNS names are not resolved, so DNS rebinding remains out of scope.
- This PR is stacked on PR #18 and must retain base-first merge ordering.

## Out Of Scope

- DNS resolution, rebinding prevention, CSP, proxy policy, image fetching, and
  connection-address pinning.
- Dependency, Vite, React, API endpoint, response-envelope, or UI changes.

## Completion Evidence

- The focused table-driven thumbnail host cases passed for shared-range
  boundaries, mapped IPv6, and adjacent public controls.
- Repository-root and external-directory `make check` passed the baseline,
  ESLint, Prettier, Vitest, coverage thresholds, and production build.
- Seven isolated mutations were rejected across range logic, lower and upper
  boundaries, mapped IPv6, public controls, maintained guidance, and completed
  plan evidence.
- Exact-path diff, generated-artifact, conflict-marker, dependency/workflow
  drift, whitespace, and credential-shaped-addition audits passed.
- No DNS resolution, browser network inspection, or production deployment was
  exercised.
