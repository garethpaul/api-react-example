# AGENTS.md

## Repository purpose

`garethpaul/api-react-example` is a JavaScript web application or frontend sample. React API Sample

## Project structure

- `Makefile` - repository verification targets
- `scripts` - baseline checks and helper scripts
- `docs` - plans, notes, and generated README assets
- `src` - primary source code
- `package.json` - Node package metadata and scripts

## Development commands

- Install dependencies: `corepack yarn install`
- Full baseline: `make check`
- Combined verification: `make verify`
- Lint/static checks: `make lint`
- Tests: `make test`
- Build: `make build`
- package script `start`: `yarn start`
- package script `build`: `yarn build`
- package script `lint`: `yarn lint`
- package script `test`: `yarn test`
- package script `verify`: `yarn verify`
- If a command above skips because a platform toolchain is missing, verify on a machine with that SDK before claiming platform behavior is tested.

## Coding conventions

- Language mix noted in the README: JavaScript (6), shell (1).
- Use Node.js 20.19 or newer through Corepack-backed Yarn 1.22.22.
- The frontend toolchain is React 19 with Vite 8 and Vitest 4.
- ESLint and Prettier are configured explicitly rather than through Create React App.
- Keep React components controlled and covered by component tests when props or rendering behavior changes.

## Testing guidance

- Test-related files detected: `docs/plans/2026-06-08-api-react-example-security-test-baseline.md`, `src/App.test.jsx`, `src/setupTests.js`
- Start with the narrowest relevant test or Make target, then run `make check` before handing off if the change is not documentation-only.
- Keep README verification notes in sync when commands, fixtures, or supported toolchains change.

## PR / change guidance

- Keep diffs focused on the requested repository and avoid unrelated modernization or formatting churn.
- Preserve public APIs, sample behavior, file formats, and documented environment variables unless the task explicitly changes them.
- Update tests, README notes, or docs/plans when behavior, security posture, or validation commands change.
- Call out skipped platform validation, legacy toolchain assumptions, and any risky files touched in the final summary.

## Safety and gotchas

- No required secret or credential file was identified in the repository scan. If you add integrations later, keep secrets out of git.
- Photo records are validated before rendering; malformed items use the existing error state instead of creating broken cards.
- Thumbnail URLs must parse as HTTPS URLs before the app renders image elements.
- Thumbnail URLs with embedded credentials are rejected before image elements are rendered.
- Accepted photo titles and thumbnail URLs are normalized before they are used in headings, alt text, and image sources.
- Photo IDs must be unique after React key coercion before cards are rendered.
- Each photo load owns its abort controller and timeout; only the active request may update state or clear request resources.
- Keep thumbnail requests lazy and use `referrerPolicy="no-referrer"` for arbitrary validated HTTPS hosts.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
