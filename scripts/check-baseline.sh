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
WORKFLOW="$ROOT_DIR/.github/workflows/check.yml"

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
  '"vite": "8.0.16"' \
  '"vitest": "4.1.8"'; do
  if ! grep -Fq "$dependency" "$PACKAGE_JSON"; then
    printf '%s\n' "Expected dependency pin is missing: $dependency" >&2
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
  "createPhotoRequestTimeout(request)" \
  "setTimeout(() =>" \
  "request.abortController.abort()" \
  "reject(new Error('Photo request timed out.'))" \
  "Promise.race([" \
  "async fetchPhotos(requestOptions)" \
  "const photoRequest = this.fetchPhotos(requestOptions)" \
  "clearPhotoRequestTimeout(request)" \
  "clearTimeout(request.timeoutId)"; do
  if ! grep -Fq "$timeout_contract" "$PHOTOS"; then
    printf '%s\n' "Missing photo request timeout contract: $timeout_contract" >&2
    exit 1
  fi
done

if grep -Fq "const photoRequest = await this.fetchPhotos(requestOptions)" "$PHOTOS"; then
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
  "times out while parsing photos without abort support" \
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

printf '%s\n' "API React example baseline checks passed."
