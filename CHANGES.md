# API React Example Changes

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
