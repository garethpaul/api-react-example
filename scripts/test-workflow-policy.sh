#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
CHECKER="$ROOT_DIR/scripts/check-workflow-policy.mjs"
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/api-react-workflow-policy.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT HUP INT TERM

PASS_COUNT=0

new_fixture() {
  name=$1
  fixture="$TMP_ROOT/$name"
  mkdir -p "$fixture/.github/workflows"
  cp "$ROOT_DIR/.github/workflows/check.yml" "$fixture/.github/workflows/check.yml"
  git -C "$fixture" init -q
  git -C "$fixture" add .
  printf '%s\n' "$fixture"
}

track_fixture() {
  git -C "$1" add -A
}

expect_accept() {
  fixture=$1
  if [ -n "${ACTIONLINT:-}" ]; then
    find "$fixture/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print0 | \
      xargs -0 "$ACTIONLINT"
  fi
  if ! output=$(node "$CHECKER" "$fixture" 2>&1); then
    printf '%s\n' "expected policy acceptance for $fixture" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
  PASS_COUNT=$((PASS_COUNT + 1))
}

expect_reject() {
  fixture=$1
  expected=$2
  if output=$(node "$CHECKER" "$fixture" 2>&1); then
    printf '%s\n' "expected policy rejection for $fixture" >&2
    exit 1
  fi
  if ! printf '%s\n' "$output" | grep -Fq "$expected"; then
    printf '%s\n' "expected rejection containing: $expected" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi
  PASS_COUNT=$((PASS_COUNT + 1))
}

baseline=$(new_fixture baseline)
expect_accept "$baseline"

writable_permissions=$(new_fixture writable-permissions)
sed -i.bak 's/contents: read/contents: write/' "$writable_permissions/.github/workflows/check.yml"
rm "$writable_permissions/.github/workflows/check.yml.bak"
track_fixture "$writable_permissions"
expect_reject "$writable_permissions" "canonical Check workflow contract changed"

appended_authenticated_command=$(new_fixture appended-authenticated-command)
cat >>"$appended_authenticated_command/.github/workflows/check.yml" <<'EOF'
      - name: Exfiltrate token
        run: gh api /user
EOF
track_fixture "$appended_authenticated_command"
expect_reject "$appended_authenticated_command" "canonical Check workflow contract changed"

bracket_github_token=$(new_fixture bracket-github-token)
cat >"$bracket_github_token/.github/workflows/token.yml" <<'EOF'
name: Bracket GitHub token
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  token:
    runs-on: ubuntu-24.04
    env:
      GH_TOKEN: ${{ github['token'] }}
    steps:
      - run: gh api /user
EOF
track_fixture "$bracket_github_token"
expect_reject "$bracket_github_token" "workflow policy forbids credential expressions"

bracket_secret=$(new_fixture bracket-secret)
cat >"$bracket_secret/.github/workflows/token.yml" <<'EOF'
name: Bracket secret
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  token:
    runs-on: ubuntu-24.04
    env:
      GH_TOKEN: ${{ secrets['DEPLOY_TOKEN'] }}
    steps:
      - run: gh api /user
EOF
track_fixture "$bracket_secret"
expect_reject "$bracket_secret" "workflow policy forbids credential expressions"

computed_secret=$(new_fixture computed-secret)
cat >"$computed_secret/.github/workflows/token.yml" <<'EOF'
name: Computed secret
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  token:
    runs-on: ubuntu-24.04
    env:
      GH_TOKEN: ${{ secrets[format('{0}', 'GITHUB_TOKEN')] }}
    steps:
      - run: gh api /user
EOF
track_fixture "$computed_secret"
expect_reject "$computed_secret" "workflow policy forbids credential expressions"

serialized_github_context=$(new_fixture serialized-github-context)
cat >"$serialized_github_context/.github/workflows/sarif.yml" <<'EOF'
name: Serialized GitHub context
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    env:
      GITHUB_CONTEXT: ${{ toJSON(github) }}
    steps:
      - run: printf '%s' "$GITHUB_CONTEXT" | jq -r .token
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$serialized_github_context"
expect_reject "$serialized_github_context" "workflow policy forbids credential expressions"

serialized_secrets_context=$(new_fixture serialized-secrets-context)
cat >"$serialized_secrets_context/.github/workflows/token.yml" <<'EOF'
name: Serialized secrets context
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  token:
    runs-on: ubuntu-24.04
    env:
      ALL_SECRETS: ${{ toJSON(secrets) }}
    steps:
      - run: printf '%s' "$ALL_SECRETS"
EOF
track_fixture "$serialized_secrets_context"
expect_reject "$serialized_secrets_context" "workflow policy forbids credential expressions"

job_env=$(new_fixture job-env)
perl -0pi -e 's/    runs-on: ubuntu-24\.04/    runs-on: ubuntu-24.04\n    env:\n      GH_TOKEN: \$\{\{ github.token \}\}/' "$job_env/.github/workflows/check.yml"
track_fixture "$job_env"
expect_reject "$job_env" "canonical Check workflow contract changed"

job_defaults=$(new_fixture job-defaults)
perl -0pi -e 's/    runs-on: ubuntu-24\.04/    runs-on: ubuntu-24.04\n    defaults:\n      run:\n        shell: bash -e \{0\}/' "$job_defaults/.github/workflows/check.yml"
track_fixture "$job_defaults"
expect_reject "$job_defaults" "canonical Check workflow contract changed"

job_condition=$(new_fixture job-condition)
perl -0pi -e 's/    runs-on: ubuntu-24\.04/    runs-on: ubuntu-24.04\n    if: always\(\)/' "$job_condition/.github/workflows/check.yml"
track_fixture "$job_condition"
expect_reject "$job_condition" "canonical Check workflow contract changed"

safe_unrelated=$(new_fixture safe-unrelated)
cat >"$safe_unrelated/.github/workflows/docs.yml" <<'EOF'
name: Docs check
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  docs:
    runs-on: ubuntu-24.04
    steps:
      - run: echo docs
EOF
track_fixture "$safe_unrelated"
expect_accept "$safe_unrelated"

tagged_unrelated=$(new_fixture tagged-unrelated)
cat >"$tagged_unrelated/.github/workflows/tagged.yml" <<'EOF'
name: Tagged check
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  tagged:
    runs-on: ubuntu-24.04
    steps:
      - run: !!str echo tagged
EOF
track_fixture "$tagged_unrelated"
expect_accept "$tagged_unrelated"

upload_sarif=$(new_fixture upload-sarif)
cat >"$upload_sarif/.github/workflows/sarif.yml" <<'EOF'
name: Upload third-party SARIF
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
        with:
          sarif_file: results.sarif
EOF
track_fixture "$upload_sarif"
expect_accept "$upload_sarif"

workflow_wide_sarif_permission=$(new_fixture workflow-wide-sarif-permission)
cat >"$workflow_wide_sarif_permission/.github/workflows/sarif.yml" <<'EOF'
name: Over-broad SARIF permission
on:
  workflow_dispatch:
permissions:
  contents: read
  security-events: write
jobs:
  upload:
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
  unrelated:
    runs-on: ubuntu-24.04
    steps:
      - run: echo unrelated
EOF
track_fixture "$workflow_wide_sarif_permission"
expect_reject "$workflow_wide_sarif_permission" "workflow-level security-events: write is forbidden"

upload_sarif_without_permission=$(new_fixture upload-sarif-without-permission)
cat >"$upload_sarif_without_permission/.github/workflows/sarif.yml" <<'EOF'
name: Upload third-party SARIF
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upload:
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$upload_sarif_without_permission"
expect_reject "$upload_sarif_without_permission" "upload-sarif requires security-events: write"

advanced_codeql=$(new_fixture advanced-codeql)
cat >"$advanced_codeql/.github/workflows/security.yml" <<'EOF'
name: Advanced CodeQL
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  analyze:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/init@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$advanced_codeql"
expect_reject "$advanced_codeql" "advanced CodeQL actions are forbidden"

case_variant_codeql=$(new_fixture case-variant-codeql)
cat >"$case_variant_codeql/.github/workflows/security.yml" <<'EOF'
name: Case variant CodeQL
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  analyze:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: GitHub/codeql-action/init@0123456789abcdef0123456789abcdef01234567
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$case_variant_codeql"
expect_reject "$case_variant_codeql" "advanced CodeQL actions are forbidden"

unpinned_action=$(new_fixture unpinned-action)
cat >"$unpinned_action/.github/workflows/unpinned.yml" <<'EOF'
name: Unpinned action
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v6
EOF
track_fixture "$unpinned_action"
expect_reject "$unpinned_action" "remote actions must use a full commit SHA"

safe_local_action=$(new_fixture safe-local-action)
mkdir -p "$safe_local_action/.github/actions/echo"
cat >"$safe_local_action/.github/actions/echo/action.yml" <<'EOF'
name: Echo
description: Echo safely
runs:
  using: composite
  steps:
    - shell: bash
      run: echo safe
EOF
cat >"$safe_local_action/.github/workflows/local.yml" <<'EOF'
name: Local action
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: ./.github/actions/echo
EOF
track_fixture "$safe_local_action"
expect_accept "$safe_local_action"

local_composite_codeql=$(new_fixture local-composite-codeql)
mkdir -p "$local_composite_codeql/.github/actions/codeql-wrapper"
cat >"$local_composite_codeql/.github/actions/codeql-wrapper/action.yml" <<'EOF'
name: CodeQL wrapper
description: Hidden advanced analysis
runs:
  using: composite
  steps:
    - uses: github/codeql-action/init@0123456789abcdef0123456789abcdef01234567
EOF
cat >"$local_composite_codeql/.github/workflows/local.yml" <<'EOF'
name: Local wrapper
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: ./.github/actions/codeql-wrapper
EOF
track_fixture "$local_composite_codeql"
expect_reject "$local_composite_codeql" "advanced CodeQL actions are forbidden"

safe_local_workflow=$(new_fixture safe-local-workflow)
cat >"$safe_local_workflow/.github/workflows/reusable.yml" <<'EOF'
name: Reusable check
on:
  workflow_call:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - run: echo reusable
EOF
cat >"$safe_local_workflow/.github/workflows/caller.yml" <<'EOF'
name: Local reusable caller
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  call:
    uses: ./.github/workflows/reusable.yml
EOF
track_fixture "$safe_local_workflow"
expect_accept "$safe_local_workflow"

local_reusable_sarif=$(new_fixture local-reusable-sarif)
cat >"$local_reusable_sarif/.github/workflows/reusable.yml" <<'EOF'
name: Reusable SARIF upload
on:
  workflow_call:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
        with:
          sarif_file: results.sarif
EOF
cat >"$local_reusable_sarif/.github/workflows/caller.yml" <<'EOF'
name: Local reusable SARIF caller
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  call:
    permissions:
      contents: read
      security-events: write
    uses: ./.github/workflows/reusable.yml
EOF
track_fixture "$local_reusable_sarif"
expect_accept "$local_reusable_sarif"

local_reusable_sarif_missing_permission=$(new_fixture local-reusable-sarif-missing-permission)
cat >"$local_reusable_sarif_missing_permission/.github/workflows/reusable.yml" <<'EOF'
name: Reusable SARIF upload
on:
  workflow_call:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
cat >"$local_reusable_sarif_missing_permission/.github/workflows/caller.yml" <<'EOF'
name: Under-permissioned reusable SARIF caller
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  call:
    uses: ./.github/workflows/reusable.yml
EOF
track_fixture "$local_reusable_sarif_missing_permission"
expect_reject "$local_reusable_sarif_missing_permission" "upload-sarif requires security-events: write"

local_reusable_codeql=$(new_fixture local-reusable-codeql)
cat >"$local_reusable_codeql/.github/workflows/reusable.yml" <<'EOF'
name: Reusable analysis
on:
  workflow_call:
permissions:
  contents: read
jobs:
  analyze:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/analyze@0123456789abcdef0123456789abcdef01234567
EOF
cat >"$local_reusable_codeql/.github/workflows/caller.yml" <<'EOF'
name: Local reusable caller
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  call:
    uses: ./.github/workflows/reusable.yml
EOF
track_fixture "$local_reusable_codeql"
expect_reject "$local_reusable_codeql" "advanced CodeQL actions are forbidden"

remote_reusable=$(new_fixture remote-reusable)
cat >"$remote_reusable/.github/workflows/remote.yml" <<'EOF'
name: Remote reusable caller
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  call:
    uses: owner/repository/.github/workflows/security.yml@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$remote_reusable"
expect_reject "$remote_reusable" "remote reusable workflows are forbidden"

local_action_cycle=$(new_fixture local-action-cycle)
mkdir -p "$local_action_cycle/.github/actions/a" "$local_action_cycle/.github/actions/b"
cat >"$local_action_cycle/.github/actions/a/action.yml" <<'EOF'
name: A
description: Cycle A
runs:
  using: composite
  steps:
    - uses: ./.github/actions/b
EOF
cat >"$local_action_cycle/.github/actions/b/action.yml" <<'EOF'
name: B
description: Cycle B
runs:
  using: composite
  steps:
    - uses: ./.github/actions/a
EOF
cat >"$local_action_cycle/.github/workflows/cycle.yml" <<'EOF'
name: Local cycle
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: ./.github/actions/a
EOF
track_fixture "$local_action_cycle"
expect_reject "$local_action_cycle" "local reference cycle detected"

local_workflow_cycle=$(new_fixture local-workflow-cycle)
cat >"$local_workflow_cycle/.github/workflows/a.yml" <<'EOF'
name: A
on:
  workflow_call:
permissions:
  contents: read
jobs:
  call:
    uses: ./.github/workflows/b.yml
EOF
cat >"$local_workflow_cycle/.github/workflows/b.yml" <<'EOF'
name: B
on:
  workflow_call:
permissions:
  contents: read
jobs:
  call:
    uses: ./.github/workflows/a.yml
EOF
track_fixture "$local_workflow_cycle"
expect_reject "$local_workflow_cycle" "local reference cycle detected"

unicode_ambiguity=$(new_fixture unicode-ambiguity)
printf '%b\n' \
  'name: Unicode ambiguity' \
  'on:' \
  '  workflow_dispatch:' \
  'permissions:' \
  '  contents: read' \
  'jobs:' \
  '  check:' \
  '    runs-on: ubuntu-24.04' \
  '    steps:' \
  "      - uses:\302\240actions/checkout@0123456789abcdef0123456789abcdef01234567" \
  >"$unicode_ambiguity/.github/workflows/unicode.yml"
track_fixture "$unicode_ambiguity"
expect_reject "$unicode_ambiguity" "ambiguous Unicode whitespace"

duplicate_key=$(new_fixture duplicate-key)
cat >"$duplicate_key/.github/workflows/duplicate.yml" <<'EOF'
name: Duplicate key
on:
  workflow_dispatch:
permissions:
  contents: read
permissions:
  contents: write
jobs: {}
EOF
track_fixture "$duplicate_key"
expect_reject "$duplicate_key" "invalid workflow YAML"

yaml_directive=$(new_fixture yaml-directive)
cat >"$yaml_directive/.github/workflows/directive.yml" <<'EOF'
%YAML 1.1
---
name: Directive
on:
  workflow_dispatch:
permissions:
  contents: read
jobs: {}
EOF
track_fixture "$yaml_directive"
expect_reject "$yaml_directive" "YAML directives are forbidden"

unknown_tag=$(new_fixture unknown-tag)
cat >"$unknown_tag/.github/workflows/tag.yml" <<'EOF'
name: Unknown tag
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - run: !custom echo unsafe
EOF
track_fixture "$unknown_tag"
expect_reject "$unknown_tag" "unsupported YAML tag"

alias_cycle=$(new_fixture alias-cycle)
cat >"$alias_cycle/.github/workflows/alias.yml" <<'EOF'
name: Alias cycle
on:
  workflow_dispatch:
permissions:
  contents: read
jobs: &jobs
  cycle:
    runs-on: ubuntu-24.04
    steps:
      - run: echo cycle
    env: *jobs
EOF
track_fixture "$alias_cycle"
expect_reject "$alias_cycle" "YAML aliases are forbidden"

symlinked_local_action=$(new_fixture symlinked-local-action)
mkdir -p "$symlinked_local_action/outside"
cat >"$symlinked_local_action/outside/action.yml" <<'EOF'
name: Outside
description: Outside action
runs:
  using: composite
  steps:
    - run: echo outside
      shell: bash
EOF
mkdir -p "$symlinked_local_action/.github/actions"
ln -s ../../outside "$symlinked_local_action/.github/actions/linked"
cat >"$symlinked_local_action/.github/workflows/symlink.yml" <<'EOF'
name: Symlinked action
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: ./.github/actions/linked
EOF
track_fixture "$symlinked_local_action"
expect_reject "$symlinked_local_action" "local references must not traverse symlinks"

job_security_events_without_upload=$(new_fixture job-security-events-without-upload)
cat >"$job_security_events_without_upload/.github/workflows/job-permissions.yml" <<'EOF'
name: Excess job permission
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - run: echo no upload
EOF
track_fixture "$job_security_events_without_upload"
expect_reject "$job_security_events_without_upload" "security-events: write is allowed only for upload-sarif"

credential_persisting_checkout=$(new_fixture credential-persisting-checkout)
cat >"$credential_persisting_checkout/.github/workflows/checkout.yml" <<'EOF'
name: Credential-persisting checkout
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567
      - run: git config --get http.https://github.com/.extraheader
EOF
track_fixture "$credential_persisting_checkout"
expect_reject "$credential_persisting_checkout" "checkout must disable persisted credentials"

case_variant_checkout=$(new_fixture case-variant-checkout)
cat >"$case_variant_checkout/.github/workflows/checkout.yml" <<'EOF'
name: Case variant checkout
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: Actions/Checkout@0123456789abcdef0123456789abcdef01234567
      - run: git config --get http.https://github.com/.extraheader
EOF
track_fixture "$case_variant_checkout"
expect_reject "$case_variant_checkout" "checkout must disable persisted credentials"

checkout_dot_subpath=$(new_fixture checkout-dot-subpath)
cat >"$checkout_dot_subpath/.github/workflows/checkout.yml" <<'EOF'
name: Checkout dot subpath
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout/.@0123456789abcdef0123456789abcdef01234567
      - run: git config --get http.https://github.com/.extraheader
EOF
track_fixture "$checkout_dot_subpath"
expect_reject "$checkout_dot_subpath" "remote action is not allowed"

github_script=$(new_fixture github-script)
cat >"$github_script/.github/workflows/script.yml" <<'EOF'
name: Token-bearing script action
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  script:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/github-script@0123456789abcdef0123456789abcdef01234567
        with:
          script: console.log(process.env['INPUT_GITHUB-TOKEN'])
EOF
track_fixture "$github_script"
expect_reject "$github_script" "remote action is not allowed"

safe_checkout=$(new_fixture safe-checkout)
cat >"$safe_checkout/.github/workflows/checkout.yml" <<'EOF'
name: Credential-free checkout
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567
        with:
          persist-credentials: false
      - run: echo safe
EOF
track_fixture "$safe_checkout"
expect_accept "$safe_checkout"

pull_request_target_upload=$(new_fixture pull-request-target-upload)
cat >"$pull_request_target_upload/.github/workflows/sarif.yml" <<'EOF'
name: Privileged pull request upload
on:
  pull_request_target:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$pull_request_target_upload"
expect_reject "$pull_request_target_upload" "upload-sarif is forbidden for pull_request_target"

scalar_pull_request_target_upload=$(new_fixture scalar-pull-request-target-upload)
cat >"$scalar_pull_request_target_upload/.github/workflows/sarif.yml" <<'EOF'
name: Scalar privileged pull request upload
on: pull_request_target
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$scalar_pull_request_target_upload"
expect_reject "$scalar_pull_request_target_upload" "upload-sarif is forbidden for pull_request_target"

sequence_pull_request_target_upload=$(new_fixture sequence-pull-request-target-upload)
cat >"$sequence_pull_request_target_upload/.github/workflows/sarif.yml" <<'EOF'
name: Sequence privileged pull request upload
on: [pull_request_target]
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$sequence_pull_request_target_upload"
expect_reject "$sequence_pull_request_target_upload" "upload-sarif is forbidden for pull_request_target"

mixed_privileged_sarif_job=$(new_fixture mixed-privileged-sarif-job)
cat >"$mixed_privileged_sarif_job/.github/workflows/sarif.yml" <<'EOF'
name: Mixed privileged SARIF job
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/setup-node@0123456789abcdef0123456789abcdef01234567
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$mixed_privileged_sarif_job"
expect_reject "$mixed_privileged_sarif_job" "upload-sarif must be the only action in its privileged job"

sarif_job_environment=$(new_fixture sarif-job-environment)
cat >"$sarif_job_environment/.github/workflows/sarif.yml" <<'EOF'
name: Environment-injected SARIF job
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    env:
      NODE_OPTIONS: --import=data:text/javascript,console.log(process.env)
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
EOF
track_fixture "$sarif_job_environment"
expect_reject "$sarif_job_environment" "privileged upload-sarif jobs must not define env, defaults, or conditions"

sarif_step_environment=$(new_fixture sarif-step-environment)
cat >"$sarif_step_environment/.github/workflows/sarif.yml" <<'EOF'
name: Environment-injected SARIF action
on:
  workflow_dispatch:
permissions:
  contents: read
jobs:
  upload:
    permissions:
      contents: read
      security-events: write
    runs-on: ubuntu-24.04
    steps:
      - uses: github/codeql-action/upload-sarif@0123456789abcdef0123456789abcdef01234567
        env:
          NODE_OPTIONS: --import=data:text/javascript,console.log(process.env)
EOF
track_fixture "$sarif_step_environment"
expect_reject "$sarif_step_environment" "upload-sarif steps must not define env or conditions"

tag_directive=$(new_fixture tag-directive)
cat >"$tag_directive/.github/workflows/tag-directive.yml" <<'EOF'
%TAG !e! tag:example.com,2026:
---
name: Tag directive
on:
  workflow_dispatch:
permissions:
  contents: read
jobs: {}
EOF
track_fixture "$tag_directive"
expect_reject "$tag_directive" "YAML directives are forbidden"

printf '%s\n' "workflow policy tests passed: $PASS_COUNT"
