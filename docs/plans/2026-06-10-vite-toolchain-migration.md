# Vite Toolchain Migration

Status: Completed

## Goal

Replace the deprecated Create React App dependency tree with a supported,
auditable frontend toolchain while preserving the photo-list behavior and its
existing component contracts.

## Requirements

- Preserve all 15 photo loading, validation, rendering, and unmount tests.
- Replace `react-scripts` with Vite and Vitest on Node.js 20.19 or newer.
- Upgrade React and React DOM to the current supported major release.
- Keep lint, formatting, tests, build, and repository contracts behind
  `make check`.
- Add hosted CI on Node 20, 22, and 24 with immutable action pins, read-only
  permissions, a bounded timeout, manual dispatch, a frozen lockfile install,
  and the shared verification command.
- Remove obsolete Create React App entry and service-worker files.
- Keep the production bundle compatible with the documented browser baseline
  and avoid runtime dependence on a third-party stylesheet CDN.

## Implementation

- Add root `index.html`, `vite.config.js`, and `eslint.config.js`.
- Replace the blocked Bootstrap CDN stylesheet with local gallery styles.
- Rename JSX-bearing source files from `.js` to standard `.jsx` extensions.
- Use Vitest's jsdom environment and jest-dom integration for component tests.
- Replace Jest mock helpers with Vitest equivalents.
- Pin React 19, Vite 8, Vitest 4, ESLint, Prettier, and testing dependencies.
- Resolve nested `debug` consumers to the patched 4.4.3 release.
- Extend `scripts/check-baseline.sh` to protect the new toolchain and CI
  contracts.

## Verification

- `corepack yarn install --frozen-lockfile`
- `make check`
- `corepack yarn audit --json`
- 15 Vitest component tests pass and the direct dependency set is current.
- `git diff --check`
