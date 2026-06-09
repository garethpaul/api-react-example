# Photo Record Shape Validation

## Status: Completed

## Goal

Keep malformed photo records from reaching the rendered card list so missing
titles, ids, or thumbnail URLs use the existing error state instead of creating
broken UI.

## Scope

- Validate each API photo item before slicing the render list.
- Require usable `id`, `title`, and `thumbnailUrl` fields for rendered cards.
- Add Jest coverage for malformed photo items.
- Extend the source baseline guard and docs for the item-shape contract.

## Out Of Scope

- Changing the JSONPlaceholder endpoint.
- Filtering partial responses into a best-effort list.
- Redesigning the photo cards or migrating away from Create React App.

## Verification

- `make check`
- `sh scripts/check-baseline.sh`
- `corepack yarn lint`
- `CI=true corepack yarn test --watchAll=false`
- `corepack yarn build`
- `corepack yarn verify`
- `git diff --check`
