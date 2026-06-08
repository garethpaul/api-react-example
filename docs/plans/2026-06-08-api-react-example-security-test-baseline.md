---
title: API React Example Security and Test Baseline
type: chore
status: completed
date: 2026-06-08
---

# API React Example Security and Test Baseline

## Summary

Raise the engineering bar for the Create React App photo-list sample by reducing the vulnerable dependency tree, replacing deprecated React lifecycle usage, and adding deterministic tests for loading, rendering, and fetch error states.

## Problem Frame

The project is still on React 16 and `react-scripts` 3.4.1. `corepack yarn audit --json` on 2026-06-08 reports 723 advisories across the dependency tree: 63 critical, 336 high, 254 moderate, and 70 low. The only test still expects the default CRA "learn react" text even though the app renders the photo list component, so the existing test gate is not meaningful. The component also fetches data in `componentWillMount`, uses insecure `http://` for the placeholder API, omits list keys, and uses `class` instead of `className` in JSX.

## Requirements

- R1. Upgrade the project to a safer maintained baseline without ejecting CRA.
- R2. Keep Yarn v1 as the package manager and update `yarn.lock`; do not introduce `package-lock.json`.
- R3. Replace deprecated `componentWillMount` data fetching with a supported lifecycle or hook.
- R4. Use HTTPS for the JSONPlaceholder photo endpoint.
- R5. Render loading, loaded, and error states deterministically.
- R6. Component tests must run without network access by mocking `fetch`.
- R7. The app-level test must assert the actual rendered UI rather than the removed CRA starter text.
- R8. Local quality gates must run in CI mode and include tests, production build, and audit reporting.
- R9. Documentation must explain Corepack/Yarn setup, verification commands, and any remaining audit limitations.

## Key Technical Decisions

- **Modernize conservatively to React 18 and CRA 5:** React 19 is current, but CRA is no longer the right route for a React 19 migration. React 18 with `react-scripts` 5.0.1 materially reduces the vulnerable tree while keeping the app inside its existing framework.
- **Keep a class component:** The app already uses a class component; moving fetch logic to `componentDidMount` is the smallest behavior-preserving change.
- **Mock `fetch` in Jest:** Tests should assert states and rendered photo cards without relying on JSONPlaceholder availability.
- **Use Corepack-backed Yarn:** The host does not have a standalone `yarn` binary, but Node 20 provides Corepack and can run Yarn 1.22.22.
- **Treat audit as a report gate:** CRA 5 may still carry advisories. This pass must reduce the current audit surface and document any residual issues instead of claiming a complete framework migration.

## Scope Boundaries

- This pass does not eject Create React App.
- This pass does not migrate to Vite or another modern React build tool.
- This pass does not migrate to React 19.
- This pass does not redesign the UI beyond basic loading/error states and valid JSX.
- This pass does not add live browser automation.

## Implementation Units

### U1. Dependency Refresh

- **Goal:** Move from CRA 3 / React 16 to CRA 5 / React 18 while preserving Yarn v1.
- **Files:** `package.json`, `yarn.lock`
- **Patterns:** Use `corepack yarn add` so lockfile resolution is deterministic; add a `verify` script that runs tests and build in CI mode.
- **Test Scenarios:**
  - `package.json` uses React 18, React DOM 18, `react-scripts` 5.0.1, and compatible Testing Library versions.
  - No `package-lock.json` is created.
  - `corepack yarn audit --json` reports a lower advisory count than the current 723 total.
- **Verification:** `corepack yarn install --frozen-lockfile`, `corepack yarn audit --json`

### U2. Fetch Lifecycle and Render States

- **Goal:** Make the photo list component valid, testable React code.
- **Files:** `src/components/Photos.js`
- **Patterns:** Fetch in `componentDidMount`; initialize `loading` and `error` state; render `className` and keyed cards.
- **Test Scenarios:**
  - Initial render shows a loading state.
  - Successful fetch renders returned photo titles and thumbnails.
  - Failed fetch renders an error state.
  - Component uses `https://jsonplaceholder.typicode.com/photos`.
- **Verification:** `CI=true corepack yarn test --watchAll=false`

### U3. App-Level Test Baseline

- **Goal:** Replace the stale CRA starter test with a meaningful app smoke test.
- **Files:** `src/App.test.js`, `src/setupTests.js`
- **Patterns:** Mock `global.fetch` in tests; use Testing Library async queries.
- **Test Scenarios:**
  - `App` renders the photo-list heading.
  - `App` renders fetched photo data without a real network call.
  - Jest setup uses the current jest-dom import path.
- **Verification:** `CI=true corepack yarn test --watchAll=false`

### U4. Documentation and Gate Wiring

- **Goal:** Make local verification and residual dependency risk explicit.
- **Files:** `README.md`, `package.json`
- **Patterns:** Keep the CRA generated reference concise; add a top-level quality-gates section.
- **Test Scenarios:**
  - README documents `corepack yarn install`, `CI=true corepack yarn test --watchAll=false`, `corepack yarn build`, and `corepack yarn audit --json`.
  - README notes that full React 19 / Vite migration is deferred follow-up work.
  - `package.json` exposes a `verify` script for tests and build.
- **Verification:** Manual README review plus test/build/audit commands.

## Risks & Dependencies

- CRA 5 can still report audit findings because CRA itself is no longer the long-term maintained baseline; residual advisories should become a future Vite/React 19 migration plan.
- React Testing Library major changes can require small test API updates.
- Production build may expose warnings from old CRA defaults or unsupported transitive packages under Node 20.

## Sources / Research

- `package.json` pins React 16.13.1, React DOM 16.13.1, and `react-scripts` 3.4.1.
- `yarn.lock` is the only lockfile; no `package-lock.json` exists.
- `src/components/Photos.js` fetches from `http://jsonplaceholder.typicode.com/photos` in `componentWillMount`.
- `src/App.test.js` still expects the default CRA "learn react" text.
- `corepack yarn audit --json` on 2026-06-08 reported 723 total advisories: 63 critical, 336 high, 254 moderate, and 70 low.
- `npm view react version` and `npm view react-dom version` on 2026-06-08 reported latest `19.2.7`.
- `npm view react-scripts version` on 2026-06-08 reported latest `5.0.1`.
- `corepack yarn --version` on 2026-06-08 reported `1.22.22`.
