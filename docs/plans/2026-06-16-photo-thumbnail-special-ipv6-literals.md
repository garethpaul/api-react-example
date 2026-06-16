# Reject Non-Global Special-Purpose IPv6 Thumbnail Literals

Status: Planned

## Problem

Backend-provided thumbnail URLs are normalized by the browser and rejected
when they explicitly target known local, private, link-local, multicast,
unspecified, shared, or reserved IPv4/IPv6 literals. The IPv6 predicate still
accepts several address blocks that IANA identifies as non-global or that the
IPv6 address-space registry marks deprecated, including documentation,
benchmarking, discard-only, dummy-prefix, SRv6 SID, and site-local literals.
For example, `https://[2001:db8::1]/thumbnail.jpg` currently reaches image
rendering even though the documentation prefix is not a public thumbnail
destination.

## Priorities

1. P0: Prevent backend data from creating image requests to selected
   non-global or deprecated special-purpose IPv6 literals.
2. P1: Preserve ordinary public IPv6 literals and special-purpose addresses
   that the selected policy does not classify as blocked.
3. P1: Keep the boundary deterministic, client-side, and mutation-sensitive.

## Requirements

- R1. Reject normalized literals in `100::/64` (discard-only),
  `100:0:0:1::/64` (dummy prefix), `2001:2::/48` (benchmarking),
  `2001:db8::/32` and `3fff::/20` (documentation), `5f00::/16`
  (SRv6 SIDs), and `fec0::/10` (deprecated site-local).
- R2. Match IPv6 prefixes numerically after WHATWG URL canonicalization rather
  than relying on textual abbreviation shape.
- R3. Preserve accepted public IPv6 literals and existing HTTPS, credential,
  port, localhost, IPv4, IPv4-mapped, and DNS-style hostname behavior.
- R4. Document that this remains a literal-address check and cannot inspect
  DNS answers or the connected peer.
- R5. Protect source integration, behavioral fixtures, maintained guidance,
  and completed verification evidence with the portable baseline checker.

## Key Technical Decisions

- Parse the canonical bracketed IPv6 hostname into eight numeric hextets and
  compare selected prefixes by prefix length. URL parsing already canonicalizes
  compressed and embedded-IPv4 spellings before this boundary runs.
- Use an explicit selected-prefix table containing only the CIDRs named in R1
  rather than blocking the entire IANA special-purpose registry. Some
  special-purpose ranges remain globally reachable or intentionally routable,
  and a browser-side sample should not invent a broader routing policy.
- Retain DNS-style hosts. Browser JavaScript cannot authoritatively inspect DNS
  resolution or the connected address, so DNS rebinding remains an explicit
  limitation rather than a claim this change cannot enforce.

## Implementation Units

### U1. Numeric IPv6 Prefix Boundary

**Goal:** Reject the selected non-global or deprecated special-purpose IPv6
literal ranges after URL normalization.

**Files:** `src/components/Photos.jsx`

**Approach:** Add a small canonical IPv6 parser and prefix matcher, then extend
the existing literal predicate with the selected registry-backed ranges. Keep
IPv4-mapped handling and existing local/non-unicast checks intact.

**Test scenarios:**

- A documentation literal such as `2001:db8::1` is rejected.
- Lower and upper addresses inside each selected prefix are rejected.
- Addresses immediately outside each selected prefix remain accepted by this
  syntactic policy, without claiming those boundary fixtures are publicly
  routable.
- A known ordinary public IPv6 literal continues to render.
- Compressed canonical spellings and full-width spellings produce the same
  decision.

### U2. Behavioral Regression Matrix

**Goal:** Prove the selected ranges fail before image rendering without
weakening accepted-address coverage.

**Files:** `src/App.test.jsx`

**Approach:** Add table-driven blocked fixtures for the exact CIDRs in R1, plus
out-of-policy boundary fixtures that make prefix-length mutations observable
and a known public IPv6 fixture that protects ordinary rendering behavior.

**Test scenarios:**

- Every blocked fixture renders the existing error state and no image.
- Every out-of-policy boundary fixture remains accepted by this selected-prefix
  policy, and the known public fixture renders a normalized image URL.
- Existing public IPv4, IPv6, IPv4-mapped, and DNS-style cases remain green.

### U3. Contracts And Maintained Guidance

**Goal:** Keep the boundary and its verification durable.

**Files:** `scripts/check-baseline.sh`, `AGENTS.md`, `README.md`, `SECURITY.md`,
`VISION.md`, `CHANGES.md`, and this plan

**Approach:** Require the numeric prefix integration, representative blocked
and accepted fixtures, maintained literal-boundary guidance, completed plan
status, and truthful verification evidence.

**Test scenarios:**

- Removing a selected prefix, broadening its prefix length, or removing an
  accepted adjacent fixture fails focused tests or the baseline checker.
- Removing maintained guidance or reopening the plan status fails the portable
  baseline checker.

## Scope Boundaries

- Do not add DNS resolution, proxying, service workers, or a backend image
  fetcher.
- Do not reject every IANA special-purpose IPv6 entry; preserve entries outside
  the selected non-global/deprecated policy.
- Do not change API response parsing, request ownership, response streaming,
  photo limits, rendering markup, or referrer policy.
- Do not merge or close stacked pull requests without explicit authorization.

## Verification

- Preserve the pre-change reproduction that accepts a documentation literal.
- Run focused thumbnail literal regressions and the complete Vitest suite.
- Run ESLint, Prettier, the production Vite build, dependency audit, and
  repository-root and external-directory `make check` with explicit timeouts.
- Reject isolated hostile mutations across prefix data, prefix length,
  behavioral fixtures, maintained guidance, and plan completion evidence.
- Audit the exact diff, generated artifacts, credential-shaped additions,
  dependency/workflow drift, conflict markers, modes, and whitespace.

## Risks And Dependencies

- WHATWG URL canonicalization remains part of the parsing boundary; regression
  fixtures must cover compressed and canonical spellings.
- The selected IANA ranges can evolve. Baseline contracts protect the intended
  policy, while future registry changes should be handled in a separate
  reviewed update rather than silently expanding this change.
- DNS rebinding remains outside this client-only syntactic check.

## Sources And Research

- IANA IPv6 Special-Purpose Address Space registry, last updated October 9,
  2025: `https://www.iana.org/assignments/iana-ipv6-special-registry`
- IANA IPv6 Address Space registry for deprecated site-local space:
  `https://www.iana.org/assignments/ipv6-address-space`
