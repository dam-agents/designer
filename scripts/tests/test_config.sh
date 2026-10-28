#!/usr/bin/env bash
# The shell reader (scripts/lib/config.sh) and the CLI's reader (toolkit/lib/core.mjs cfg)
# must read every value identically — CLAUDE.md → Runtime configuration.
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/work"
cat > "$T/work/CONFIG.md" <<'MD'
# Designer configuration

- default_style: repo:acme/widgets   # the main app
- repos: "acme/widgets, acme/site"
- work_repo: `alice/designer-work`
- audit_report:   disabled
- log_level: info
Not a bullet: default_style: carbon
MD
CONFIG="$T/work/CONFIG.md"; . "$ROOT/scripts/lib/config.sh"
fail=0
for k in default_style repos work_repo audit_report log_level missing_key; do
  sh_v="$(cfg "$k")"
  js_v="$(WORK_DIR="$T/work" node --input-type=module -e "import('$ROOT/toolkit/lib/core.mjs').then(m => process.stdout.write(m.cfg('$k')))" 2>/dev/null)"
  if [ "$sh_v" != "$js_v" ]; then echo "  $k: shell '$sh_v' != cli '$js_v'"; fail=1; fi
done
[ "$(cfg default_style)" = "repo:acme/widgets" ] || { echo "  comment not stripped: $(cfg default_style)"; fail=1; }
[ "$(cfg work_repo)" = "alice/designer-work" ] || { echo "  backticks not stripped: $(cfg work_repo)"; fail=1; }
exit $fail
