#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/api-react-make-authority.XXXXXX")
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
unset MAKEFLAGS MAKEFILES MAKEFILE_LIST

MAKE_COMMAND=$(command -v make)
ATTACK_MARKER="$TEMP_ROOT/attack-ran"

assert_rejected() {
  label=$1
  shift
  output="$TEMP_ROOT/$label.out"
  if "$@" >"$output" 2>&1; then
    printf '%s\n' "$label unexpectedly passed" >&2
    cat "$output" >&2
    exit 1
  fi
}

for separator in : ::; do
  later_makefile="$TEMP_ROOT/later-${separator%:}.mk"
  cat >"$later_makefile" <<EOF
build check dependency-policy lint test verify workflow-policy$separator
	@touch '$ATTACK_MARKER'
EOF
  assert_rejected "later-$separator" \
    "$MAKE_COMMAND" --no-print-directory -f "$ROOT_DIR/Makefile" -f "$later_makefile" check
  if [ -e "$ATTACK_MARKER" ]; then
    printf '%s\n' "later $separator recipe executed before rejection" >&2
    exit 1
  fi
done

startup_makefile="$TEMP_ROOT/startup.mk"
cat >"$startup_makefile" <<EOF
build check dependency-policy lint test verify workflow-policy:
	@touch '$ATTACK_MARKER'
EOF
assert_rejected startup-file env MAKEFILES="$startup_makefile" \
  "$MAKE_COMMAND" --no-print-directory -f "$ROOT_DIR/Makefile" check
if [ -e "$ATTACK_MARKER" ]; then
  printf '%s\n' "startup Makefile recipe executed before rejection" >&2
  exit 1
fi

assert_rejected caller-makeflags \
  "$MAKE_COMMAND" --no-print-directory -f "$ROOT_DIR/Makefile" check MAKEFLAGS=-n
assert_rejected command-makefile-list \
  "$MAKE_COMMAND" --no-print-directory -f "$ROOT_DIR/Makefile" check MAKEFILE_LIST=/tmp/untrusted
assert_rejected environment-makefile-list env MAKEFILE_LIST=/tmp/untrusted \
  "$MAKE_COMMAND" --no-print-directory -e -f "$ROOT_DIR/Makefile" check

noop_makefile="$TEMP_ROOT/noop.mk"
printf '%s\n' '# intentionally empty later Makefile' >"$noop_makefile"
assert_rejected noop-later-file \
  "$MAKE_COMMAND" --no-print-directory -f "$ROOT_DIR/Makefile" -f "$noop_makefile" check

for mode in -n --just-print --dry-run --recon -t --touch -q --question -i --ignore-errors; do
  label=$(printf '%s' "$mode" | tr -cd '[:alnum:]')
  assert_rejected "mode-$label" \
    "$MAKE_COMMAND" --no-print-directory "$mode" -f "$ROOT_DIR/Makefile" check
done

CHECKOUT="$TEMP_ROOT/API React's [gate] \`touch API_REACT_PATH_MARKER\`"
CONTROL_DIR="$TEMP_ROOT/control"
COMMAND_LOG="$TEMP_ROOT/commands.log"
BAD_COMMAND_LOG="$TEMP_ROOT/bad-command.log"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
mkdir -p "$CHECKOUT/scripts" "$CHECKOUT/bin" "$CONTROL_DIR"
cp "$ROOT_DIR/Makefile" "$CHECKOUT/Makefile"

cat >"$CHECKOUT/bin/node" <<'EOF'
#!/bin/sh
printf '%s|node %s\n' "$PWD" "$*" >>"$API_REACT_COMMAND_LOG"
EOF
cat >"$CHECKOUT/bin/corepack" <<'EOF'
#!/bin/sh
printf '%s|corepack %s\n' "$PWD" "$*" >>"$API_REACT_COMMAND_LOG"
EOF
chmod +x "$CHECKOUT/bin/node" "$CHECKOUT/bin/corepack"

for script in test-dependency-policy.sh test-workflow-policy.sh check-baseline.sh test-makefile-authority.sh; do
  cat >"$CHECKOUT/scripts/$script" <<'EOF'
#!/bin/sh
printf '%s|script %s\n' "$PWD" "$0" >>"$API_REACT_COMMAND_LOG"
EOF
  chmod +x "$CHECKOUT/scripts/$script"
done
touch "$CHECKOUT/scripts/check-dependency-policy.mjs" "$CHECKOUT/scripts/check-workflow-policy.mjs"

BAD_COMMAND="$TEMP_ROOT/bad-command"
cat >"$BAD_COMMAND" <<EOF
#!/bin/sh
printf '%s\n' invoked >>'$BAD_COMMAND_LOG'
exit 91
EOF
chmod +x "$BAD_COMMAND"

FAKE_SHELL="$TEMP_ROOT/fake-shell"
cat >"$FAKE_SHELL" <<EOF
#!/bin/sh
printf '%s\n' invoked >>'$FAKE_SHELL_LOG'
exec /bin/sh "\$@"
EOF
chmod +x "$FAKE_SHELL"

for target in dependency-policy workflow-policy lint test build verify check; do
  : >"$COMMAND_LOG"
  (
    cd "$CONTROL_DIR"
    API_REACT_COMMAND_LOG="$COMMAND_LOG" \
      PATH="$CHECKOUT/bin:$PATH" \
      "$MAKE_COMMAND" --no-print-directory -f "$CHECKOUT/Makefile" "$target" \
      ROOT=/tmp/api-react-attacker NODE="$BAD_COMMAND" YARN="$BAD_COMMAND" SHELL="$FAKE_SHELL"
  )
  if [ ! -s "$COMMAND_LOG" ]; then
    printf '%s\n' "$target executed no repository command" >&2
    exit 1
  fi
  if grep -Fv "$CHECKOUT|" "$COMMAND_LOG" >/dev/null; then
    printf '%s\n' "$target escaped the checkout" >&2
    cat "$COMMAND_LOG" >&2
    exit 1
  fi
done

if [ -e "$BAD_COMMAND_LOG" ]; then
  printf '%s\n' "caller-selected Node or Yarn command executed" >&2
  exit 1
fi
if [ -e "$FAKE_SHELL_LOG" ]; then
  printf '%s\n' "caller-selected SHELL executed" >&2
  exit 1
fi
if [ -e "$CHECKOUT/API_REACT_PATH_MARKER" ] || [ -e "$CONTROL_DIR/API_REACT_PATH_MARKER" ]; then
  printf '%s\n' "hostile checkout path was evaluated as shell syntax" >&2
  exit 1
fi

printf '%s\n' "API React Make authority tests passed: 2 replacement/append rejections, 1 startup rejection, 1 no-op later-file rejection, 3 caller-variable rejections, 10 unsafe mode rejections, and 7 live target checks"
