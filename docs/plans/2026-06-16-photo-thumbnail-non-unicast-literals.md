# Photo Thumbnail Non-Unicast Literal Boundary

## Status: Planned

## Problem

API-provided thumbnail URLs are rendered by the browser after HTTPS,
credential, default-port, localhost, private, link-local, loopback, and shared
literal-address checks. The current IPv4 policy still accepts multicast
(`224.0.0.0/4`) and reserved future-use (`240.0.0.0/4`) literals, while the
IPv6 policy accepts multicast (`ff00::/8`) literals. These are not valid public
unicast thumbnail destinations and can make a browser issue unintended network
requests when a response controls `thumbnailUrl`.

## Requirements

- Reject IPv4 multicast and reserved future-use thumbnail address literals.
- Reject IPv6 multicast thumbnail address literals.
- Preserve existing rejection of local, private, link-local, loopback, shared,
  credentialed, non-HTTPS, and alternate-port URLs.
- Preserve accepted public IPv4, public IPv6, and DNS-style HTTPS thumbnail
  URLs.
- Keep the boundary fully client-side and explicitly retain DNS rebinding as a
  browser visibility limitation.
- Add mutation-sensitive behavioral and static contracts plus completed
  verification evidence.

## Scope Boundaries

- Do not add DNS resolution, proxying, service workers, or a backend image
  fetcher.
- Do not block documentation, benchmarking, or other non-global ranges unless
  they are part of the selected multicast or reserved future-use boundaries.
- Do not change API response parsing, photo limits, rendering markup, or
  referrer policy.
- Do not merge or close stacked pull requests without explicit authorization.

## Technical Design

- Extend the existing numeric IPv4 predicate in `src/components/Photos.jsx`
  with the multicast and reserved ranges.
- Extend the bracketed IPv6 predicate with the multicast prefix range.
- Add table-driven rendering regressions in `src/App.test.jsx` for lower and
  upper boundaries, plus adjacent accepted public literals.
- Register exact source, test, documentation, and completed-plan contracts in
  `scripts/check-baseline.sh`.
- Update `README.md`, `SECURITY.md`, and `CHANGES.md` with the enforceable
  non-unicast literal boundary and the remaining DNS limitation.

## Implementation Units

### Literal-address policy

- **Files:** `src/components/Photos.jsx`
- Reject IPv4 multicast/reserved and IPv6 multicast literals without changing
  normalized public URL output.

### Behavioral regressions

- **Files:** `src/App.test.jsx`
- Prove selected blocked boundaries fail the photo response and adjacent public
  literals still render.

### Contracts and guidance

- **Files:** `scripts/check-baseline.sh`, `README.md`, `SECURITY.md`,
  `CHANGES.md`, this plan
- Protect the source and tests, explain the boundary, and record truthful final
  verification.

## Verification Planned

- Focused Vitest cases for blocked and accepted literal boundaries.
- Repository-root and external-directory `make check`.
- Isolated hostile mutations for each source range, blocked and accepted test
  fixtures, guidance, and completed plan status.
- Exact diff, generated-artifact, untracked-file, dependency/workflow drift,
  file-mode, credential-pattern, conflict-marker, and whitespace audits.

## Risks

- Browser JavaScript still cannot inspect DNS answers or the connected peer;
  DNS rebinding remains outside this client-only policy.
- Literal-address parsing depends on WHATWG URL canonicalization before these
  numeric checks run.

## Assumptions

- Thumbnails are expected to come from public unicast HTTPS destinations.
- Existing API response rejection is the correct behavior when any photo
  record contains an invalid thumbnail URL.
