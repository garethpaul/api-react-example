## API React Example Vision

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
- Keep the app small enough for beginners to inspect

Next priorities:

- Update tests so they assert the actual photo-list behavior
- Replace deprecated lifecycle usage with modern React patterns
- Move API configuration and error handling into clearer boundaries
- Keep dependencies current enough to install on supported Node versions

Contribution rules:

- One PR = one focused React, API, or tooling improvement.
- Run `yarn test` and `yarn build` before pushing behavior changes.
- Keep examples dependency-light unless a package teaches a clear concept.
- Update docs when scripts, API endpoints, or runtime expectations change.

## Security And Privacy

This sample fetches public placeholder data. Do not add private API keys,
credentials, or user-specific endpoints directly to source code.

Future API examples should prefer HTTPS endpoints and make failure behavior
visible to users and tests.

## What We Will Not Merge For Now

- Production app claims that are not supported by tests and configuration
- API integrations requiring committed secrets
- Framework rewrites that obscure the basic React data-loading lesson
- Test removals without replacement coverage for rendered behavior
