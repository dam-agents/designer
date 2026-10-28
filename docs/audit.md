# Audit run

The weekly self-check, `designer-audit-weekly` (Monday, suggested off). **Read-only and
repair-free:** it reports, the operator decides.

1. Run the deterministic half:

   ```bash
   bash "$HOME/scripts/audit.sh"
   ```

   One `ok`/`warn`/`FAIL` line per check and a JSON summary last. It runs `design doctor`, builds
   and screenshots a tiny Carbon page end to end, checks the saved brand and every repo profile
   still parse, that the definition checkout is clean and `work/` is not a repo, disk space,
   leftover scratch, and the last backup's outcome.
2. Judgment checks the script can't do:
   - `mcp__platform-outbound__list_schedules`: `designer-audit-weekly` exists with the task text
     ONBOARDING Step 5 registers. A drifted task is a finding; changing it is the operator's call.
   - Version currency, report only (docs/persistence.md → **Definition version & upgrade**).
3. **Report only what is not ok.** All `ok` → say nothing: end the run with no message. Otherwise,
   when `audit_report` is `enabled` (missing = enabled), send the operator **one** message: each
   `FAIL` and `warn` on one line with its `fix:`, the version drift if any. In the direct session
   it goes in the chat; with a bound Slack DM, there too.
4. Never repair in an audit run — no installs, no deletes, no config changes. A fix the operator
   asks for afterwards happens in the direct session.
