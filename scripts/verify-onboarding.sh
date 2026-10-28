#!/usr/bin/env bash
# verify-onboarding.sh — one-shot structure verification of an onboarded Designer.
#
# Runs twice during ONBOARDING — `--config` right after `work/CONFIG.md` is
# written, then a full run at the end (after the sentinel) — and again as an
# upgrade step whenever a version changes what onboarding produces. Shape only:
# required files, required keys, enum values; the data inside is never judged.
# Detects, never repairs. Every FAIL line carries a `fix:`; re-run after fixing
# until it prints PASS.
#
#   ok   <check> — <detail>
#   warn <check> — <detail>                      informational, never blocks
#   FAIL <check> — <problem> — fix: <instruction>
#
#   --config   the CONFIG block only (mid-onboarding: no sentinel, no VERSION yet)
#   (none)     every offline block: definition, toolkit, work/, CONFIG
#   --live     the offline blocks plus `design doctor` and one real build+screenshot
#
# Exit 0 iff nothing FAILed.
set -u
export LC_ALL=C

LIVE=0; STRUCTURE=1
case "${1:-}" in
  (--live)   LIVE=1;;
  (--config) STRUCTURE=0;;
  ('') ;;
  (*) printf 'usage: %s [--config|--live]\n' "$0" >&2; exit 2;;
esac

HOME_DIR="${HOME:-/home/agent}"
WORK="${WORK_DIR:-$HOME_DIR/work}"
CONFIG="$WORK/CONFIG.md"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if ! . "$SCRIPT_DIR/log.sh" 2>/dev/null; then logev() { :; }; fi

CHECKS=0; FAILS=0; WARNS=0
ok()   { CHECKS=$((CHECKS+1)); printf 'ok   %s — %s\n' "$1" "$2"; }
fail() { CHECKS=$((CHECKS+1)); FAILS=$((FAILS+1)); printf 'FAIL %s — %s — fix: %s\n' "$1" "$2" "$3"; }
warn() { WARNS=$((WARNS+1)); printf 'warn %s — %s\n' "$1" "$2"; }

# The same reader the runtime uses, from the same file.
. "$SCRIPT_DIR/lib/config.sh" || { echo "cannot source lib/config.sh" >&2; exit 1; }

if [ "$STRUCTURE" = 1 ]; then
  # ------------------------------------------------------------- definition
  if [ -d "$HOME_DIR/.git" ]; then
    ok definition "checkout at $(git -C "$HOME_DIR" rev-parse --short HEAD 2>/dev/null)"
    leak="$(git -C "$HOME_DIR" status --porcelain 2>/dev/null | grep -E '^\?\? ' | head -3)"
    [ -z "$leak" ] && ok gitignore "no untracked paths visible at \$HOME" \
      || fail gitignore "untracked paths visible: $(printf '%s' "$leak" | tr '\n' ' ')" "fix .gitignore's allowlist; never git add them"
  else
    fail definition "no git checkout at $HOME_DIR" "the kit's seed failed — tell the operator to retry it; never clone over \$HOME"
  fi
  for f in CLAUDE.md ONBOARDING.md kit.yaml toolkit/package.json scripts/install-toolkit.sh; do
    [ -f "$HOME_DIR/$f" ] && ok "file $f" "present" || fail "file $f" "missing" "the checkout is incomplete — tell the operator"
  done
  for s in prototype walkthrough slides demo-video brand copy; do
    [ -f "$HOME_DIR/.agents/skills/$s/SKILL.md" ] && ok "skill $s" "bundled" \
      || fail "skill $s" "missing from .agents/skills/" "the checkout is incomplete — tell the operator"
  done
  [ -f "$HOME/.designer-onboarded" ] && ok sentinel "$(cat "$HOME/.designer-onboarded")" \
    || fail sentinel "\$HOME/.designer-onboarded missing" "finish ONBOARDING.md Step 6"

  # --------------------------------------------------------------- toolkit
  [ -d "$HOME_DIR/toolkit/node_modules/tailwindcss" ] && ok toolkit "packages installed" \
    || fail toolkit "toolkit packages not installed" "bash \"\$HOME/scripts/install-toolkit.sh\""
  [ -x "$HOME_DIR/bin/design" ] && ok command "\$HOME/bin/design" \
    || fail command "\$HOME/bin/design missing" "bash \"\$HOME/scripts/install-toolkit.sh\""

  # ------------------------------------------------------------------ work/
  [ -d "$WORK" ] && ok work "present" || fail work "work/ missing" "ONBOARDING.md Step 2"
  [ -d "$WORK/.git" ] && fail work-git "work/ is a git repo" "it must be a plain directory; move work/.git aside" || ok work-git "plain directory"
  for d in output profiles; do
    [ -d "$WORK/$d" ] && ok "work/$d" "present" || fail "work/$d" "missing" "mkdir -p \"$WORK/$d\""
  done
  [ -f "$WORK/AGENTS.md" ] && ok work-pointer "work/AGENTS.md" || fail work-pointer "work/AGENTS.md missing" "ONBOARDING.md Step 2c"
  if [ -f "$WORK/VERSION" ]; then
    [ "$(head -1 "$WORK/VERSION")" = "$(head -1 "$HOME_DIR/VERSION" 2>/dev/null)" ] && ok version "$(head -1 "$WORK/VERSION")" \
      || warn version "adopted $(head -1 "$WORK/VERSION") ≠ checked out $(head -1 "$HOME_DIR/VERSION" 2>/dev/null) — run the version check (docs/persistence.md)"
  else fail version "work/VERSION missing" "ONBOARDING.md Step 6"; fi
  if [ -f "$WORK/brand/brand.json" ]; then
    jq -e '.colors.accent | test("^#[0-9a-fA-F]{6}$")' "$WORK/brand/brand.json" >/dev/null 2>&1 \
      && ok brand "saved, accent $(jq -r .colors.accent "$WORK/brand/brand.json")" \
      || fail brand "work/brand/brand.json has no #rrggbb colors.accent" "brand skill → re-save (design brand save)"
  fi
fi

# ------------------------------------------------------------------- CONFIG
if [ ! -f "$CONFIG" ]; then
  fail config "work/CONFIG.md missing" "ONBOARDING.md Step 3"
else
  KNOWN=" default_style repos work_repo audit_report log_level "
  for k in $(sed -n 's/^- \([a-z_][a-z0-9_]*\):.*/\1/p' "$CONFIG"); do
    case "$KNOWN" in (*" $k "*) ;; (*) fail "config $k" "unknown key (the runtime cannot see it)" "remove it, or rename it to a key in CLAUDE.md → Runtime configuration";; esac
  done
  ds="$(cfg default_style)"
  case "$ds" in
    (auto|brand|carbon|repo:*/*) ok "config default_style" "$ds" ;;
    ("") fail "config default_style" "missing" "write '- default_style: auto' (CLAUDE.md → Runtime configuration)" ;;
    (*) fail "config default_style" "'$ds' is not auto | brand | carbon | repo:<owner/name>" "fix the value" ;;
  esac
  case "$ds" in (repo:*) p="$WORK/profiles/$(printf '%s' "${ds#repo:}" | sed 's/[^A-Za-z0-9._-]\{1,\}/__/g').yaml"
    [ -f "$p" ] && ok "config default repo" "profile saved" || fail "config default repo" "no saved profile for ${ds#repo:}" "prototype skill §2: design repo detect, confirm, save";; esac
  [ "$(cfg default_style)" = "brand" ] && [ ! -f "$WORK/brand/brand.json" ] && fail "config default_style" "brand, but no brand is saved" "save one (brand skill) or set auto"
  r="$(cfg repos)"
  if [ -n "$r" ] && [ "$r" != "none" ]; then
    for x in $(printf '%s' "$r" | tr ',' ' '); do
      printf '%s' "$x" | grep -qE '^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$' && ok "config repo $x" "shape ok" \
        || fail "config repo $x" "not owner/name" "fix it in repos:"
    done
  else ok "config repos" "none (brand / Carbon only)"; fi
  w="$(cfg work_repo)"
  case "$w" in (""|none) ok "config work_repo" "none (local only)";;
    (*/*) ok "config work_repo" "$w";; (*) fail "config work_repo" "'$w' is not owner/name or none" "fix the value";; esac
  a="$(cfg audit_report)"
  case "$a" in (""|enabled|disabled) ok "config audit_report" "${a:-enabled}";; (*) fail "config audit_report" "'$a' is not enabled|disabled" "fix the value";; esac
  l="$(cfg log_level)"
  case "$l" in (""|info|debug) ok "config log_level" "${l:-info}";; (*) fail "config log_level" "'$l' is not info|debug" "fix the value";; esac
fi

# --------------------------------------------------------------------- live
if [ "$LIVE" = 1 ]; then
  if out="$("$SCRIPT_DIR/audit.sh" 2>&1)"; then ok live "toolchain, a real Carbon build and its screenshot all passed"
  else
    printf '%s\n' "$out" | grep -E '^(FAIL|warn)' | sed 's/^/     /'
    fail live "the audit's end-to-end checks failed (above)" "apply each fix shown, then re-run with --live"
  fi
  for x in $(printf '%s' "$(cfg repos)" | tr ',' ' '); do
    [ "$x" = none ] && continue
    gh api "repos/$x" --jq .full_name >/dev/null 2>&1 && ok "repo $x" "reachable" \
      || fail "repo $x" "not reachable with the agent's GitHub access" "connect GitHub with access to $x, or drop it from repos:"
  done
fi

# ------------------------------------------------------------------- summary
if [ "$LIVE" = 1 ]; then SCOPE="structure+live"
elif [ "$STRUCTURE" = 1 ]; then SCOPE="structure"
else SCOPE="config"; fi
if [ "$FAILS" -eq 0 ]; then
  printf 'PASS (%s) — %d checks passed, %d warning(s)\n' "$SCOPE" "$CHECKS" "$WARNS"
  logev info onboarding_verify "PASS $SCOPE ($CHECKS checks, $WARNS warnings)"
  exit 0
else
  printf 'RESULT (%s): %d of %d checks FAILED — apply each fix above, then re-run this script until it prints PASS.\n' "$SCOPE" "$FAILS" "$CHECKS"
  logev error onboarding_verify "FAILED $SCOPE ($FAILS of $CHECKS checks) — agent must repair and re-run"
  exit 1
fi
