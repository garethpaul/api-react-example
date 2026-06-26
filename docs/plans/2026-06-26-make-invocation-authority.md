# Make Invocation Authority Plan

Status: Completed

## Goal

Prevent `make check` from reporting success when callers replace the reviewed
verification graph, request a non-executing mode, or redirect repository
commands through caller-selected shell, Node, Yarn, or root values.

## Root cause

The Makefile protected `ROOT` from a direct command-line override, but every
public target still used replaceable single-colon recipes. A later Makefile
could replace all verification leaves with no-ops and return zero. GNU Make's
dry-run, touch, question, and ignore-error modes also returned without proving
the reviewed checks executed.

## Implementation

1. Added a causal shell suite that first reproduced later single-colon recipe
   replacement returning success.
2. Converted public targets to double-colon rules with a shared authority
   prerequisite and a runtime `MAKEFILE_LIST` equality check.
3. Rejected `MAKEFILES`, caller-provided `MAKEFLAGS`, direct or environment
   `MAKEFILE_LIST` overrides, and ten non-executing/error-ignoring modes.
4. Fixed the recipe shell, Node command, Corepack-backed Yarn command, and
   repository-root derivation inside the reviewed Makefile.
5. Added live target checks from an external directory and a checkout path
   containing spaces, quotes, brackets, and shell metacharacters.
6. Made the authority suite a required prerequisite of `verify` and `check`.

## Verification Completed

- RED: a later single-colon Makefile replaced every verification leaf and
  returned success without running Node, lint, tests, or the build.
- `/bin/sh scripts/test-makefile-authority.sh` passed 24 causal authority cases.
- `/bin/sh scripts/check-baseline.sh` passed after registering the new boundary.
- `make check` passed the complete repository gate.
- Absolute external-directory `make -f <repo>/Makefile check` passed.

## Remaining scope

- The authority boundary proves execution of the reviewed repository graph; it
  does not independently attest the host's `make`, `node`, Corepack, or Yarn
  binaries.
