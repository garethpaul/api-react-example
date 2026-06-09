#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE_JSON="$ROOT_DIR/package.json"
PHOTOS="$ROOT_DIR/src/components/Photos.js"
APP_TEST="$ROOT_DIR/src/App.test.js"
README="$ROOT_DIR/README.md"
RECORD_SHAPE_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-record-shape-validation.md"
THUMBNAIL_URL_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-thumbnail-url-validation.md"
RENDER_FIELD_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-render-field-normalization.md"
DUPLICATE_ID_PLAN="$ROOT_DIR/docs/plans/2026-06-09-photo-duplicate-id-validation.md"

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

if [ -f "$ROOT_DIR/package-lock.json" ]; then
  printf '%s\n' "Yarn is the lockfile source of truth; package-lock.json must not be present." >&2
  exit 1
fi

if git -C "$ROOT_DIR" ls-files 'node_modules/*' 'build/*' | grep -q .; then
  printf '%s\n' "Generated node_modules/ and build/ artifacts must not be tracked." >&2
  exit 1
fi

for dependency in \
  '"react": "18.3.1"' \
  '"react-dom": "18.3.1"' \
  '"react-scripts": "5.0.1"'; do
  if ! grep -Fq "$dependency" "$PACKAGE_JSON"; then
    printf '%s\n' "Expected dependency pin is missing: $dependency" >&2
    exit 1
  fi
done

if ! grep -Fq 'PHOTO_ENDPOINT = '\''https://jsonplaceholder.typicode.com/photos'\''' "$PHOTOS"; then
  printf '%s\n' "Photo endpoint must stay on HTTPS JSONPlaceholder." >&2
  exit 1
fi

if ! grep -Fq "componentDidMount()" "$PHOTOS"; then
  printf '%s\n' "Photo loading must use componentDidMount instead of deprecated lifecycle hooks." >&2
  exit 1
fi

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

if ! grep -Fq "String(photo.id)" "$PHOTOS" || ! grep -Fq "!hasUniquePhotoIds(photos)" "$PHOTOS"; then
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

if ! grep -Fq "photo thumbnail URL is not HTTPS" "$APP_TEST"; then
  printf '%s\n' "Tests must cover insecure thumbnail URL responses." >&2
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

if ! grep -Fq '"lint": "eslint src --max-warnings=0"' "$PACKAGE_JSON"; then
  printf '%s\n' "package.json must expose an explicit lint gate." >&2
  exit 1
fi

if ! grep -Fq "eslint src --max-warnings=0 && CI=true react-scripts test --watchAll=false" "$PACKAGE_JSON"; then
  printf '%s\n' "package.json verify script must run lint before tests." >&2
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

if ! grep -Fq "CI=true corepack yarn test --watchAll=false" "$README"; then
  printf '%s\n' "README must document the CI test gate." >&2
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

if ! grep -Fq "CHANGES.md" "$README"; then
  printf '%s\n' "README must point to CHANGES.md." >&2
  exit 1
fi

if ! grep -Fq "sh scripts/check-baseline.sh" "$PACKAGE_JSON"; then
  printf '%s\n' "package.json verify script must run the baseline check." >&2
  exit 1
fi

printf '%s\n' "API React example baseline checks passed."
