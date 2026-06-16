# Photo Thumbnail Default HTTPS Port

Status: Planned

## Problem

API-provided thumbnail URLs require HTTPS, reject credentials, and block
explicit non-public address literals, but still accept arbitrary explicit
ports. A response can therefore direct the browser to a nonstandard TLS service
on an otherwise accepted host, broadening the client-side network surface
beyond ordinary HTTPS image delivery.

Browser JavaScript cannot resolve a hostname or inspect the connected peer, so
DNS rebinding cannot be truthfully closed in this client-only architecture.
Restricting thumbnails to the default HTTPS port is the next enforceable
transport boundary.

## Priorities

1. Reject thumbnail URLs with an explicit nondefault HTTPS port.
2. Preserve ordinary URLs and explicit `:443` URLs after URL normalization.
3. Preserve HTTPS, credential, local/shared literal, rendering, referrer, and
   response-processing behavior.
4. Add mutation-sensitive executable and static contracts without claiming DNS
   peer binding.

## Requirements

- Accept `URL.port` only when it is empty or `443`.
- Reject representative low, HTTP, adjacent, alternate TLS, and high ports.
- Accept implicit HTTPS and explicit `:443`, preserving normalized `url.href`.
- Apply the port check before a thumbnail URL becomes renderable.
- Synchronize maintained guidance and completed plan evidence.
- Keep repository-root and external-directory verification equivalent.

## Implementation Units

### 1. Enforce the HTTPS authority

**File:** `src/components/Photos.jsx`

Extend thumbnail normalization with a default-port check after protocol and
credential validation and before host classification.

### 2. Add executable and static regressions

**Files:** `src/App.test.jsx`, `scripts/check-baseline.sh`

Cover implicit and explicit default-port acceptance, nondefault rejection, the
source condition, named tests, guidance, and completed-plan evidence.

### 3. Synchronize guidance

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
and this plan.

Document that API-provided thumbnails are limited to ordinary HTTPS port 443
and that browser code still cannot inspect DNS answers or the connected peer.

## Verification

- Demonstrate that a nondefault HTTPS thumbnail currently renders.
- Run focused thumbnail authority cases and the complete Vitest suite.
- Run repository-root and external-directory `make check`.
- Reject isolated source, explicit-443, nondefault-port, guidance, and reopened
  plan mutations.
- Audit exact paths, generated artifacts, conflict markers, file modes,
  dependency/workflow drift, whitespace, and credential-shaped additions.

## Risks

- URL normalization removes an explicit `:443`; tests must assert the
  normalized result rather than preserving source spelling.
- The fixed JSONPlaceholder endpoint controls response data but not browser DNS
  resolution; this change reduces authority scope without claiming DNS pinning.
- This PR is stacked on PR #15 and must retain base-first merge ordering.

## Out Of Scope

- DNS resolution, rebinding prevention, connected-peer inspection, CSP,
  hostname allowlists, proxies, and service workers.
- API endpoint, response handling, photo schema, render count, UI, dependency,
  Vite, React, or workflow changes.
- Browser deployment and live thumbnail delivery.
