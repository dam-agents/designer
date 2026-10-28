# Agent entry point

This repository is an **agent definition**, not an application. Its operating manual is
**[`CLAUDE.md`](CLAUDE.md)** — read that file first, under any harness. It is the single
source of truth for the run types, the delivery rules, runtime configuration, and the hard
invariants.

Reading order:

1. **[`CLAUDE.md`](CLAUDE.md)** — always, before anything else.
2. The skill the request needs (`.agents/skills/<name>/SKILL.md`) and the `docs/` file the work
   needs — `CLAUDE.md` says which and when. Never read them all up front.
3. **[`ONBOARDING.md`](ONBOARDING.md)** — only on a fresh instance that has no
   `$HOME/.designer-onboarded` sentinel.

This file is a pointer, not a copy: it carries no rules of its own, and nothing here
overrides `CLAUDE.md`. A harness that starts inside `work/` finds the same pointer at
`work/AGENTS.md` (seeded by `ONBOARDING.md`).
