# Reject NAT64-Embedded Blocked IPv4 Thumbnail Literals

Status: Completed

## Problem

The thumbnail URL policy rejects blocked IPv4 literals and rejects the
non-global local-use NAT64 prefix `64:ff9b:1::/48`, but it still accepted
well-known NAT64 literals in `64:ff9b::/96` when their final 32 bits encoded
blocked IPv4 addresses. A backend response could therefore render an image for
`https://[64:ff9b::c0a8:101]/thumbnail.jpg`, which embeds `192.168.1.1`.

## Requirements

- Preserve well-known NAT64 literals that embed public IPv4 addresses.
- Reject well-known NAT64 literals that embed IPv4 addresses already blocked by
  the literal IPv4 policy: unspecified, private, shared, loopback, link-local,
  multicast, or reserved future-use ranges.
- Keep the check syntactic and browser-only; do not add DNS or connected-peer
  inspection.
- Make the source helper, blocked fixtures, accepted public control, guidance,
  and completion evidence visible to the repository baseline checker.

## Implementation

- Decode the last 32 bits of `64:ff9b::/96` literals in
  `src/components/Photos.jsx` and reuse the existing IPv4 blocklist.
- Add table-driven Vitest coverage for private, shared, loopback, multicast,
  and reserved embedded IPv4 values while preserving the existing public NAT64
  acceptance control.
- Update maintained security guidance and static baseline checks.

## Verification

- Before implementation, the focused well-known NAT64 embedded IPv4 regression
  failed because the component rendered images for the blocked literals.
- After implementation, the focused well-known NAT64 matrix passed 6 blocked
  cases.
- Full repository verification is recorded in the landing review.

## Scope Boundaries

- Do not block `64:ff9b::/96` wholesale.
- Do not add DNS resolution, connected-peer inspection, proxying, or network
  dependencies.
