# Designer

Designer makes slide decks, clickable mockups, product walkthroughs, charts, demo videos and
the copy for them. Ask in plain words and you get one finished file back as a private link.
You don't need design skills or code.

| Ask | Get |
| --- | --- |
| "Turn this doc into a 6-slide deck" | An HTML deck you present with the arrow keys, plus a PDF |
| "Mock up issue #142 in acme/web" | A clickable mockup with 2 or 3 approaches to compare |
| "Make a walkthrough of what's new in 2.4" | A click-through tour of the real screens, with notes on what changed |
| "A 90-second demo of the export flow" | An MP4 video |
| "Chart our weekly signups" | A chart or dashboard in your colors |
| "Rewrite these button labels" | Short, plain copy in your product's words |

**It looks like your product.** Name a GitHub repo and Designer builds from that repo's real
styles and components. Without a repo it uses a brand you upload (a logo, a screenshot or an
old deck), or IBM Carbon. Every file says which look it used.

## Get started

1. In DAM, open **Starter kits → Productivity → Designer** and create the agent.
2. Add a **GitHub** connection only if your repo is private.
3. Tell it what you want to make first.

You can also send requests from a **Slack DM**. Slack carries images but not documents, so
upload decks and PDFs in the DAM chat.

## Good to know

- Files stay private until you ask for a share link.
- It reads your repo but never runs its code.
- It works only when you ask. An optional weekly self-check ships turned off.
- Change any setting by asking, for example "my main repo is acme/web".

## More

- Settings: [`CLAUDE.md`](CLAUDE.md) → **Runtime configuration**.
- Setup without the catalog: send a new Claude Code agent the link to
  [`ONBOARDING.md`](ONBOARDING.md) and ask it to set itself up.
- Runs on DAM with the Claude Code harness, 10 GiB disk and the *trusted* egress preset
  (npm, PyPI, github.com). Where its files live: [`docs/persistence.md`](docs/persistence.md).
- Contributing: the skills are in [`.agents/skills/`](.agents/skills/) and the `design` CLI
  is in [`toolkit/`](toolkit/). `bash scripts/tests/run.sh` runs the tests. Read
  [`docs/self-modification.md`](docs/self-modification.md) before opening a PR.
