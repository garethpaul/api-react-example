# API React Example Changes

## 2026-06-26 14:29 PDT - P1 - Make verification invocation authoritative

### Summary

Closed a false-green verification boundary where a later Makefile or unsafe
GNU Make mode could report a passing `check` without executing the reviewed
Node, lint, component-test, or production-build graph.

### Work completed

- Converted public verification targets to guarded double-colon rules.
- Rejected startup/later Makefiles, caller invocation variables, and ten
  non-executing or error-ignoring modes.
- Fixed shell, Node, Corepack/Yarn, and repository-root ownership inside the
  reviewed Makefile.
- Added 24 causal authority cases, external-root coverage, and hostile checkout
  path coverage.

### Threads

- None; the focused Make, shell-test, baseline, and documentation work was
  completed directly.

### Files changed

- `Makefile` — authoritative invocation and guarded repository recipes.
- `scripts/test-makefile-authority.sh` — causal replacement, mode, override,
  external-root, and hostile-path regressions.
- `scripts/check-baseline.sh` — structural authority and plan contracts.
- `README.md`, `VISION.md`, `AGENTS.md`,
  `docs/plans/2026-06-26-make-invocation-authority.md` — public boundary and
  verification evidence.

### Validation

- `/bin/sh scripts/test-makefile-authority.sh` — 24 authority cases passed.
- `/bin/sh scripts/check-baseline.sh` — passed.
- Node 20.20.2, 22.16.0, and 24.17.0 `make check` — passed with 77
  workflow-policy tests, dependency-policy mutations, lint, format, 128
  component tests, and production builds.
- Absolute external-directory Make verification — passed on Node 20.20.2.
- Hosted Node 20/22/24 Check run `28266447712` and CodeQL run
  `28266439237` — passed on the initial PR head.

### Bugs / findings

- P1 fixed: a later single-colon Makefile replaced every leaf recipe and exited
  zero; `make -n check` also exited zero without executing verification.

### Blockers

- The host default was unsupported Node 18 without Corepack; validation used
  the installed supported Node 20/22/24 toolchains.
- Codex review was attempted once and skipped after HTTP 401 authentication
  failures, as permitted by the maintenance workflow.

### Next action

- Merge only after all hosted Node and CodeQL checks pass on the exact final
  head.

- Backend-provided thumbnail URLs cannot explicitly target localhost, loopback, private, link-local, or unspecified IP literals before rendering; DNS-style hosts are not resolved by this syntactic check.
- Backend-provided thumbnail URLs cannot explicitly target IPv4 shared address space before rendering.
- Backend-provided thumbnail URLs reject multicast and reserved future-use IP literals before rendering.
- Backend-provided thumbnail URLs reject selected non-global and deprecated special-purpose IPv6 literals before rendering.
- Backend-provided thumbnail URLs reject the non-global local-use NAT64 prefix `64:ff9b:1::/48` and blocked IPv4 addresses embedded in the well-known `64:ff9b::/96` prefix while preserving well-known NAT64 literals that embed public IPv4 addresses.
- Backend-provided thumbnail URLs use only the default HTTPS port before rendering; browser code cannot inspect DNS answers or the connected peer.
- Expired photo requests cancel late fetch responses before response metadata or stream access.

## 2026-06-26

- Rejected photo titles containing only Unicode format or combining-mark
  characters before they can render blank headings and image alternatives.
- Added component regressions for invisible-only titles while preserving
  decomposed visible text and emoji sequences.
- Added static, guidance, and completed-plan contracts for the visible-title
  boundary.

## 2026-06-19

- Replaced textual workflow checks with a semantic policy that preserves the
  canonical Node matrix, recursively inspects local workflow delegation,
  rejects remote reusable workflows and advanced CodeQL actions, and allows
  narrowly permissioned third-party SARIF uploads.
- Restricted executable jobs to the pinned GitHub-hosted runner, rejected
  `pull_request_target`, containers, services, environments, and inherited
  reusable-workflow secrets, and ignored nested YAML that GitHub does not load
  as workflows.

## 2026-06-15

- Upgraded the exactly pinned development checks to ESLint 10.5.0 and
  Vitest 4.1.9 while preserving the complete lint, component-test, and build
  gates.
- Malformed and unsafe-range photo Content-Length declarations cancel unread bodies before preserving validation errors.
- Oversized and unstreamable photo response envelopes cancel unread bodies
  before preserving their deterministic validation failures.

## 2026-06-14

- Pre-read photo response rejection initiates best-effort body cancellation
  without replacing status, redirect, or media-type validation errors.
- Required a readable byte stream for photo responses and rejected allocating
  whole-body fallbacks that cannot enforce the 2 MiB ceiling in advance.
- Rejected malformed and zero-length photo stream chunks before bounded buffer
  writes, with best-effort reader cancellation.
- Photo requests reject redirects before response parsing so the fixed endpoint
  cannot silently transfer response trust to another origin.

## 2026-06-13

- Cancel pending response readers on timeout and unmount, including browsers
  without `AbortController` support.
- Replaced per-chunk photo stream retention with one contiguous bounded buffer,
  preserving exact-limit parsing and overflow cancellation.
- Added a 2 MiB photo response body limit with streamed cancellation, fallback
  byte checks, and strict UTF-8 decoding before JSON parsing.
- Required successful photo responses to declare `application/json` or an
  `application/*+json` media type before body parsing.
- Added deterministic coverage for missing, HTML, parameterized, and structured
  suffix JSON content types.

## 2026-06-12

- Documented the existing GitHub CodeQL default setup for GitHub Actions and
  JavaScript/TypeScript, and rejected a duplicate advanced workflow that
  conflicts with the repository setting.
- Added lazy thumbnail loading and a no-referrer image policy so arbitrary
  thumbnail hosts do not receive the application page URL.

## 2026-06-10

- Added a 10-second photo request timeout that aborts when supported, renders
  the existing error state, and clears timers on success or unmount.
- Scoped photo timers, abort controllers, completion, and cleanup to request
  identity so a Strict Mode remount cannot let stale work replace current state.
- Added fake-timer timeout coverage, made Make targets location-independent,
  and pinned CI to Ubuntu 24.04 with superseded-run cancellation.
- Replaced deprecated Create React App with Vite 8 and Vitest 4.
- Upgraded React and React DOM to 19.2.7 while preserving the existing photo
  rendering and validation behavior.
- Added explicit ESLint and Prettier tooling plus a pinned, least-privilege
  GitHub Actions verification workflow on Node 20, 22, and 24.
- Removed the unused Create React App service-worker helper and template entry.
- Replaced the blocked Bootstrap CDN stylesheet with local responsive gallery
  styles and set a browser-compatible production target.
- Replaced the vulnerable 1,512-package Create React App dependency graph with
  a directly managed supported frontend toolchain and pinned the remaining
  nested `debug` dependency to its patched release.

## 2026-06-09

- Aborted pending photo fetches on component unmount when `AbortController` is
  available.
- Rejected credential-bearing HTTPS thumbnail URLs before rendering photo cards.
- Required API photo IDs to be non-empty strings or finite numbers before
  normalizing them for React keys.
- Added an unmount guard around pending photo loads so late API responses do
  not call `setState` after the component has left the tree.
- Rejected duplicate API photo IDs before rendering so React keys remain stable
  and repeated records use the existing error state.
- Normalized accepted photo render fields so titles are trimmed and thumbnail
  URLs are canonicalized before they reach headings, alt text, and image srcs.
- Required photo thumbnail URLs to parse as HTTPS before rendering, with test
  and source-baseline coverage for insecure URLs.
- Added photo item shape validation so malformed records use the existing error
  state instead of rendering broken cards.
- Added component and source-baseline coverage for missing photo render fields.
- Documented the photo record rendering contract in the README and vision.

## 2026-06-08

- Added `make check` as the root wrapper for the React source baseline, lint,
  tests, and production build.
- Added photo API response normalization so non-array responses render the
  existing error state and large responses are capped before rendering.
- Added an explicit ESLint gate for the React source tree and wired it into `verify`.
- Updated the README verification flow to use Corepack-backed Yarn with the checked-in `yarn.lock`.
- Extended the source baseline check to guard the lint script, changelog, and documented verification commands.
