#!/usr/bin/env bash
# run.sh — offline test runner for the designer scripts. Discovers and
# runs every scripts/tests/test_*.sh; a test file exits non-zero on failure.
#
# Test conventions (each test_*.sh):
#   - Sandbox: create its own WORK_DIR under a temp dir — never touch a real
#     work/ or $HOME; clean up on exit.
#   - Offline: stub external CLIs by prepending scripts/tests/bin to PATH and
#     placing fake executables there (e.g. a `gh` printing canned JSON per
#     argument pattern). Tests must pass with no network and no credentials.
#   - Determinism: identical input must yield identical output — assert on JSON (jq).
#
# A behavior change in a script updates its test case in the same PR
# (docs/self-modification.md §9).
# The suite: config-reader parity (shell vs the CLI), repo profile detection on
# fixture repos, the fallback theme's tokens, and the build's checks — all offline.
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
for t in "$DIR"/test_*.sh; do
  [ -e "$t" ] || { echo "no tests found in $DIR"; exit 0; }
  name="$(basename "$t")"
  if bash "$t"; then
    echo "PASS  $name"; pass=$((pass + 1))
  else
    echo "FAIL  $name"; fail=$((fail + 1))
  fi
done
echo "tests: $pass pass, $fail fail"
[ "$fail" -eq 0 ] || exit 1
