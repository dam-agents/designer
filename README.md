# Designer

**An agent that makes the visual things you'd normally ask a designer for.** Describe what you
need in plain words. You get back one finished file as a private link: a slide deck, a
clickable mockup, a product walkthrough, a chart, a short demo video, or the copy for any of
them.

You don't need design tools or design skills. You don't need code either, but if your
product lives in a GitHub repo, Designer builds its mockups from your real product styles
instead of a lookalike.

## Who it's for

- **Product managers** who want to show an idea before it's built, or explain what shipped.
- **Developers** who want a quick mockup of a feature without opening Figma.
- **Anyone presenting**: a deck from a doc, a chart from a spreadsheet, a demo for a launch.

## What you can ask for

| You say | You get |
| --- | --- |
| "Mock up issue #142 in acme/web" | A clickable HTML mockup with 2 or 3 different approaches to compare, with light/dark and empty-state toggles |
| "Make a walkthrough of what's new in 2.4" | A click-through tour of the real screens, with numbered notes on what changed |
| "Turn this doc into a 6-slide deck" | An HTML deck you present with the arrow keys, plus a PDF |
| "A 90-second demo of the export flow" | An MP4 video of the flow, step by step |
| "Chart our weekly signups" | A chart or dashboard in your colors |
| "Rewrite these button labels" | Short, plain copy in your product's own words |
| "Use our brand" + a logo or old .pptx | Your colors and fonts, saved and used for everything after |

## How it decides what things look like

Designer always uses one of three looks, and every file says which one, so nobody mistakes a
mockup for the real product:

1. **Your product's repo.** Name a GitHub repo and Designer compiles that repo's own
   stylesheet and renders its real components (logo, icons, avatars, badges). Mockups look
   like your app because they're built from it. Best with React and Tailwind.
2. **Your brand.** Upload a logo, a screenshot, an old slide deck, or just say "our blue is
   #0b5fff and we use Inter". Designer shows you what it found before saving it.
3. **IBM Carbon**, when you give it neither.

## Get started

1. In DAM, open **Starter kits → Productivity → Designer**.
2. Add a **GitHub** connection if your repo is private. Public repos and no-repo work need
   nothing.
3. Name the agent and create it.
4. It asks one question: *what do you want to make first?* Answer, and it starts.

You can also bind a **Slack DM** to send requests and screenshots from Slack. Links come back
in the thread. Slack carries images but not documents, so upload decks and PDFs in the DAM
chat instead.

**Without the catalog:** create a Claude Code agent by hand and send it this first message:

> Here is a file — read it and set yourself up according to it:
> `https://github.com/dam-agents/designer/blob/main/ONBOARDING.md`

## Good to know

- **Everything is private** until you ask for a share link. Anyone with a share link can open
  it.
- **It never runs your repo's code.** No `npm install` and no build scripts in your clone. It
  only reads the repo and installs the exact styling packages it needs into its own folders.
- **It works on request only.** The one schedule, a weekly self-check that reports only when
  something broke, is off unless you turn it on.
- **Change settings by asking**, e.g. "use Carbon by default" or "my main repo is acme/web".

---

## Reference

### Configuration

Stored in `work/CONFIG.md`, written at onboarding and changeable in chat. Exact semantics:
[`CLAUDE.md`](CLAUDE.md) → **Runtime configuration**.

| Key | Default | Purpose |
| --- | --- | --- |
| `default_style` | `auto` | `auto` (brand if saved, else Carbon), `brand`, `carbon`, or `repo:<owner/name>` |
| `repos` | `none` | The repos you work on, so "our app" resolves |
| `work_repo` | `none` | A private repo to back up the brand and repo profiles to (env `GITHUB_REPO_WORK` wins) |
| `audit_report` | `enabled` | Whether the weekly check messages you when something broke |
| `log_level` | `info` | `debug` for diagnostics |

### Repo support

React + Tailwind v3/v4 work fully, as do plain CSS and CSS modules. CSS-in-JS (MUI, Chakra,
styled-components) shows through rendered components only. Vue and Svelte work for classes
and copy, not component rendering. The first time you name a repo, Designer proposes a short
*design profile* (framework, Tailwind version, CSS entry, icons, fonts) for you to confirm.

### Runtime requirements

- **Platform:** DAM, Claude Code harness, 10 GiB disk (repo builds and video frames need
  room).
- **Network:** the *trusted* egress preset (npm, PyPI, github.com).
- **Browser and video:** the image's Playwright Chromium, or a self-contained one the
  installer unpacks into the home directory. ffmpeg comes from `ffmpeg-static`.

### Persistence

`work/` holds your config, brand, repo profiles and outputs on the agent's own disk. With
`work_repo` set, the brand, profiles and config are backed up to that private repo after each
change. Definition updates arrive through the platform's **Update** button and never touch
`work/`. See [`docs/persistence.md`](docs/persistence.md).

### Adding it to a catalog

One entry in a catalog repository's `catalog.yaml`:

```yaml
kits:
  - url: https://github.com/dam-agents/designer
```

### For contributors

- [`toolkit/`](toolkit/) is the `design` CLI every skill calls; `node toolkit/bin/design.mjs`
  prints its usage. `lib/profile.mjs` reads repos, `lib/style.mjs` compiles their CSS,
  `lib/theme.mjs` is the Carbon/brand fallback, `lib/components.mjs` renders real components.
- [`.agents/skills/`](.agents/skills/) holds the six skills: `prototype`, `walkthrough`,
  `slides`, `demo-video`, `brand`, `copy`. Charts use the harness's `dataviz` skill.
- `bash scripts/tests/run.sh` runs the offline suite, `bash scripts/validate-definition.sh .`
  checks the definition's shape. CI runs both.
- Changes go through PRs; read [`docs/self-modification.md`](docs/self-modification.md) first.

### Files

- [`kit.yaml`](kit.yaml): the Starter Kit (seed, install, connections, schedule, size).
- [`CLAUDE.md`](CLAUDE.md): the agent's manual. [`AGENTS.md`](AGENTS.md) points to it.
- [`ONBOARDING.md`](ONBOARDING.md): first-run setup.
- [`docs/`](docs/): the audit, persistence and self-modification rules.
- [`scripts/`](scripts/): install, audit, verify, backup, logging, tests, validator.
- [`VERSION`](VERSION) + [`CHANGELOG.md`](CHANGELOG.md): semver and upgrade steps.
- [`LICENSE`](LICENSE): Apache 2.0.
