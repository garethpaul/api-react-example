---
title: API React Example Baseline Guard
type: chore
status: completed
date: 2026-06-08
---

# API React Example Baseline Guard

## Summary

Add a small source baseline guard to the React photo-list sample and extend test
coverage to the non-OK HTTP response path.

---

## Problem Frame

The prior React 18 / CRA 5 pass added meaningful fetch tests, HTTPS endpoint
usage, and quality-gate documentation. A future edit could still drift back to a
dynamic or insecure baseline without a fast source check, and the component's
explicit `!response.ok` branch did not have direct test coverage.

---

## Requirements

- R1. `yarn verify` must run a source baseline check before tests and build.
- R2. The guard must fail if `package-lock.json`, tracked `node_modules/`, or tracked `build/` artifacts appear.
- R3. The guard must enforce React 18 / React DOM 18 / CRA 5 pins.
- R4. The guard must preserve the HTTPS photo endpoint, `componentDidMount`, loading status role, and error alert role.
- R5. Tests must cover rejected fetches and non-OK HTTP responses without network access.
- R6. README must document the source baseline check.

---

## Key Technical Decisions

- **Use POSIX shell:** A small `scripts/check-baseline.sh` avoids adding more dependencies to a CRA project.
- **Keep verify simple:** Running the guard before the existing Jest/build sequence catches source drift quickly.
- **Test behavior, not implementation:** The non-OK response test asserts the user-facing alert instead of internal error text.

---

## Scope Boundaries

- This pass does not migrate from CRA to Vite.
- This pass does not change the visual design, endpoint behavior, or React component structure.
- This pass does not attempt to resolve the remaining CRA audit findings.

---

## Implementation Units

### U1. Add Source Baseline Guard

- **Goal:** Protect the established React 18 / CRA 5 photo-list baseline.
- **Files:** `scripts/check-baseline.sh`, `package.json`, `README.md`
- **Patterns:** POSIX shell checks for dependency pins, generated artifact tracking, endpoint/lifecycle roles, and verify wiring.
- **Verification:** `sh scripts/check-baseline.sh`, `corepack yarn verify`

### U2. Cover Non-OK Responses

- **Goal:** Exercise the explicit HTTP status error branch.
- **Files:** `src/App.test.js`
- **Patterns:** Mock `fetch` with `{ ok: false, status: 500 }` and assert the alert state.
- **Verification:** `CI=true corepack yarn test --watchAll=false`

---

## Risks & Dependencies

- The remaining audit findings are still tied to CRA 5 and should be addressed by a future build-tool migration.
- The guard is intentionally source-based and does not replace runtime/browser verification.

---

## Sources / Research

- `src/components/Photos.js` contains the fetch lifecycle and render states.
- `src/App.test.js` already mocks successful and rejected fetches.
- `package.json` exposes the existing `verify` script.
