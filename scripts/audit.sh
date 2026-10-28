#!/usr/bin/env bash
# audit.sh — the weekly self-check's deterministic half (docs/audit.md). Read-only
# toward everything outside work/; never repairs. One line per check, then a JSON
# summary on the last line:
#
#   ok   <check> — <detail>
#   warn <check> — <detail>
#   FAIL <check> — <problem> — fix: <instruction>
#
# Checks: the design toolchain (`design doctor`), a real build and screenshot of a
# tiny page in Carbon style (the cheapest end-to-end proof), the saved brand and
# every saved repo profile still parse, the definition checkout is clean, disk
# space, leftover scratch, and the backup's last result.
set -u
export LC_ALL=C
HOME_DIR="${HOME:-/home/agent}"
WORK="${WORK_DIR:-$HOME_DIR/work}"
CONFIG="$WORK/CONFIG.md"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_JOB=audit
if ! . "$SCRIPT_DIR/log.sh" 2>/dev/null; then logev() { :; }; fi
. "$SCRIPT_DIR/lib/config.sh" || { echo "cannot source lib/config.sh" >&2; exit 1; }
DESIGN="$HOME_DIR/bin/design"
[ -x "$DESIGN" ] || DESIGN="node $HOME_DIR/toolkit/bin/design.mjs"

OKS=0; WARNS=0; FAILS=0
ok()   { OKS=$((OKS+1));     printf 'ok   %s — %s\n' "$1" "$2"; }
warn() { WARNS=$((WARNS+1)); printf 'warn %s — %s\n' "$1" "$2"; }
fail() { FAILS=$((FAILS+1)); printf 'FAIL %s — %s — fix: %s\n' "$1" "$2" "$3"; }

# 1. Toolchain.
doc="$($DESIGN doctor 2>&1)"; rc=$?
if [ "$rc" -eq 0 ]; then ok toolchain "design doctor passed"
else
  printf '%s\n' "$doc" | grep '^FAIL' | while IFS= read -r l; do printf '     %s\n' "$l"; done
  fail toolchain "design doctor reported failures (above)" "bash \"\$HOME/scripts/install-toolkit.sh\", then design doctor"
fi

# 2. End to end: build and screenshot a tiny Carbon page.
t="$(mktemp -d /tmp/designer-audit.XXXXXX)"
cat > "$t/a.src.html" <<'HTML'
<!doctype html><html lang="en" data-review-title="audit"><head><meta charset="utf-8"><title>audit</title><!-- design:css --></head>
<body><!-- design:review-bar --><div data-view="1" data-view-name="Audit" class="p-6 bg-background text-foreground"><h1 class="text-xl font-semibold">Audit</h1><button class="mt-2 rounded-md bg-primary px-3 py-1.5 text-sm text-primary-foreground"><ui-icon name="Checkmark" size="16"/> Ok</button></div></body></html>
HTML
if out="$(WORK_DIR="$t/work" $DESIGN build "$t/a.src.html" "$t/a.html" --style carbon 2>&1)" \
   && shots="$(WORK_DIR="$t/work" $DESIGN shot "$t/a.html" "$t/shots" --width 600 --height 200 2>&1)" \
   && [ -s "$t/shots/1-light.png" ]; then
  ok render "built and screenshotted a Carbon page ($(printf '%s' "$out" | sed -n 's/.*"kb":\([0-9]*\).*/\1/p') KB)"
else
  fail render "a Carbon build or screenshot failed: $(printf '%s\n%s' "${out:-}" "${shots:-}" | grep -m1 -E 'design:|Error' || echo unknown)" "design doctor; then re-run this audit"
fi
rm -rf "$t"

# 3. Saved state parses.
if [ -f "$WORK/brand/brand.json" ]; then
  if jq -e '.colors.accent | test("^#[0-9a-fA-F]{6}$")' "$WORK/brand/brand.json" >/dev/null 2>&1; then
    ok brand "$(jq -r '.name // "saved brand"' "$WORK/brand/brand.json"), accent $(jq -r .colors.accent "$WORK/brand/brand.json")"
    logo="$(jq -r '.logo // empty' "$WORK/brand/brand.json")"
    [ -z "$logo" ] || [ -f "$WORK/brand/$logo" ] || fail brand-logo "brand.json names $logo but work/brand/$logo is missing" "ask the operator for the logo again (brand skill)"
  else fail brand "work/brand/brand.json does not parse or has no #rrggbb colors.accent" "brand skill: re-save the brand"; fi
else ok brand "none saved (Carbon is the fallback)"; fi
n=0; bad=""
for p in "$WORK"/profiles/*.yaml; do
  [ -e "$p" ] || continue; n=$((n+1))
  grep -qE '^repo: ' "$p" && grep -qE '^(kind|styling): ' "$p" || bad="$bad $(basename "$p")"
done
if [ -n "$bad" ]; then fail profiles "malformed:$bad" "design repo detect <owner/name> again and save"
else ok profiles "$n saved"; fi

# 4. Definition checkout clean; work/ is not a repo.
if [ -d "$HOME_DIR/.git" ]; then
  dirty="$(git -C "$HOME_DIR" status --porcelain 2>/dev/null | head -5)"
  [ -z "$dirty" ] && ok definition "checkout clean at $(git -C "$HOME_DIR" rev-parse --short HEAD 2>/dev/null)" \
    || warn definition "uncommitted changes in the definition: $(printf '%s' "$dirty" | tr '\n' ' ')"
fi
[ -d "$WORK/.git" ] && fail work-git "work/ has a .git — it must stay a plain directory" "move work/.git aside and tell the operator" || ok work-git "work/ is a plain directory"

# 5. Disk and scratch.
avail_kb="$(df -Pk "$HOME_DIR" 2>/dev/null | awk 'NR==2{print $4}')"
if [ -n "$avail_kb" ]; then
  [ "$avail_kb" -gt 1048576 ] && ok disk "$((avail_kb/1024)) MB free on the home disk" \
    || warn disk "only $((avail_kb/1024)) MB free — old work/output/ renders and ~/.local/share/designer/toolchains are the big items"
fi
out_mb="$(du -sm "$WORK/output" 2>/dev/null | cut -f1)"; tc_mb="$(du -sm "$HOME_DIR/.local/share/designer/toolchains" 2>/dev/null | cut -f1)"
ok usage "work/output ${out_mb:-0} MB, repo toolchains ${tc_mb:-0} MB"
left="$(find /tmp -maxdepth 1 -name 'designer-audit.*' -mmin +60 2>/dev/null | wc -l | tr -d ' ')"
[ "$left" -eq 0 ] || warn scratch "$left leftover /tmp/designer-audit.* directories"

# 6. Backup.
repo="${GITHUB_REPO_WORK:-$(cfg work_repo)}"
case "$repo" in
  (""|none|off|disabled) ok backup "not configured (work/ is local only)" ;;
  (*) # the last final outcome only: "pushed work/" or "push failed after N attempts"
      lastb="$(grep -h '"event":"work_backup"' "$WORK"/logs/events-*.jsonl 2>/dev/null | grep -E 'pushed work/|push failed after' | tail -1)"
      case "$lastb" in
        (*'"level":"error"'*) fail backup "last backup to $repo failed: $(printf '%s' "$lastb" | jq -r .msg 2>/dev/null)" "check the GitHub connection can write to $repo" ;;
        ("") warn backup "configured ($repo) but no backup logged yet" ;;
        (*) ok backup "last backup to $repo: $(printf '%s' "$lastb" | jq -r .ts 2>/dev/null)" ;;
      esac ;;
esac

printf '{"ok":%d,"warn":%d,"fail":%d}\n' "$OKS" "$WARNS" "$FAILS"
logev info audit "ok=$OKS warn=$WARNS fail=$FAILS"
[ "$FAILS" -eq 0 ]
