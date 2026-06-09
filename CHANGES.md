# API React Example Changes

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
- Required photo thumbnail URLs to parse as HTTPS before rendering, with Jest
  and source-baseline coverage for insecure URLs.
- Added photo item shape validation so malformed records use the existing error
  state instead of rendering broken cards.
- Added Jest and source-baseline coverage for missing photo render fields.
- Documented the photo record rendering contract in the README and vision.

## 2026-06-08

- Added `make check` as the root wrapper for the React source baseline, lint,
  tests, and production build.
- Added photo API response normalization so non-array responses render the
  existing error state and large responses are capped before rendering.
- Added an explicit ESLint gate for the React source tree and wired it into `verify`.
- Updated the README verification flow to use Corepack-backed Yarn with the checked-in `yarn.lock`.
- Extended the source baseline check to guard the lint script, changelog, and documented verification commands.
