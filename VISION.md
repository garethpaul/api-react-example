## API React Example Vision

This document explains the current state and direction of the project.
Project overview and developer docs: [`README.md`](README.md)

API React Example is a small Create React App project that renders a photo list
from the JSONPlaceholder photos API.

The repository is useful as a simple React API-fetching example with component
state, remote JSON data, and a standard CRA toolchain. Setup and script notes
live in [`README.md`](README.md).

The goal is to keep the sample easy to run, easy to understand, and useful for
learning how a React component loads and renders API data.

The current focus is:

Priority:

- Preserve the `Photos` component as the central API example
- Keep `yarn start`, `yarn test`, and `yarn build` usable
- Make network assumptions visible instead of hidden in component code
- Require successful API responses to identify JSON content before parsing
- Enforce a 2 MiB photo response body limit before JSON parsing
- Validate API item shape before rendering photo cards
- Render only HTTPS thumbnail URLs from the API response
- Reject thumbnail URLs with embedded credentials before DOM rendering
- Normalize accepted API fields before using them in visible photo cards
- Reject duplicate API photo IDs before React key rendering
- Require photo IDs to be key-safe string or finite number values
- Avoid state updates from pending API loads after unmount
- Abort pending photo loads after unmount when the browser supports it
- Bound photo requests so stalled endpoints cannot leave the UI loading forever
- Keep photo request completion and cleanup owned by the latest mounted request
- Keep the app small enough for beginners to inspect
- Keep CodeQL default-setup coverage for workflow and JavaScript trust boundaries

Next priorities:

- Keep tests aligned with the actual photo-list behavior
- Consider modern React patterns in a dedicated refactor
- Move API configuration and error handling into clearer boundaries
- Keep dependencies current enough to install on supported Node versions

Contribution rules:

- One PR = one focused React, API, or tooling improvement.
- Run `yarn test` and `yarn build` before pushing behavior changes.
- Keep examples dependency-light unless a package teaches a clear concept.
- Update docs when scripts, API endpoints, or runtime expectations change.

## Security And Privacy

Canonical security policy and reporting:

- [`SECURITY.md`](SECURITY.md)

This sample fetches public placeholder data. Do not add private API keys,
credentials, or user-specific endpoints directly to source code.

Future API examples should prefer HTTPS endpoints and make failure behavior
visible to users and tests.
Rendered media URLs should be validated before they are placed in the DOM.

## What We Will Not Merge (For Now)

- Production app claims that are not supported by tests and configuration
- API integrations requiring committed secrets
- Framework rewrites that obscure the basic React data-loading lesson
- Test removals without replacement coverage for rendered behavior

This list is a roadmap guardrail, not a permanent rule.
Strong user demand and strong technical rationale can change it.
