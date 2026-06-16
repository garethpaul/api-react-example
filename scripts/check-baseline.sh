#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE_JSON="$ROOT_DIR/package.json"
PHOTOS="$ROOT_DIR/src/components/Photos.jsx"
APP_TEST="$ROOT_DIR/src/App.test.jsx"
README="$ROOT_DIR/README.md"
RECORD_SHAPE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-record-shape-validation.md"
THUMBNAIL_URL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-thumbnail-url-validation.md"
RENDER_FIELD_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-render-field-normalization.md"
DUPLICATE_ID_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-duplicate-id-validation.md"
UNMOUNT_GUARD_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-unmount-state-guard.md"
PHOTO_ID_TYPE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-id-type-validation.md"
THUMBNAIL_CREDENTIAL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-thumbnail-credential-validation.md"
PHOTO_ABORT_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-fetch-abort-guard.md"
TOOLCHAIN_PLAN="$ROOT_DIR/docs/plans/2026-06-10-vite-toolchain-migration.md"
PHOTO_TIMEOUT_PLAN="$ROOT_DIR/docs/plans/2026-06-10-photo-request-timeout.md"
REQUEST_OWNERSHIP_PLAN="$ROOT_DIR/docs/plans/2026-06-10-photo-request-ownership.md"
THUMBNAIL_REFERRER_PLAN="$ROOT_DIR/docs/plans/2026-06-12-photo-thumbnail-referrer-privacy.md"
WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"
CODEQL_PLAN="$ROOT_DIR/docs/plans/2026-06-12-codeql-baseline.md"
CONTENT_TYPE_PLAN="$ROOT_DIR/docs/plans/2026-06-13-photo-response-content-type.md"
RESPONSE_BODY_LIMIT_PLAN="$ROOT_DIR/docs/plans/2026-06-13-photo-response-body-limit.md"
STREAM_BUFFER_PLAN="$ROOT_DIR/docs/plans/2026-06-13-photo-stream-buffer-bound.md"
STREAM_TIMEOUT_PLAN="$ROOT_DIR/docs/plans/2026-06-13-photo-stream-timeout-cancellation.md"
REDIRECT_REJECTION_PLAN="$ROOT_DIR/docs/plans/2026-06-14-photo-response-redirect-rejection.md"
STREAM_CHUNK_PLAN="$ROOT_DIR/docs/plans/2026-06-14-photo-stream-chunk-validation.md"
READABLE_STREAM_PLAN="$ROOT_DIR/docs/plans/2026-06-14-photo-readable-stream-boundary.md"
REJECTED_RESPONSE_CANCEL_PLAN="$ROOT_DIR/docs/plans/2026-06-15-photo-rejected-response-body-cancellation.md"
RESPONSE_ENVELOPE_CANCEL_PLAN="$ROOT_DIR/docs/plans/2026-06-15-photo-response-envelope-cancellation.md"
CONTENT_LENGTH_CANCEL_PLAN="$ROOT_DIR/docs/plans/2026-06-15-photo-content-length-cancellation.md"
TOOL_PATCH_PLAN="$ROOT_DIR/docs/plans/2026-06-15-eslint-vitest-patch-upgrades.md"
THUMBNAIL_PRIVATE_LITERAL_PLAN="$ROOT_DIR/docs/plans/2026-06-15-photo-thumbnail-private-literal-boundary.md"
THUMBNAIL_SHARED_ADDRESS_PLAN="$ROOT_DIR/docs/plans/2026-06-15-photo-thumbnail-shared-address-boundary.md"
THUMBNAIL_DEFAULT_PORT_PLAN="$ROOT_DIR/docs/plans/2026-06-16-photo-thumbnail-default-port.md"

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md must document repository maintenance." >&2
  exit 1
fi

if ! grep -Fq "API React Example Changes" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "CHANGES.md must identify the project." >&2
  exit 1
fi

if [ ! -f "$RECORD_SHAPE_PLAN" ]; then
  printf '%s\n' "Photo record shape validation plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$RECORD_SHAPE_PLAN" || ! grep -Fq "make check" "$RECORD_SHAPE_PLAN"; then
  printf '%s\n' "Photo record shape validation plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$THUMBNAIL_URL_PLAN" ]; then
  printf '%s\n' "Photo thumbnail URL validation plan is missing." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$THUMBNAIL_URL_PLAN" || ! grep -Fq "make check" "$THUMBNAIL_URL_PLAN"; then
  printf '%s\n' "Photo thumbnail URL validation plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$RENDER_FIELD_PLAN" ]; then
  printf '%s\n' "Photo render field normalization plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$RENDER_FIELD_PLAN" || ! grep -Fq "make check" "$RENDER_FIELD_PLAN"; then
  printf '%s\n' "Photo render field normalization plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$DUPLICATE_ID_PLAN" ]; then
  printf '%s\n' "Photo duplicate id validation plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$DUPLICATE_ID_PLAN" || ! grep -Fq "make check" "$DUPLICATE_ID_PLAN"; then
  printf '%s\n' "Photo duplicate id validation plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$UNMOUNT_GUARD_PLAN" ]; then
  printf '%s\n' "Photo unmount state guard plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$UNMOUNT_GUARD_PLAN" || ! grep -Fq "make check" "$UNMOUNT_GUARD_PLAN"; then
  printf '%s\n' "Photo unmount state guard plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$PHOTO_ID_TYPE_PLAN" ]; then
  printf '%s\n' "Photo id type validation plan is missing." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PHOTO_ID_TYPE_PLAN" || ! grep -Fq "make check" "$PHOTO_ID_TYPE_PLAN"; then
  printf '%s\n' "Photo id type validation plan must record completed status and make check verification." >&2
  exit 1
fi

if [ -f "$ROOT_DIR/package-lock.json" ]; then
  printf '%s\n' "Yarn is the lockfile source of truth; package-lock.json must not be present." >&2
  exit 1
fi

if git -C "$ROOT_DIR" ls-files 'node_modules/*' 'build/*' 'dist/*' | grep -q .; then
  printf '%s\n' "Generated dependency and build artifacts must not be tracked." >&2
  exit 1
fi

for dependency in \
  '"react": "19.2.7"' \
  '"react-dom": "19.2.7"' \
  '"eslint": "10.5.0"' \
  '"vite": "8.0.16"' \
  '"vitest": "4.1.9"'; do
  if ! grep -Fq "$dependency" "$PACKAGE_JSON"; then
    printf '%s\n' "Expected dependency pin is missing: $dependency" >&2
    exit 1
  fi
done

for lockfile_contract in \
  'eslint@10.5.0:' \
  'version "10.5.0"' \
  'vitest@4.1.9:' \
  'version "4.1.9"' \
  '"@vitest/runner@4.1.9"'; do
  if ! grep -Fq "$lockfile_contract" "$ROOT_DIR/yarn.lock"; then
    printf '%s\n' "Expected lockfile contract is missing: $lockfile_contract" >&2
    exit 1
  fi
done

for tool_patch_document in \
  "$README" \
  "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq 'ESLint 10.5.0' "$tool_patch_document" || \
     ! grep -Fq 'Vitest 4.1.9' "$tool_patch_document"; then
    printf '%s\n' "$tool_patch_document must document the current ESLint and Vitest patch versions." >&2
    exit 1
  fi
done

for tool_patch_plan_contract in \
  'status: completed' \
  'ESLint 10.5.0' \
  'Vitest 4.1.9' \
  'all 38 component tests passed' \
  'make check' \
  'external working directory' \
  'hostile mutations' \
  'credential-shaped additions'; do
  if ! grep -Fq "$tool_patch_plan_contract" "$TOOL_PATCH_PLAN"; then
    printf '%s\n' "Tool patch plan must preserve completion evidence: $tool_patch_plan_contract" >&2
    exit 1
  fi
done

if grep -Fq '"react-scripts"' "$PACKAGE_JSON"; then
  printf '%s\n' "Deprecated react-scripts must not remain in package.json." >&2
  exit 1
fi

for package_contract in \
  '"packageManager": "yarn@1.22.22"' \
  '"node": ">=20.19"' \
  '"debug": "4.4.3"' \
  '"build": "vite build"' \
  '"format:check": "prettier --check ."' \
  '"test": "vitest run"'; do
  if ! grep -Fq "$package_contract" "$PACKAGE_JSON"; then
    printf '%s\n' "Expected package contract is missing: $package_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "/dist" "$ROOT_DIR/.gitignore"; then
  printf '%s\n' ".gitignore must exclude Vite's dist output." >&2
  exit 1
fi

for required_file in \
  "index.html" \
  "vite.config.js" \
  "eslint.config.js" \
  ".prettierrc.json" \
  ".github/workflows/check.yml" \
  "docs/plans/2026-06-10-vite-toolchain-migration.md"; do
  if [ ! -f "$ROOT_DIR/$required_file" ]; then
    printf '%s\n' "Required modern toolchain file is missing: $required_file" >&2
    exit 1
  fi
done

if [ -f "$ROOT_DIR/public/index.html" ] || [ -f "$ROOT_DIR/src/serviceWorker.js" ]; then
  printf '%s\n' "Obsolete Create React App entry files must be removed." >&2
  exit 1
fi

for workflow_contract in \
  "permissions:" \
  "contents: read" \
  "runs-on: ubuntu-24.04" \
  "cancel-in-progress: true" \
  "timeout-minutes: 10" \
  "actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10" \
  "persist-credentials: false" \
  "actions/setup-node@48b55a011bda9f5d6aeb4c2d9c7362e8dae4041e" \
  "node-version: [20, 22, 24]" \
  "node-version: \${{ matrix.node-version }}" \
  "workflow_dispatch:" \
  "run: corepack yarn install --frozen-lockfile" \
  "run: make check"; do
  if ! grep -Fq "$workflow_contract" "$WORKFLOW"; then
    printf '%s\n' "GitHub Actions workflow must keep contract: $workflow_contract" >&2
    exit 1
  fi
done

if find "$ROOT_DIR/.github/workflows" -type f \( -name '*codeql*.yml' -o -name '*codeql*.yaml' \) -print -quit | grep -q .; then
  printf '%s\n' "GitHub default CodeQL setup must not be duplicated by an advanced workflow." >&2
  exit 1
fi

workflow_paths=$(find "$ROOT_DIR/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print | LC_ALL=C sort)
expected_workflow_paths=$WORKFLOW
if [ "$workflow_paths" != "$expected_workflow_paths" ]; then
  printf '%s\n' "Only the canonical Check workflow is allowed." >&2
  exit 1
fi

if grep -E '^[[:space:]]*(-[[:space:]]+)?uses:' "$WORKFLOW" | \
   grep -Ev '@[0-9a-f]{40}([[:space:]]+#.*)?$' >/dev/null; then
  printf '%s\n' "GitHub Actions must use immutable commit SHAs." >&2
  exit 1
fi

if [ ! -f "$CODEQL_PLAN" ] || \
   ! grep -Fq "status: completed" "$CODEQL_PLAN" || \
   ! grep -Fq "make check" "$CODEQL_PLAN" || \
   ! grep -Fq "external working directory" "$CODEQL_PLAN" || \
   ! grep -Fq "hostile mutations rejected" "$CODEQL_PLAN" || \
   ! grep -Fq "default setup" "$CODEQL_PLAN" || \
   ! grep -Fq "advanced CodeQL workflow" "$CODEQL_PLAN"; then
  printf '%s\n' "CodeQL plan must record completed local verification." >&2
  exit 1
fi

if ! grep -Fq "CodeQL default setup analyzes" "$README" || \
   ! grep -Fq "CodeQL default-setup results" "$ROOT_DIR/SECURITY.md" || \
   ! grep -Fq "CodeQL default-setup coverage" "$ROOT_DIR/VISION.md" || \
   ! grep -Fq "CodeQL default setup" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "Repository guidance must document the CodeQL trust boundary." >&2
  exit 1
fi

if [ "$(grep -Ec '^[[:space:]]*permissions:' "$WORKFLOW")" -ne 1 ] || \
   grep -Eq 'write-all|contents:[[:space:]]*write|pull-requests:[[:space:]]*write|actions:[[:space:]]*write' "$WORKFLOW"; then
  printf '%s\n' "GitHub Actions permissions must remain globally read-only." >&2
  exit 1
fi

if [ "$(grep -Ec '^[[:space:]]+run:' "$WORKFLOW")" -ne 2 ] || \
   grep -Eq 'continue-on-error:[[:space:]]*true|if:[[:space:]]*false' "$WORKFLOW"; then
  printf '%s\n' "GitHub Actions must run exactly the frozen install and full Make gate without bypasses." >&2
  exit 1
fi

if ! grep -Fq 'ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))' "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile checks must be location-independent." >&2
  exit 1
fi

if ! grep -Fq 'cd $(ROOT) &&' "$ROOT_DIR/Makefile"; then
  printf '%s\n' "Makefile commands must execute from the repository root." >&2
  exit 1
fi

if ! grep -Fq 'PHOTO_ENDPOINT = '\''https://jsonplaceholder.typicode.com/photos'\''' "$PHOTOS"; then
  printf '%s\n' "Photo endpoint must stay on HTTPS JSONPlaceholder." >&2
  exit 1
fi

for redirect_contract in \
  "const options = { redirect: 'error' }" \
  "const response = await fetch(PHOTO_ENDPOINT, requestOptions)" \
  "if (response.redirected)" \
  "Photo response redirects are not allowed."; do
  if ! grep -Fq "$redirect_contract" "$PHOTOS"; then
    printf '%s\n' "Missing photo redirect-rejection contract: $redirect_contract" >&2
    exit 1
  fi
done

if ! awk '
  /if \(!response\.ok\)/ { ok_guard = NR }
  /if \(response\.redirected\)/ { redirect_guard = NR }
  /response\.headers\?\.get\('\''content-type'\''\)/ { content_type = NR }
  END { exit !(ok_guard && redirect_guard && content_type && ok_guard < redirect_guard && redirect_guard < content_type) }
' "$PHOTOS"; then
  printf '%s\n' "Redirected photo responses must be rejected before header and body parsing." >&2
  exit 1
fi

for redirect_test in \
  "disables redirects when abort support is unavailable" \
  "rejects a redirected photo response before reading headers or body" \
  "expect(getHeader).not.toHaveBeenCalled()" \
  "expect(arrayBuffer).not.toHaveBeenCalled()"; do
  if ! grep -Fq "$redirect_test" "$APP_TEST"; then
    printf '%s\n' "Missing photo redirect regression contract: $redirect_test" >&2
    exit 1
  fi
done

if [ ! -f "$REDIRECT_REJECTION_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$REDIRECT_REJECTION_PLAN" || \
   ! grep -Fq "make check" "$REDIRECT_REJECTION_PLAN" || \
   ! grep -Fq "hostile mutations" "$REDIRECT_REJECTION_PLAN"; then
  printf '%s\n' "Photo redirect-rejection plan must record completed verification." >&2
  exit 1
fi

for redirect_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$redirect_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "reject redirects before response parsing"; then
    printf '%s\n' "$redirect_doc must document photo response redirect rejection." >&2
    exit 1
  fi
done

if ! grep -Fq "componentDidMount()" "$PHOTOS"; then
  printf '%s\n' "Photo loading must use componentDidMount instead of deprecated lifecycle hooks." >&2
  exit 1
fi

if ! grep -Fq "componentWillUnmount()" "$PHOTOS"; then
  printf '%s\n' "Photo loading must guard async state updates after unmount." >&2
  exit 1
fi

if ! grep -Fq "isActive = false" "$PHOTOS" || \
   ! grep -Fq "setPhotosState(request, nextState)" "$PHOTOS" || \
   ! grep -Fq "this.activeRequest === request" "$PHOTOS"; then
  printf '%s\n' "Photos component must centralize mounted-state checks before setState." >&2
  exit 1
fi

if ! awk '
  /setPhotosState\(request, nextState\)/ { in_state_helper = 1 }
  in_state_helper && /this\.isActive && this\.activeRequest === request/ { found = 1 }
  in_state_helper && /^  }/ { in_state_helper = 0 }
  END { exit found ? 0 : 1 }
' "$PHOTOS"; then
  printf '%s\n' "Photo state updates must verify active request identity inside setPhotosState." >&2
  exit 1
fi

if ! grep -Fq "activeRequest = null" "$PHOTOS" || \
   ! grep -Fq "request.abortController.abort()" "$PHOTOS" || \
   ! grep -Fq "cancelActivePhotoRequest()" "$PHOTOS"; then
  printf '%s\n' "Photos component must abort pending photo fetches during unmount." >&2
  exit 1
fi

if ! grep -Fq "new AbortController()" "$PHOTOS" || ! grep -Fq "fetch(PHOTO_ENDPOINT, requestOptions)" "$PHOTOS"; then
  printf '%s\n' "Photos component must pass an abort signal to photo fetch when supported." >&2
  exit 1
fi

for timeout_contract in \
  "PHOTO_REQUEST_TIMEOUT_MS = 10000" \
  "timeoutId: null" \
  "this.createPhotoRequestTimeout(request)," \
  "setTimeout(() =>" \
  "request.abortController.abort()" \
  "reject(new Error('Photo request timed out.'))" \
  "Promise.race([" \
  "async fetchPhotos(request)" \
  "const requestOptions = this.createPhotoRequestOptions(request)" \
  "const photoRequest = this.fetchPhotos(request)" \
  "clearPhotoRequestTimeout(request)" \
  "clearTimeout(request.timeoutId)"; do
  if ! grep -Fq "$timeout_contract" "$PHOTOS"; then
    printf '%s\n' "Missing photo request timeout contract: $timeout_contract" >&2
    exit 1
  fi
done

if grep -Fq "const photoRequest = await this.fetchPhotos(request)" "$PHOTOS"; then
  printf '%s\n' "Photo operation must start without awaiting before the timeout race." >&2
  exit 1
fi

if [ "$(grep -Fc 'this.clearPhotoRequestTimeout(request);' "$PHOTOS")" -lt 2 ]; then
  printf '%s\n' "Photo timeout cleanup must run after completion and unmount." >&2
  exit 1
fi

if [ "$(grep -Fc 'request.abortController.abort();' "$PHOTOS")" -lt 2 ]; then
  printf '%s\n' "Photo requests must abort at timeout and unmount." >&2
  exit 1
fi

for ownership_contract in \
  "const request = this.createPhotoRequest()" \
  "this.activeRequest = request" \
  "this.setPhotosState(request," \
  "if (this.activeRequest === request)"; do
  if ! grep -Fq "$ownership_contract" "$PHOTOS"; then
    printf '%s\n' "Missing photo request ownership contract: $ownership_contract" >&2
    exit 1
  fi
done

if grep -Fq "componentWillMount" "$PHOTOS"; then
  printf '%s\n' "Deprecated componentWillMount must not be reintroduced." >&2
  exit 1
fi

if ! grep -Fq "role=\"status\"" "$PHOTOS"; then
  printf '%s\n' "Photos component must expose a loading status role." >&2
  exit 1
fi

if ! grep -Fq "role=\"alert\"" "$PHOTOS"; then
  printf '%s\n' "Photos component must expose an error alert role." >&2
  exit 1
fi

if ! grep -Fq "MAX_PHOTOS = 12" "$PHOTOS"; then
  printf '%s\n' "Photos component must cap rendered API results." >&2
  exit 1
fi

if ! grep -Fq "function normalizePhotos" "$PHOTOS"; then
  printf '%s\n' "Photos component must normalize API responses before rendering." >&2
  exit 1
fi

if ! grep -Fq "Array.isArray(photos)" "$PHOTOS"; then
  printf '%s\n' "Photos component must reject non-array API responses." >&2
  exit 1
fi

if ! grep -Fq "slice(0, MAX_PHOTOS)" "$PHOTOS"; then
  printf '%s\n' "Photos component must limit rendered API responses." >&2
  exit 1
fi

if ! grep -Fq "function isRenderablePhoto" "$PHOTOS"; then
  printf '%s\n' "Photos component must validate photo item shape before rendering." >&2
  exit 1
fi

if ! grep -Fq "photo.id !== null" "$PHOTOS" || ! grep -Fq "photo.id !== undefined" "$PHOTOS"; then
  printf '%s\n' "Photos component must require photo ids before rendering." >&2
  exit 1
fi

if ! grep -Fq "function isPhotoId" "$PHOTOS"; then
  printf '%s\n' "Photos component must validate photo id types before rendering." >&2
  exit 1
fi

if ! grep -Fq "Number.isFinite(value)" "$PHOTOS" || ! grep -Fq "hasText(value)" "$PHOTOS"; then
  printf '%s\n' "Photos component must accept only finite numeric or non-empty string photo ids." >&2
  exit 1
fi

if ! grep -Fq "isPhotoId(photo.id)" "$PHOTOS"; then
  printf '%s\n' "Photos component must use key-safe photo id validation before rendering." >&2
  exit 1
fi

if ! grep -Fq "hasText(photo.title)" "$PHOTOS"; then
  printf '%s\n' "Photos component must require title text before rendering." >&2
  exit 1
fi

if ! grep -Fq "function isHttpsUrl" "$PHOTOS"; then
  printf '%s\n' "Photos component must validate thumbnail URLs before rendering." >&2
  exit 1
fi

if ! grep -Fq "function normalizeHttpsUrl" "$PHOTOS"; then
  printf '%s\n' "Photos component must normalize accepted thumbnail URLs before rendering." >&2
  exit 1
fi

if ! grep -Fq "new URL(value)" "$PHOTOS" || ! grep -Fq "protocol !== 'https:'" "$PHOTOS"; then
  printf '%s\n' "Photos component must require HTTPS thumbnail URLs." >&2
  exit 1
fi

if ! grep -Fq "url.username || url.password" "$PHOTOS"; then
  printf '%s\n' "Photos component must reject thumbnail URLs with embedded credentials." >&2
  exit 1
fi

for thumbnail_host_contract in \
  "function isBlockedThumbnailHost" \
  "isBlockedThumbnailHost(url.hostname)" \
  "address <= 0x00ffffff" \
  "address >= 0x0a000000 && address <= 0x0affffff" \
  "address >= 0x64400000 && address <= 0x647fffff" \
  "address >= 0x7f000000 && address <= 0x7fffffff" \
  "address >= 0xa9fe0000 && address <= 0xa9feffff" \
  "address >= 0xac100000 && address <= 0xac1fffff" \
  "address >= 0xc0a80000 && address <= 0xc0a8ffff" \
  "ipv6Address.startsWith('::ffff:')" \
  "firstHextet >= 0xfc00 && firstHextet <= 0xfdff" \
  "firstHextet >= 0xfe80 && firstHextet <= 0xfebf"; do
  if ! grep -Fq "$thumbnail_host_contract" "$PHOTOS"; then
    printf '%s\n' "Missing thumbnail local-address contract: $thumbnail_host_contract" >&2
    exit 1
  fi
done

for thumbnail_shared_fixture in \
  "https://100.63.255.255/thumbnail.jpg" \
  "https://100.128.0.0/thumbnail.jpg" \
  "https://100.64.0.0/thumbnail.jpg" \
  "https://100.127.255.255/thumbnail.jpg" \
  "https://1681915905/thumbnail.jpg" \
  "https://[::ffff:6440:1]/thumbnail.jpg"; do
  if ! grep -Fq "$thumbnail_shared_fixture" "$APP_TEST"; then
    printf '%s\n' "Missing thumbnail shared-address fixture: $thumbnail_shared_fixture" >&2
    exit 1
  fi
done

for thumbnail_shared_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Backend-provided thumbnail URLs cannot explicitly target IPv4 shared address space before rendering." "$thumbnail_shared_doc"; then
    printf '%s\n' "$thumbnail_shared_doc must document the thumbnail shared-address boundary." >&2
    exit 1
  fi
done

for thumbnail_shared_plan_contract in \
  "Status: Completed" \
  "100.64.0.0/10" \
  "make check" \
  "mutations"; do
  if ! grep -Fq "$thumbnail_shared_plan_contract" "$THUMBNAIL_SHARED_ADDRESS_PLAN"; then
    printf '%s\n' "Thumbnail shared-address plan must preserve completion evidence: $thumbnail_shared_plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "if (url.port !== '')" "$PHOTOS"; then
  printf '%s\n' "Thumbnail URL normalization must reject nondefault HTTPS ports." >&2
  exit 1
fi

for thumbnail_port_fixture in \
  "https://example.com:1/thumbnail.jpg" \
  "https://example.com:80/thumbnail.jpg" \
  "https://example.com:443/thumbnail.jpg" \
  "https://example.com:444/thumbnail.jpg" \
  "https://example.com:8443/thumbnail.jpg" \
  "https://example.com:65535/thumbnail.jpg"; do
  if ! grep -Fq "$thumbnail_port_fixture" "$APP_TEST"; then
    printf '%s\n' "Missing thumbnail HTTPS port fixture: $thumbnail_port_fixture" >&2
    exit 1
  fi
done

for thumbnail_port_test in \
  "rejects a nondefault thumbnail HTTPS port" \
  "preserves the default thumbnail HTTPS port"; do
  if ! grep -Fq "$thumbnail_port_test" "$APP_TEST"; then
    printf '%s\n' "Missing thumbnail HTTPS port test: $thumbnail_port_test" >&2
    exit 1
  fi
done

for thumbnail_port_plan_contract in \
  "Status: Completed" \
  "url.port" \
  "make check" \
  "mutations"; do
  if ! grep -Fq "$thumbnail_port_plan_contract" "$THUMBNAIL_DEFAULT_PORT_PLAN"; then
    printf '%s\n' "Thumbnail default-port plan must record completed verification: $thumbnail_port_plan_contract" >&2
    exit 1
  fi
done

for thumbnail_port_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Backend-provided thumbnail URLs use only the default HTTPS port before rendering; browser code cannot inspect DNS answers or the connected peer." "$thumbnail_port_doc"; then
    printf '%s\n' "$thumbnail_port_doc must document the thumbnail default-port boundary." >&2
    exit 1
  fi
done

for thumbnail_host_fixture in \
  "https://LOCALHOST./thumbnail.jpg" \
  "https://images.localhost/thumbnail.jpg" \
  "https://2130706433/thumbnail.jpg" \
  "https://0x7f000001/thumbnail.jpg" \
  "https://167772161/thumbnail.jpg" \
  "https://127.255.255.255/thumbnail.jpg" \
  "https://169.254.1.1/thumbnail.jpg" \
  "https://169.254.255.255/thumbnail.jpg" \
  "https://172.16.0.1/thumbnail.jpg" \
  "https://172.31.255.255/thumbnail.jpg" \
  "https://192.168.1.1/thumbnail.jpg" \
  "https://192.168.255.255/thumbnail.jpg" \
  "https://[::1]/thumbnail.jpg" \
  "https://[fc00::1]/thumbnail.jpg" \
  "https://[fe80::1]/thumbnail.jpg" \
  "https://[febf:ffff::1]/thumbnail.jpg" \
  "https://[::ffff:10.0.0.1]/thumbnail.jpg" \
  "https://8.8.8.8/thumbnail.jpg" \
  "https://172.15.255.255/thumbnail.jpg" \
  "https://172.32.0.0/thumbnail.jpg" \
  "https://[2001:4860:4860::8888]/thumbnail.jpg" \
  "https://[::ffff:8.8.8.8]/thumbnail.jpg" \
  "https://images.localhost.example/thumbnail.jpg"; do
  if ! grep -Fq "$thumbnail_host_fixture" "$APP_TEST"; then
    printf '%s\n' "Missing thumbnail local-address fixture: $thumbnail_host_fixture" >&2
    exit 1
  fi
done

for thumbnail_host_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Backend-provided thumbnail URLs cannot explicitly target localhost, loopback, private, link-local, or unspecified IP literals before rendering; DNS-style hosts are not resolved by this syntactic check." "$thumbnail_host_doc"; then
    printf '%s\n' "$thumbnail_host_doc must document the thumbnail local-address boundary." >&2
    exit 1
  fi
done

for thumbnail_host_plan_contract in \
  "status: completed" \
  "isBlockedThumbnailHost" \
  "make check" \
  "hostile mutations"; do
  if ! grep -Fqi "$thumbnail_host_plan_contract" "$THUMBNAIL_PRIVATE_LITERAL_PLAN"; then
    printf '%s\n' "Thumbnail local-address plan must record completed verification: $thumbnail_host_plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "isHttpsUrl(photo.thumbnailUrl)" "$PHOTOS"; then
  printf '%s\n' "Photos component must use HTTPS URL validation for thumbnails." >&2
  exit 1
fi

if ! grep -Fq "if (!photos.every(isRenderablePhoto))" "$PHOTOS"; then
  printf '%s\n' "Photos component must validate every API photo before applying the render limit." >&2
  exit 1
fi

if ! grep -Fq "function normalizePhoto" "$PHOTOS"; then
  printf '%s\n' "Photos component must normalize accepted photo fields before rendering." >&2
  exit 1
fi

if ! grep -Fq "function normalizePhotoId" "$PHOTOS"; then
  printf '%s\n' "Photos component must normalize accepted photo ids before rendering." >&2
  exit 1
fi

if ! grep -Fq "id: normalizePhotoId(photo.id)" "$PHOTOS"; then
  printf '%s\n' "Photos component must render normalized photo ids." >&2
  exit 1
fi

if ! grep -Fq "title: photo.title.trim()" "$PHOTOS"; then
  printf '%s\n' "Photos component must trim accepted photo titles before rendering." >&2
  exit 1
fi

if ! grep -Fq "thumbnailUrl: normalizeHttpsUrl(photo.thumbnailUrl)" "$PHOTOS"; then
  printf '%s\n' "Photos component must render normalized HTTPS thumbnail URLs." >&2
  exit 1
fi

if ! grep -Fq 'loading="lazy"' "$PHOTOS" || \
   ! grep -Fq 'referrerPolicy="no-referrer"' "$PHOTOS"; then
  printf '%s\n' "Photo thumbnails must load lazily without sending page referrers." >&2
  exit 1
fi

if ! grep -Fq "photos.map(normalizePhoto).slice(0, MAX_PHOTOS)" "$PHOTOS"; then
  printf '%s\n' "Photos component must normalize photos before applying the render cap." >&2
  exit 1
fi

if ! grep -Fq "function hasUniquePhotoIds" "$PHOTOS"; then
  printf '%s\n' "Photos component must guard duplicate photo ids before rendering." >&2
  exit 1
fi

if ! grep -Fq "normalizePhotoId(photo.id)" "$PHOTOS" || ! grep -Fq "!hasUniquePhotoIds(photos)" "$PHOTOS"; then
  printf '%s\n' "Photos component must compare React key-compatible photo ids before rendering." >&2
  exit 1
fi

if ! grep -Fq "mockFetchSuccess" "$APP_TEST"; then
  printf '%s\n' "Tests must mock fetch success without network access." >&2
  exit 1
fi

for content_type_contract in \
  "export function isJsonContentType(value)" \
  "mediaType === 'application/json'" \
  "\\+json$/.test(mediaType)" \
  "const contentType = response.headers?.get('content-type')" \
  "if (!isJsonContentType(contentType))"; do
  if ! grep -Fq "$content_type_contract" "$PHOTOS"; then
    printf '%s\n' "Missing photo response content-type contract: $content_type_contract" >&2
    exit 1
  fi
done

status_check_line=$(grep -nF "if (!response.ok)" "$PHOTOS" | cut -d: -f1)
content_type_line=$(grep -nF "const contentType = response.headers?.get('content-type')" "$PHOTOS" | cut -d: -f1)
json_parse_line=$(grep -nF "await readBoundedPhotoJson(response" "$PHOTOS" | cut -d: -f1)
if [ -z "$status_check_line" ] || [ -z "$content_type_line" ] || \
   [ -z "$json_parse_line" ] || [ "$status_check_line" -ge "$content_type_line" ] || \
   [ "$content_type_line" -ge "$json_parse_line" ]; then
  printf '%s\n' "Photo response content type must be validated after status and before JSON parsing." >&2
  exit 1
fi

for response_body_contract in \
  "export const MAX_PHOTO_RESPONSE_BYTES = 2 * 1024 * 1024" \
  "export async function readBoundedPhotoJson(response, setReaderCancel = null)" \
  "response.headers?.get('content-length')" \
  "new TextDecoder('utf-8', { fatal: true })" \
  "typeof response.body?.getReader !== 'function'" \
  "Photo response body must be a readable stream." \
  "return readPhotoStream(response.body, setReaderCancel)" \
  "ArrayBuffer.isView(value)" \
  "Object.prototype.toString.call(value) === '[object Uint8Array]'" \
  "!isUint8Array(value) || value.byteLength === 0" \
  "await cancelPhotoReader(reader)" \
  "chunk.byteLength > MAX_PHOTO_RESPONSE_BYTES - receivedBytes" \
  "await reader.cancel()" \
  "reader.releaseLock()"; do
  if ! grep -Fq "$response_body_contract" "$PHOTOS"; then
    printf '%s\n' "Missing bounded photo response-body contract: $response_body_contract" >&2
    exit 1
  fi
done

invalid_chunk_line=$(grep -nF '!isUint8Array(value) || value.byteLength === 0' "$PHOTOS" | cut -d: -f1)
chunk_assignment_line=$(grep -nF 'const chunk = value;' "$PHOTOS" | cut -d: -f1)
chunk_copy_line=$(grep -nF 'bytes.set(chunk, receivedBytes)' "$PHOTOS" | cut -d: -f1)
if [ -z "$invalid_chunk_line" ] || [ -z "$chunk_assignment_line" ] || \
   [ -z "$chunk_copy_line" ] || [ "$invalid_chunk_line" -ge "$chunk_assignment_line" ] || \
   [ "$chunk_assignment_line" -ge "$chunk_copy_line" ]; then
  printf '%s\n' "Photo stream chunks must be validated before assignment and copying." >&2
  exit 1
fi
for chunk_test in \
  'rejects a non-byte photo stream chunk and clears reader ownership' \
  "[Symbol.toStringTag]: 'Uint8Array'" \
  'rejects an empty photo stream chunk without waiting for timeout' \
  'preserves the invalid chunk error when reader cancellation fails' \
  'expect(setReaderCancel).toHaveBeenLastCalledWith(null)' \
  'expect(reader.read).toHaveBeenCalledTimes(1)'; do
  if ! grep -Fq "$chunk_test" "$APP_TEST"; then
    printf '%s\n' "Photo stream chunk tests are incomplete: $chunk_test" >&2
    exit 1
  fi
done
if [ ! -f "$STREAM_CHUNK_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STREAM_CHUNK_PLAN" || \
   ! grep -Fq "yarn verify" "$STREAM_CHUNK_PLAN" || \
   ! grep -Fq "hostile mutations" "$STREAM_CHUNK_PLAN"; then
  printf '%s\n' "Photo stream chunk plan must record completed verification." >&2
  exit 1
fi
for stream_chunk_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$stream_chunk_doc" | tr -s '[:space:]' ' ' | \
      grep -Eiq 'reject(ed)? malformed (or|and) (empty|zero-length).*(stream )?chunks'; then
    printf '%s\n' "$stream_chunk_doc must document malformed and empty stream-chunk rejection." >&2
    exit 1
  fi
done

for stream_buffer_contract in \
  "const bytes = new Uint8Array(MAX_PHOTO_RESPONSE_BYTES)" \
  "bytes.set(chunk, receivedBytes)" \
  "receivedBytes += chunk.byteLength" \
  "bytes.subarray(0, receivedBytes)"; do
  if ! grep -Fq "$stream_buffer_contract" "$PHOTOS"; then
    printf '%s\n' "Missing contiguous photo stream buffer contract: $stream_buffer_contract" >&2
    exit 1
  fi
done
if grep -Fq "const chunks = []" "$PHOTOS" || \
   grep -Fq "chunks.push(chunk)" "$PHOTOS" || \
   grep -Fq "chunks.forEach" "$PHOTOS"; then
  printf '%s\n' "Photo stream reads must not retain attacker-controlled chunk arrays." >&2
  exit 1
fi

if grep -Fq "response.json()" "$PHOTOS" || \
   grep -Fq "response.text()" "$PHOTOS" || \
   grep -Fq "response.arrayBuffer()" "$PHOTOS"; then
  printf '%s\n' "Photo JSON must pass through authoritative bounded stream decoding." >&2
  exit 1
fi

for response_body_test in \
  "rejects a declared oversized photo response before reading" \
  "cancels a streamed photo response when its byte limit is crossed" \
  "releases a streamed photo reader after successful parsing" \
  "parses a valid photo response split into one-byte stream chunks" \
  "rejects an unstreamable photo response without whole-body fallback" \
  "rejects malformed UTF-8 photo response bytes" \
  "accepts valid JSON exactly at the photo response byte limit"; do
  if ! grep -Fq "$response_body_test" "$APP_TEST"; then
    printf '%s\n' "Missing photo response-body regression test: $response_body_test" >&2
    exit 1
  fi
done

if ! grep -Fq "expect(arrayBuffer).not.toHaveBeenCalled()" "$APP_TEST"; then
  printf '%s\n' "Unstreamable response coverage must reject whole-body fallback calls." >&2
  exit 1
fi

if [ ! -f "$READABLE_STREAM_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$READABLE_STREAM_PLAN" || \
   ! grep -Fq "make check" "$READABLE_STREAM_PLAN" || \
   ! grep -Fq "hostile mutations" "$READABLE_STREAM_PLAN"; then
  printf '%s\n' "Photo readable stream plan must record completed verification." >&2
  exit 1
fi

for readable_stream_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$readable_stream_doc" | tr -s '[:space:]' ' ' | \
      grep -Eiq 'require(s|d)? a readable (byte )?stream'; then
    printf '%s\n' "$readable_stream_doc must document the readable stream boundary." >&2
    exit 1
  fi
done

for rejected_response_cancel_contract in \
  "function cancelUnreadPhotoResponse(response)" \
  "typeof body?.cancel !== 'function'" \
  "Promise.resolve(body.cancel()).catch(() => {})" \
  "Preserve the response validation error if transport cleanup also fails."; do
  if ! grep -Fq "$rejected_response_cancel_contract" "$PHOTOS"; then
    printf '%s\n' "Rejected photo responses must keep cleanup contract: $rejected_response_cancel_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc 'cancelUnreadPhotoResponse(response);' "$PHOTOS")" -ne 6 ]; then
  printf '%s\n' "All six pre-read response rejection paths must cancel the unread response body." >&2
  exit 1
fi

if ! awk '
  /if \(!response\.ok\)/ { status = NR }
  status && /cancelUnreadPhotoResponse\(response\);/ && !status_cancel { status_cancel = NR }
  status_cancel && /throw new Error\(`Photo request failed/ { status_throw = NR }
  /if \(response\.redirected\)/ { redirect = NR }
  redirect && /cancelUnreadPhotoResponse\(response\);/ && !redirect_cancel { redirect_cancel = NR }
  redirect_cancel && /throw new Error\('\''Photo response redirects/ { redirect_throw = NR }
  /if \(!isJsonContentType\(contentType\)\)/ { media = NR }
  media && /cancelUnreadPhotoResponse\(response\);/ { media_cancel = NR }
  media_cancel && /throw new Error\('\''Photo response must use/ { media_throw = NR }
  END {
    exit !(status && status_cancel && status_throw && redirect && redirect_cancel &&
      redirect_throw && media && media_cancel && media_throw && status < status_cancel &&
      status_cancel < status_throw && status_throw < redirect && redirect < redirect_cancel &&
      redirect_cancel < redirect_throw && redirect_throw < media && media < media_cancel &&
      media_cancel < media_throw)
  }
' "$PHOTOS"; then
  printf '%s\n' "Unread photo bodies must be cancelled immediately before each validation error." >&2
  exit 1
fi

if ! awk '
  /contentLength !== null && contentLength > MAX_PHOTO_RESPONSE_BYTES/ { oversized = NR }
  oversized && /cancelUnreadPhotoResponse\(response\);/ && !oversized_cancel { oversized_cancel = NR }
  oversized_cancel && /throw new Error\('\''Photo response body is too large/ { oversized_throw = NR }
  /typeof response\.body\?\.getReader !== '\''function'\''/ { unstreamable = NR }
  unstreamable && /cancelUnreadPhotoResponse\(response\);/ && !unstreamable_cancel { unstreamable_cancel = NR }
  unstreamable_cancel && /throw new Error\('\''Photo response body must be a readable stream/ { unstreamable_throw = NR }
  END {
    exit !(oversized && oversized_cancel && oversized_throw && unstreamable &&
      unstreamable_cancel && unstreamable_throw && oversized < oversized_cancel &&
      oversized_cancel < oversized_throw && oversized_throw < unstreamable &&
      unstreamable < unstreamable_cancel && unstreamable_cancel < unstreamable_throw)
  }
' "$PHOTOS"; then
  printf '%s\n' "Oversized and unstreamable photo responses must cancel before rejection." >&2
  exit 1
fi

if ! awk '
  /export async function readBoundedPhotoJson/ { in_reader = 1 }
  /export function isRenderablePhoto/ { in_reader = 0 }
  in_reader && /const contentLengthHeader = response\.headers/ { header = NR }
  in_reader && /contentLength = parseContentLength\(contentLengthHeader\);/ { parse = NR }
  in_reader && /catch \(error\)/ { caught = NR }
  in_reader && caught && /cancelUnreadPhotoResponse\(response\);/ && !cancelled { cancelled = NR }
  in_reader && cancelled && /throw error;/ { rethrow = NR }
  END {
    exit !(header && parse && caught && cancelled && rethrow &&
      header < parse && parse < caught && caught < cancelled && cancelled < rethrow)
  }
' "$PHOTOS"; then
  printf '%s\n' "Malformed photo Content-Length values must cancel before rethrowing validation errors." >&2
  exit 1
fi

content_length_cancel_tests=$(awk '
  /^test.*cancels a photo response with a nonnumeric content length/ { capture = 1 }
  capture && /^test.*cancels a streamed photo response/ { exit }
  capture { print }
' "$APP_TEST")
for content_length_cancel_test in \
  "cancels a photo response with a nonnumeric content length" \
  "headers: jsonHeaders('application/json', 'not-a-number')" \
  "Photo response Content-Length must be numeric." \
  "cancels a photo response with an unsafe content length" \
  "headers: jsonHeaders('application/json', '9007199254740992')" \
  "Photo response Content-Length is outside the safe range."; do
  if ! printf '%s\n' "$content_length_cancel_tests" | grep -Fq "$content_length_cancel_test"; then
    printf '%s\n' "Content-Length cleanup test contract is missing: $content_length_cancel_test" >&2
    exit 1
  fi
done
if [ "$(printf '%s\n' "$content_length_cancel_tests" | grep -Fc 'expect(cancel).toHaveBeenCalledOnce();')" -ne 2 ]; then
  printf '%s\n' "Both malformed Content-Length regressions must assert unread-body cancellation." >&2
  exit 1
fi

content_length_cancel_guidance='Malformed and unsafe-range photo Content-Length declarations cancel unread bodies before preserving validation errors.'
for content_length_cancel_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "$content_length_cancel_guidance" "$content_length_cancel_doc"; then
    printf '%s\n' "$content_length_cancel_doc must document malformed Content-Length cleanup." >&2
    exit 1
  fi
done

for content_length_cancel_plan_contract in \
  "status: completed" \
  "make check" \
  "hostile mutations" \
  "Live endpoint and cross-browser transport testing were not performed"; do
  if ! grep -Fqi "$content_length_cancel_plan_contract" "$CONTENT_LENGTH_CANCEL_PLAN"; then
    printf '%s\n' "Content-Length cancellation plan must record completion evidence: $content_length_cancel_plan_contract" >&2
    exit 1
  fi
done

for response_envelope_cancel_test in \
  "rejects a declared oversized photo response before reading" \
  "rejects an unstreamable photo response without whole-body fallback"; do
  if ! grep -Fq "$response_envelope_cancel_test" "$APP_TEST"; then
    printf '%s\n' "Response envelope cleanup test is missing: $response_envelope_cancel_test" >&2
    exit 1
  fi
done
if [ "$(grep -Fc 'expect(cancel).toHaveBeenCalledOnce();' "$APP_TEST")" -lt 5 ]; then
  printf '%s\n' "Pre-read response tests must assert cancellation on all envelope failures." >&2
  exit 1
fi

for response_envelope_cancel_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Oversized and unstreamable photo response envelopes cancel unread bodies" \
      "$response_envelope_cancel_doc"; then
    printf '%s\n' "$response_envelope_cancel_doc must document response envelope cleanup." >&2
    exit 1
  fi
done

for response_envelope_cancel_plan_contract in \
  "status: completed" \
  "make check" \
  "hostile mutations" \
  "Live endpoint and cross-browser transport testing were not performed"; do
  if ! grep -Fqi "$response_envelope_cancel_plan_contract" "$RESPONSE_ENVELOPE_CANCEL_PLAN"; then
    printf '%s\n' "Response envelope cancellation plan must record completion evidence: $response_envelope_cancel_plan_contract" >&2
    exit 1
  fi
done

for rejected_response_test in \
  "renders an error state when the photo request is not ok" \
  "rejects a redirected photo response before reading headers or body" \
  "rejects a successful non-JSON photo response before parsing"; do
  if ! grep -Fq "$rejected_response_test" "$APP_TEST"; then
    printf '%s\n' "Rejected response cleanup test is missing: $rejected_response_test" >&2
    exit 1
  fi
done
if [ "$(grep -Fc 'expect(cancel).toHaveBeenCalledOnce();' "$APP_TEST")" -lt 3 ]; then
  printf '%s\n' "Rejected response tests must assert body cancellation on every pre-read path." >&2
  exit 1
fi

for rejected_response_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! grep -Fq "Pre-read photo response rejection initiates best-effort body cancellation" \
      "$rejected_response_doc"; then
    printf '%s\n' "$rejected_response_doc must document pre-read response body cancellation." >&2
    exit 1
  fi
done

for rejected_response_plan_contract in \
  "Status: Completed" \
  "make check" \
  "Ten hostile mutations" \
  "cross-browser response-body cancellation were not exercised"; do
  if ! grep -Fqi "$rejected_response_plan_contract" "$REJECTED_RESPONSE_CANCEL_PLAN"; then
    printf '%s\n' "Rejected response cancellation plan must record completion evidence: $rejected_response_plan_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "expect(reader.read).toHaveBeenCalledTimes(chunks.length + 1)" "$APP_TEST" || \
   ! grep -Fq "Array.from(utf8.encode(json), (byte)" "$APP_TEST"; then
  printf '%s\n' "Photo stream tests must exercise high-fragmentation one-byte chunks." >&2
  exit 1
fi

if [ ! -f "$RESPONSE_BODY_LIMIT_PLAN" ] || \
   ! grep -Fq "status: completed" "$RESPONSE_BODY_LIMIT_PLAN" || \
   ! grep -Fq "## Status: Completed" "$RESPONSE_BODY_LIMIT_PLAN" || \
   ! grep -Fq "make check" "$RESPONSE_BODY_LIMIT_PLAN" || \
   ! grep -Fq "hostile mutations" "$RESPONSE_BODY_LIMIT_PLAN"; then
  printf '%s\n' "Photo response body limit plan must record completed verification." >&2
  exit 1
fi

for response_body_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$response_body_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "2 MiB photo response body limit"; then
    printf '%s\n' "$response_body_doc must document the 2 MiB photo response body limit." >&2
    exit 1
  fi
done

if [ ! -f "$STREAM_BUFFER_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STREAM_BUFFER_PLAN" || \
   ! grep -Fq "Verification: Completed" "$STREAM_BUFFER_PLAN" || \
   ! grep -Fq "Nine focused hostile mutations" "$STREAM_BUFFER_PLAN" || \
   ! grep -Fq "yarn verify" "$STREAM_BUFFER_PLAN"; then
  printf '%s\n' "Photo stream buffer plan must record completed verification." >&2
  exit 1
fi

for stream_buffer_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$stream_buffer_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "contiguous bounded buffer"; then
    printf '%s\n' "$stream_buffer_doc must document contiguous bounded buffer handling." >&2
    exit 1
  fi
done

for stream_timeout_contract in \
  "cancelResponseBody: null" \
  "this.cancelPhotoResponseBody(request)" \
  "return readPhotoStream(response.body, setReaderCancel)" \
  "request.cancelResponseBody = cancelResponseBody"; do
  if ! grep -Fq "$stream_timeout_contract" "$PHOTOS"; then
    printf '%s\n' "Missing timed-out stream cancellation contract: $stream_timeout_contract" >&2
    exit 1
  fi
done

if [ "$(grep -Fc "this.cancelPhotoResponseBody(request)" "$PHOTOS")" -ne 2 ]; then
  printf '%s\n' "Photo response readers must be cancelled on timeout and active-request cleanup." >&2
  exit 1
fi

if ! grep -Fq "cancels a pending photo stream on timeout without abort support" "$APP_TEST" || \
   ! grep -Fq "cancels a pending photo stream on unmount without abort support" "$APP_TEST" || \
   ! grep -Fq "expect(releaseLock).toHaveBeenCalledTimes(1)" "$APP_TEST"; then
  printf '%s\n' "Tests must cover reader cancellation and lock release without AbortController." >&2
  exit 1
fi

if [ ! -f "$STREAM_TIMEOUT_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$STREAM_TIMEOUT_PLAN" || \
   ! grep -Fq "Verification: Completed" "$STREAM_TIMEOUT_PLAN" || \
   ! grep -Fq "focused hostile mutations" "$STREAM_TIMEOUT_PLAN" || \
   ! grep -Fq "make check" "$STREAM_TIMEOUT_PLAN"; then
  printf '%s\n' "Photo stream timeout cancellation plan must record completed verification." >&2
  exit 1
fi

for stream_timeout_doc in "$ROOT_DIR/AGENTS.md" "$README" "$ROOT_DIR/SECURITY.md" \
  "$ROOT_DIR/VISION.md" "$ROOT_DIR/CHANGES.md"; do
  if ! tr '\n' ' ' < "$stream_timeout_doc" | tr -s '[:space:]' ' ' | \
      grep -Fiq "cancel pending response readers"; then
    printf '%s\n' "$stream_timeout_doc must document timed-out response reader cancellation." >&2
    exit 1
  fi
done

for content_type_test in \
  "recognizes explicit JSON response media types" \
  "rejects a successful photo response without a content type" \
  "rejects a successful non-JSON photo response before parsing"; do
  if ! grep -Fq "$content_type_test" "$APP_TEST"; then
    printf '%s\n' "Missing photo response content-type regression test: $content_type_test" >&2
    exit 1
  fi
done

if ! grep -Fq "Successful photo responses must declare an application JSON media type" "$README" || \
   ! grep -Fq "2026-06-13-photo-response-content-type.md" "$README"; then
  printf '%s\n' "README must document photo response content-type validation and its plan." >&2
  exit 1
fi

if [ ! -f "$CONTENT_TYPE_PLAN" ] || \
   ! grep -Fq "status: completed" "$CONTENT_TYPE_PLAN" || \
   ! grep -Fq "## Status: Completed" "$CONTENT_TYPE_PLAN" || \
   ! grep -Fq "make check" "$CONTENT_TYPE_PLAN" || \
   ! grep -Fq "Ten isolated hostile mutations were rejected" "$CONTENT_TYPE_PLAN"; then
  printf '%s\n' "Photo response content-type plan must record completed status and verification." >&2
  exit 1
fi

if ! grep -Fq "not ok" "$APP_TEST"; then
  printf '%s\n' "Tests must cover non-OK HTTP responses." >&2
  exit 1
fi

if ! grep -Fq "photo response is not an array" "$APP_TEST"; then
  printf '%s\n' "Tests must cover non-array photo responses." >&2
  exit 1
fi

if ! grep -Fq "photo item is missing render fields" "$APP_TEST"; then
  printf '%s\n' "Tests must cover malformed photo item responses." >&2
  exit 1
fi

if ! grep -Fq "photo ids are duplicated" "$APP_TEST"; then
  printf '%s\n' "Tests must cover duplicate photo id responses." >&2
  exit 1
fi

if ! grep -Fq "photo id is not a string or finite number" "$APP_TEST"; then
  printf '%s\n' "Tests must cover non-renderable photo id responses." >&2
  exit 1
fi

if ! grep -Fq "does not update state after unmounting during photo load" "$APP_TEST"; then
  printf '%s\n' "Tests must cover async photo loading after component unmount." >&2
  exit 1
fi

if ! grep -Fq "aborts pending photo fetch after unmount" "$APP_TEST"; then
  printf '%s\n' "Tests must cover aborting pending photo fetches after unmount." >&2
  exit 1
fi

if ! grep -Fq "ignores a superseded request after the same instance remounts" "$APP_TEST" || \
   ! grep -Fq "expect(component.setState).toHaveBeenCalledTimes(1)" "$APP_TEST"; then
  printf '%s\n' "Tests must cover superseded request completion after remount." >&2
  exit 1
fi

for timeout_test_contract in \
  "aborts and renders an error when the photo request times out" \
  "cancels a pending photo stream on timeout without abort support" \
  "global.AbortController = undefined" \
  "vi.useFakeTimers()" \
  "vi.advanceTimersByTimeAsync(PHOTO_REQUEST_TIMEOUT_MS)"; do
  if ! grep -Fq "$timeout_test_contract" "$APP_TEST"; then
    printf '%s\n' "Missing photo timeout test contract: $timeout_test_contract" >&2
    exit 1
  fi
done

if ! grep -Fq "photo thumbnail URL is not HTTPS" "$APP_TEST"; then
  printf '%s\n' "Tests must cover insecure thumbnail URL responses." >&2
  exit 1
fi

if ! grep -Fq "photo thumbnail URL includes credentials" "$APP_TEST"; then
  printf '%s\n' "Tests must cover credentialed thumbnail URL responses." >&2
  exit 1
fi

if ! grep -Fq "trims photo titles and normalizes thumbnail URLs before rendering" "$APP_TEST"; then
  printf '%s\n' "Tests must cover accepted photo render field normalization." >&2
  exit 1
fi

if ! grep -Fq "loads thumbnails lazily without sending a referrer" "$APP_TEST" || \
   ! grep -Fq "toHaveAttribute('referrerpolicy', 'no-referrer')" "$APP_TEST"; then
  printf '%s\n' "Tests must cover thumbnail referrer privacy." >&2
  exit 1
fi

if ! grep -Fq "malformed photo is beyond the render limit" "$APP_TEST"; then
  printf '%s\n' "Tests must cover malformed photos beyond the display limit." >&2
  exit 1
fi

if ! grep -Fq "limits rendered photos from large API responses" "$APP_TEST"; then
  printf '%s\n' "Tests must cover large photo response limits." >&2
  exit 1
fi

if ! grep -Fq '"lint": "eslint src vite.config.js eslint.config.js"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose an explicit lint gate." >&2
  exit 1
fi

if ! grep -Fq "yarn lint && yarn format:check && yarn test && yarn build" "$PACKAGE_JSON"; then
  printf '%s\n' "package.json verify script must run lint, format, tests, and build." >&2
  exit 1
fi

if ! grep -Fq "sh scripts/check-baseline.sh" "$README"; then
  printf '%s\n' "README must document the source baseline check." >&2
  exit 1
fi

if grep -Fq "npm install" "$README"; then
  printf '%s\n' "README must not document npm install for a Yarn-lockfile project." >&2
  exit 1
fi

if ! grep -Fq "corepack yarn install --frozen-lockfile" "$README"; then
  printf '%s\n' "README must document Corepack-backed Yarn install." >&2
  exit 1
fi

if ! grep -Fq "corepack yarn lint" "$README"; then
  printf '%s\n' "README must document the lint gate." >&2
  exit 1
fi

if ! grep -Fq "corepack yarn test" "$README"; then
  printf '%s\n' "README must document the CI test gate." >&2
  exit 1
fi

if ! grep -Fq "Vite" "$README" || ! grep -Fq "Vitest" "$README"; then
  printf '%s\n' "README must document the Vite and Vitest toolchain." >&2
  exit 1
fi

if ! grep -Fq "GitHub Actions" "$README"; then
  printf '%s\n' "README must document hosted verification." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$TOOLCHAIN_PLAN" || ! grep -Fq "make check" "$TOOLCHAIN_PLAN"; then
  printf '%s\n' "Vite migration plan must record completed status and verification." >&2
  exit 1
fi

if ! grep -Fq "corepack yarn build" "$README"; then
  printf '%s\n' "README must document the production build gate." >&2
  exit 1
fi

if ! grep -Fq "corepack yarn verify" "$README"; then
  printf '%s\n' "README must document the combined verify gate." >&2
  exit 1
fi

if ! grep -Fq "Photo IDs must be non-empty strings or finite numbers" "$README"; then
  printf '%s\n' "README must document key-safe photo id validation." >&2
  exit 1
fi

if ! grep -Fq "Thumbnail URLs with embedded credentials are rejected" "$README"; then
  printf '%s\n' "README must document credentialed thumbnail URL rejection." >&2
  exit 1
fi

if ! grep -Fq "Thumbnails load lazily with a no-referrer policy" "$README"; then
  printf '%s\n' "README must document thumbnail referrer privacy." >&2
  exit 1
fi

if ! grep -Fq "Pending photo loads are aborted when the component unmounts" "$README"; then
  printf '%s\n' "README must document pending photo fetch abort handling." >&2
  exit 1
fi

if ! grep -Fq "Photo requests time out after 10 seconds" "$README"; then
  printf '%s\n' "README must document the photo request timeout." >&2
  exit 1
fi

if ! grep -Fq "Each photo request owns its timeout and abort controller" "$README"; then
  printf '%s\n' "README must document photo request ownership." >&2
  exit 1
fi

if ! grep -Fq "CHANGES.md" "$README"; then
  printf '%s\n' "README must point to CHANGES.md." >&2
  exit 1
fi

if ! grep -Fq "sh scripts/check-baseline.sh" "$PACKAGE_JSON"; then
  printf '%s\n' "package.json verify script must run the baseline check." >&2
  exit 1
fi

if [ ! -f "$THUMBNAIL_CREDENTIAL_PLAN" ]; then
  printf '%s\n' "Photo thumbnail credential validation plan is missing." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$THUMBNAIL_CREDENTIAL_PLAN" || ! grep -Fq "make check" "$THUMBNAIL_CREDENTIAL_PLAN"; then
  printf '%s\n' "Photo thumbnail credential validation plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$PHOTO_ABORT_PLAN" ]; then
  printf '%s\n' "Photo fetch abort guard plan is missing." >&2
  exit 1
fi

if ! grep -Fq "status: completed" "$PHOTO_ABORT_PLAN" || ! grep -Fq "make check" "$PHOTO_ABORT_PLAN"; then
  printf '%s\n' "Photo fetch abort guard plan must record completed status and make check verification." >&2
  exit 1
fi

if [ ! -f "$PHOTO_TIMEOUT_PLAN" ]; then
  printf '%s\n' "Photo request timeout plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$PHOTO_TIMEOUT_PLAN" || ! grep -Fq "make check" "$PHOTO_TIMEOUT_PLAN"; then
  printf '%s\n' "Photo request timeout plan must record completed status and verification." >&2
  exit 1
fi

if [ ! -f "$REQUEST_OWNERSHIP_PLAN" ]; then
  printf '%s\n' "Photo request ownership plan is missing." >&2
  exit 1
fi

if ! grep -Fq "Status: Completed" "$REQUEST_OWNERSHIP_PLAN" || \
   ! grep -Fq "make check" "$REQUEST_OWNERSHIP_PLAN"; then
  printf '%s\n' "Photo request ownership plan must record completed status and verification." >&2
  exit 1
fi

if [ ! -f "$THUMBNAIL_REFERRER_PLAN" ] || \
   ! grep -Fq "Status: Completed" "$THUMBNAIL_REFERRER_PLAN" || \
   ! grep -Fq "make check" "$THUMBNAIL_REFERRER_PLAN"; then
  printf '%s\n' "Photo thumbnail referrer plan must record completed status and verification." >&2
  exit 1
fi

printf '%s\n' "API React example baseline checks passed."
