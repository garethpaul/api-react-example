# API React Example Lint Gate

## Goal

Add an explicit lint command to the React photo-list sample so the documented verification flow includes source checks, tests, and production build.

## Scope

- Keep the existing React 18 and Create React App 5 dependency baseline.
- Keep Yarn v1 as the lockfile source of truth through Corepack.
- Reuse the existing CRA ESLint configuration instead of adding a new formatter or lint stack.
- Document and enforce the updated verification commands.

## Verification

- `sh scripts/check-baseline.sh`
- `corepack yarn lint`
- `CI=true corepack yarn test --watchAll=false`
- `corepack yarn build`
- `corepack yarn verify`
