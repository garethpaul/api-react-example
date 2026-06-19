#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECKER="$ROOT_DIR/scripts/check-dependency-policy.mjs"
FIXTURE_DIR=$(mktemp -d)
trap 'rm -rf "$FIXTURE_DIR"' EXIT HUP INT TERM

write_fixture() {
  version=$1
  selector=${2:-undici@^7.25.0}
  cat >"$FIXTURE_DIR/package.json" <<'EOF'
{
  "devDependencies": {
    "jsdom": "29.1.1"
  }
}
EOF
  cat >"$FIXTURE_DIR/yarn.lock" <<EOF
jsdom@29.1.1:
  version "29.1.1"
  dependencies:
    undici "^7.25.0"

$selector:
  version "$version"
EOF
}

expect_accept() {
  version=$1
  write_fixture "$version"
  node "$CHECKER" "$FIXTURE_DIR"
}

expect_reject() {
  version=$1
  selector=${2:-undici@^7.25.0}
  write_fixture "$version" "$selector"
  if node "$CHECKER" "$FIXTURE_DIR" >/dev/null 2>&1; then
    printf '%s\n' "dependency policy unexpectedly accepted undici $version" >&2
    exit 1
  fi
}

expect_reject "7.27.2"
expect_reject "7.28.0-beta.1"
expect_reject "8.0.0"
expect_reject "7.28.0" "not-undici@^7.25.0"
expect_accept "7.28.0"
expect_accept "7.29.1"

printf '%s\n' "dependency policy tests passed"
