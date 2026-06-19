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
- Backend-provided thumbnail URLs cannot explicitly target localhost, loopback, private, link-local, or unspecified IP literals before rendering; DNS-style hosts are not resolved by this syntactic check.
- Backend-provided thumbnail URLs cannot explicitly target IPv4 shared address space before rendering.
- Backend-provided thumbnail URLs reject multicast and reserved future-use IP literals before rendering.
- Backend-provided thumbnail URLs reject selected non-global and deprecated special-purpose IPv6 literals before rendering.
- Backend-provided thumbnail URLs reject the non-global local-use NAT64 prefix `64:ff9b:1::/48` and blocked IPv4 addresses embedded in the well-known `64:ff9b::/96` prefix while preserving well-known NAT64 literals that embed public IPv4 addresses.
- Backend-provided thumbnail URLs use only the default HTTPS port before rendering; browser code cannot inspect DNS answers or the connected peer.
- Accepted photo titles and thumbnail URLs are normalized before they are used in headings, alt text, and image sources.
- Photo IDs must be unique after React key coercion before cards are rendered.
- Each photo load owns its abort controller and timeout; only the active request may update state or clear request resources.
- Expired photo requests cancel late fetch responses before response metadata or stream access.
- Photo request timeout and unmount cleanup cancel pending response readers even
  when `AbortController` is unavailable.
- Photo response streams reject malformed or empty chunks before buffer writes
  and cancel the reader on validation failure.
- Photo requests reject redirects before response parsing so the fixed endpoint
  cannot silently transfer response trust to another origin.
- Enforce the 2 MiB photo response body limit on raw bytes before JSON parsing;
  stream into one contiguous bounded buffer, and cancel/release on overflow.
- Require a readable byte stream and reject whole-body fallbacks that cannot
  enforce the memory ceiling before allocation.
- Pre-read photo response rejection initiates best-effort body cancellation
  without replacing status, redirect, or media-type validation errors.
- Oversized and unstreamable photo response envelopes cancel unread bodies
  before deterministic validation errors are raised.
- Malformed and unsafe-range photo Content-Length declarations cancel unread bodies before preserving validation errors.
- Keep thumbnail requests lazy and use `referrerPolicy="no-referrer"` for arbitrary validated HTTPS hosts.

## Agent workflow

1. Inspect the README, Makefile, manifests, and the files directly related to the request.
2. Make the smallest source or docs change that satisfies the task; avoid generated, vendored, or local-environment files unless required.
3. Run the narrowest useful validation first, then `make check` or the documented package/platform gate when available.
4. If a required SDK, service credential, or external runtime is unavailable, record the skipped command and why.
5. Summarize changed files, commands run, and remaining risks or follow-up validation.
