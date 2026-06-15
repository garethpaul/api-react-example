---
title: Reject Non-Public Thumbnail Address Literals
type: security
status: completed
date: 2026-06-15
---

# Reject Non-Public Thumbnail Address Literals

## Problem

The API controls `thumbnailUrl`, and accepted values become browser image
requests. The current normalizer requires HTTPS and rejects embedded
credentials, but it accepts explicit loopback, private, link-local, and
unspecified IP literals. A malformed or compromised response can therefore
make the browser request services on the viewer's own host or local network.

The WHATWG URL parser normalizes legacy one-to-four-part decimal, octal, and
hexadecimal IPv4 syntax before exposing `URL.hostname`. IANA identifies
loopback, private-use, link-local, unspecified, IPv6 unique-local, and mapped
address ranges as non-global or protocol-special boundaries. The policy can
therefore reject explicit address literals deterministically without resolving
DNS-style hosts.

Primary references:

- [WHATWG URL Standard](https://url.spec.whatwg.org/)
- [IANA IPv4 Special-Purpose Address Space](https://www.iana.org/assignments/iana-ipv4-special-registry)
- [IANA IPv6 Special-Purpose Address Space](https://www.iana.org/assignments/iana-ipv6-special-registry)

## Priorities

1. **P0 - Prevent explicit local-network image requests:** reject localhost
   names plus explicit IPv4/IPv6 loopback, private, link-local, and unspecified
   literals before rendering any image element.
2. **P1 - Preserve public compatibility:** continue accepting public IP
   literals, normal DNS-style HTTPS hosts, signed paths, query strings, and
   fragments while retaining credential and referrer protections.
3. **P2 - Durable evidence:** add executable and static mutation-sensitive
   coverage plus synchronized security guidance and completed-plan evidence.
4. **Follow-up - DNS-derived addresses:** treat hostname resolution, DNS
   rebinding, connection pinning, and backend proxy policy as a separate
   architecture task; this browser-only syntactic check must not claim them.

## Requirements

- Use the normalized `URL.hostname` value so legacy numeric IPv4 forms cannot
  bypass the policy.
- Strip one trailing DNS root dot, then reject exact and subdomain `localhost`
  names case-insensitively.
- Reject IPv4 `0/8`, `10/8`, `127/8`, `169.254/16`, `172.16/12`, and
  `192.168/16` literals.
- Reject IPv6 unspecified, loopback, unique-local, link-local, and IPv4-mapped
  forms of the blocked IPv4 ranges.
- Preserve public IPv4 and IPv6 literals and DNS-style hosts without DNS
  resolution.
- Preserve existing HTTPS, user-info, normalization, lazy-loading,
  no-referrer, record-shape, duplicate-ID, response, timeout, and request
  ownership behavior.

## Implementation Units

### U1: Explicit Host Boundary

**File:** `src/components/Photos.jsx`

Extend thumbnail URL normalization with small deterministic IPv4 and canonical
IPv6 literal predicates. Apply them only after successful WHATWG URL parsing
and before returning the normalized URL. Do not add a DNS lookup or dependency.

### U2: Rendering Regressions

**File:** `src/App.test.jsx`

Add focused component fixtures for exact, mixed-case, trailing-dot, and
subdomain localhost names; normalized legacy IPv4 aliases; private/link-local
IPv4; IPv6 loopback/unique-local/link-local; and mapped private IPv4 rejection.
Include public IPv4, public IPv6, and DNS-style acceptance controls and assert
rejected records never render image elements.

### U3: Portable Contracts And Guidance

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan.

Require the source masks, representative rejected and accepted fixtures,
synchronized scope language, completed status, and truthful verification
evidence. State explicitly that DNS-style hosts are not resolved by this
boundary.

## Verification

- Run focused thumbnail-host tests and the complete Vitest suite.
- Run ESLint, Prettier, production build, frozen Yarn installation, and the
  production dependency audit.
- Run repository-root and external-directory `make check`.
- Reject isolated hostile mutations for the host guard, IPv4 masks, IPv6
  categories, mapped-address handling, public controls, maintained guidance,
  and plan completion.
- Audit exact intended paths, generated artifacts, conflict markers,
  dependency/workflow drift, whitespace, and credential-shaped additions.
- Capture one bounded exact-head hosted snapshot after push; record pending
  state rather than polling when checks are not terminal.

## Completion Evidence

- Added `isBlockedThumbnailHost` after WHATWG URL parsing and credential checks,
  using normalized IPv4 values and canonical bracketed IPv6 syntax without DNS
  resolution or a new dependency.
- Added 34 focused rendering cases: 25 localhost/local-address rejections and
  9 public-IP or DNS-style acceptance controls. The complete suite passed all
  72 Vitest cases.
- Frozen Yarn installation, ESLint 10.5.0, Prettier, Vite production build,
  and the production dependency audit passed; the audit reported zero known
  vulnerabilities.
- Twenty-five hostile mutations were rejected: 12 runtime mutations covering
  complete guard removal, localhost, every IPv4 range, mapped IPv4, IPv6 local
  ranges, and public over-rejection; plus 5 static mutations covering source,
  blocked/public fixtures, guidance, and plan completion; plus 8 review
  mutations covering every upper boundary and mapped-public compatibility.
- Complete repository-root and external-directory `make check` gates passed in
  an exact-source disposable proof copy before the real plan status changed.
- The same complete root and external-directory gates passed again in the real
  worktree after review fixes.
- Exact nine-path diff, generated-artifact, conflict-marker, dependency and
  workflow drift, whitespace, and credential-shaped-addition audits passed.
- `agent-browser` was unavailable, so live browser automation was not run; the
  72 jsdom component tests are the rendered-behavior evidence for this change.
- No live endpoint, cross-browser, DNS, proxy, corporate-network, or browser
  automation execution was performed.

## Risks And Mitigations

- **False DNS claim:** operate only on parsed literal syntax and document that
  a DNS hostname can still resolve or rebind to a non-public address.
- **Parser inconsistency:** rely on WHATWG URL normalization already used by
  browsers and the Node/jsdom test environment, with legacy numeric fixtures.
- **Over-rejection:** keep public IPv4/IPv6 and ordinary DNS controls in the
  executable suite and static contracts.
- **Stacked delivery:** base the pull request on PR #13 and retain base-first
  ordering.

## Out Of Scope

- DNS resolution, DNS rebinding prevention, connection-address pinning,
  backend proxying, Content Security Policy changes, or hostname allowlists.
- Endpoint, response schema, stream parsing, byte limits, dependencies,
  workflows, React rendering layout, or toolchain changes.
- Live endpoint, cross-browser, proxy, corporate-network, or browser automation
  execution.
