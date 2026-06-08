#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PACKAGE_JSON="$ROOT_DIR/package.json"
PHOTOS="$ROOT_DIR/src/components/Photos.js"
APP_TEST="$ROOT_DIR/src/App.test.js"
README="$ROOT_DIR/README.md"

if [ ! -f "$ROOT_DIR/CHANGES.md" ]; then
  printf '%s\n' "CHANGES.md must document repository maintenance." >&2
  exit 1
fi

if ! grep -Fq "API React Example Changes" "$ROOT_DIR/CHANGES.md"; then
  printf '%s\n' "CHANGES.md must identify the project." >&2
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

if ! grep -Fq "mockFetchSuccess" "$APP_TEST"; then
  printf '%s\n' "Tests must mock fetch success without network access." >&2
  exit 1
fi

if ! grep -Fq "not ok" "$APP_TEST"; then
  printf '%s\n' "Tests must cover non-OK HTTP responses." >&2
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
