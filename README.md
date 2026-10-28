# Designer

Slides, mockups, charts and demo videos, with or without code.

Designer is an agent you ask for something to look at: a slide deck, a clickable mockup of a
screen, a step-by-step walkthrough, a chart, a 90-second demo video, or the words for any of
them. It hands back one finished file as a private link.

Connect a GitHub repo, and mockups and walkthroughs are built on your product's real styles
and components, compiled fresh from its code every time. Without one, they use a brand you
upload (a logo, an old deck, a screenshot) or IBM Carbon.

## What it makes

| Ask for | You get | Skill |
| --- | --- | --- |
| "Mock up issue #142 in acme/web", "three ways to show sharing settings" | One HTML file with 2–3 approaches, or one design across its screens. Light/dark and empty-state toggles. | `prototype` |
| "A walkthrough of what's new in 2.4" | A clickable step-by-step tour with numbered notes on what changed. | `walkthrough` |
| "A 6-slide deck on our Q3 results from this doc" | An HTML deck (arrow keys to present) and a PDF. | `slides` |
| "A 90-second demo of the export flow" | An MP4: a step rail, the product in a framed window, a still. | `demo-video` |
| "Use our colors", a logo or a .pptx | A saved brand that everything above uses from then on. | `brand` |
| Button labels, an announcement, slide text | Plain, specific copy in your product's own words. | `copy` |
| A chart or a dashboard | Charts in your brand's or Carbon's colors (the harness's dataviz skill). | — |

## Where the look comes from

1. **A repo you name.** The agent reads it once and proposes a short *design profile*:
   framework, Tailwind version, the CSS entry, icon package and fonts. You confirm it. From then
   on, every build clones the repo fresh and compiles its own stylesheet with the exact package
   versions its lockfile names. Real components (your logo, avatars, badges) render straight
   from their source files. Works with React + Tailwind v3/v4 fully, and with plain CSS / CSS
   modules. CSS-in-JS (MUI, Chakra, styled-components) shows through rendered components only.
   Vue and Svelte work for classes and copy, but not for component rendering.
2. **A brand you upload.** From a `.pptx` (it reads the colors and fonts your slides really
   use, not the default Office theme), a logo, a screenshot, a stylesheet, font files, or just
   "our blue is #0b5fff and we use Inter". You confirm it before it's saved.
3. **IBM Carbon**, otherwise: its official tokens (`@carbon/themes`), Plex fonts, Carbon icons.

Every file says which of the three it used, so nobody mistakes a Carbon mockup for the real
product.

## Setup

This repository is its own **Starter Kit** ([`kit.yaml`](kit.yaml)):

1. **Find Designer under Starter kits** (Productivity) and open it.
2. **Connections — all optional.** *GitHub* lets it use a private repo. Public repos and
   no-repo work need nothing.
3. **Name the agent and create it.** The platform seeds this definition, installs the
   toolchain (`scripts/install-toolkit.sh`), and opens the first session on
   [`ONBOARDING.md`](ONBOARDING.md).
4. **Answer one question:** what do you want to make first? It may ask for a repo or brand
   material if the first request needs one, whether to back up your brand, and whether to turn
   on the weekly self-check.

Optionally bind a **Slack DM**: send requests and screenshots there, and get links back in the
thread. Slack carries images but not documents, so send decks and PDFs through the chat upload.

Not in a catalog yet? One entry in a catalog repository's `catalog.yaml` adds it:

```yaml
kits:
  - url: https://github.com/dam-agents/designer
```

### Without the catalog

Create an agent on the Claude Code harness by hand, then send it its first message:

> Here is a file — read it and set yourself up according to it:
> `https://github.com/dam-agents/designer/blob/main/ONBOARDING.md`

## Configuration

`work/CONFIG.md`, written at onboarding and changeable in chat ("use Carbon by default").
Exact semantics: [`CLAUDE.md`](CLAUDE.md) → **Runtime configuration**.

| Key | Default | Purpose |
| --- | --- | --- |
| `default_style` | `auto` | `auto` (brand if saved, else Carbon), `brand`, `carbon`, or `repo:<owner/name>` |
| `repos` | `none` | The repos you work on, as a hint for "our app" |
| `work_repo` | `none` | A private repo to back up the brand and repo profiles to (env `GITHUB_REPO_WORK` wins) |
| `audit_report` | `enabled` | Whether the weekly check messages you when something broke |
| `log_level` | `info` | `debug` for diagnostics |

## Runtime requirements

- **Platform:** the DAM agent platform. `$HOME` on a persistent disk, the outbound gateway for
  credentials, the `mcp__platform-outbound__*` tools for artifacts and the schedule. Claude Code
  harness. 10 GiB disk.
- **Network:** the platform's *trusted* preset. That covers registry.npmjs.org (toolchains,
  fonts, ffmpeg), github.com and its asset hosts (repo clones, the ffmpeg binary), PyPI.
- **Browser:** the image's Playwright Chromium when it has one, otherwise a self-contained
  Chromium the installer unpacks into the home directory. ffmpeg comes from `ffmpeg-static`.
- **Safety:** it never runs a repository's own code (no `npm install` in a clone, no build or
  postinstall scripts). It installs the exact packages a build needs into its own directories.
- **External surfaces:** every deliverable is a **private** artifact unless you ask for a share
  link. A link, once made, is readable by anyone who has it.

## Persistence

`work/` holds your config, brand, repo profiles and outputs, on the agent's own disk. With
`work_repo` set, the brand, profiles and config are backed up after each change to that
private repo; outputs aren't, they're artifacts already. Definition updates arrive through the
platform's **Update** button and never touch `work/`. See
[`docs/persistence.md`](docs/persistence.md).

## For contributors

- [`toolkit/`](toolkit/) is the `design` CLI every skill calls. `node toolkit/bin/design.mjs` prints its usage.
  `lib/profile.mjs` reads repos, `lib/style.mjs` compiles their CSS, `lib/theme.mjs` is the
  Carbon/brand fallback, and `lib/components.mjs` renders real components.
- [`.agents/skills/`](.agents/skills/) holds the six skills.
- `bash scripts/tests/run.sh` runs the offline suite, and `bash scripts/validate-definition.sh .`
  checks the definition's shape. CI runs both.
- Changes go through PRs; read [`docs/self-modification.md`](docs/self-modification.md) first.

## Files

- [`kit.yaml`](kit.yaml): the Starter Kit (seed, install, connections, schedule, size).
- [`CLAUDE.md`](CLAUDE.md): the agent's manual. [`AGENTS.md`](AGENTS.md): pointer to it.
- [`ONBOARDING.md`](ONBOARDING.md): first-run setup.
- [`docs/`](docs/): the audit, persistence, and self-modification rules.
- [`scripts/`](scripts/): install, audit, verify, backup, logging, tests, validator.
- [`VERSION`](VERSION) + [`CHANGELOG.md`](CHANGELOG.md): semver and upgrade steps.
- [`LICENSE`](LICENSE): Apache 2.0.
