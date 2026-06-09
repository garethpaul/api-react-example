# API React Example Changes

## 2026-06-09

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
