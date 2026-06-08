# Photo Response Normalization

## Goal

Keep the photo list resilient when the API returns an unexpected shape or a very
large array.

## Red

- Added tests for non-array photo responses and large API responses.
- Confirmed `CI=true corepack yarn test --watchAll=false` failed because a
  non-array response reached `photos.map`, and because no `MAX_PHOTOS` cap was
  exported.

## Green

- Added `MAX_PHOTOS` and `normalizePhotos` in `Photos.js`.
- Non-array responses now throw inside the existing load/catch path and render
  the existing alert state.
- Large arrays are sliced before entering component state.
- Extended `scripts/check-baseline.sh` to require the normalizer and tests.

## Verification

- `sh scripts/check-baseline.sh`
- `corepack yarn lint`
- `CI=true corepack yarn test --watchAll=false`
- `corepack yarn build`
- `corepack yarn verify`
- `git diff --check`
