# Photo Thumbnail Referrer Privacy

Status: Completed

## Context

Thumbnail URLs are validated as credential-free HTTPS URLs, but they may still
target arbitrary hosts. Browser image requests can disclose the application
page URL through the HTTP referrer header, and eagerly loading every rendered
thumbnail creates requests before they are needed.

## Changes

- Render thumbnails with a `no-referrer` policy.
- Mark thumbnails for browser-native lazy loading.
- Add a component test for both image request attributes.
- Extend the repository baseline and README with the privacy contract.

## Verification

- `npm test -- --run`
- `npm run lint`
- `npm run build`
- `make check`
- `git diff --check`

Browser/network inspection is not available on this host, so emitted request
headers still require verification in a real browser session.
