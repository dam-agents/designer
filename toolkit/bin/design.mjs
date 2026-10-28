#!/usr/bin/env node
// design — the Designer kit's one entry point. Every skill calls it; run with no
// arguments for usage. Prints machine-readable results on stdout, problems on stderr.
const [cmd, ...args] = process.argv.slice(2);
const USAGE = `usage: design <command> [args]

  doctor                               check the toolchain (browser, ffmpeg, fonts, npm)
  repo clone <owner/name> [ref]        fresh clone into scratch; prints {dir, commit}
  repo detect <owner/name> [ref]       clone + propose a design profile (not saved)
  repo save <profile.yaml>             save a confirmed profile to work/profiles/
  repo show <owner/name>               print the saved profile
  build <src.html> <out.html> [--style repo:<owner/name>|brand|carbon] [--ref <ref>]
                                       compile a prototype or walkthrough source
  shot <page.html> <outdir> [--width 1440] [--views] [--dark] [--click <selector>]...
                                       full-length screenshots (light, dark, each view)
  deck-new <deck.html> [--style brand|carbon]
                                       start a deck from the template, in the style's colors and fonts
  deck-pdf <deck.html> <out.pdf>       print a deck to PDF, one page per slide
  deck-check <deck.html>               the deck skill's mechanical checks
  video <page.html[?shot=Name]> <out.mp4> [fps] [music]
                                       render a demo video to MP4
  stills <page.html> <shot|""> <t1,t2,...> <outdir>
                                       PNG stills of a video at given times
  video-new <dir> [--style brand|carbon]
                                       start a video in <dir>: template + vendor/ (React, Babel, fonts)
  brand extract <file>... [--name <n>] read logo/screenshot/pptx/pdf/css into a draft brand
  brand show                           print the saved brand
  brand save <brand.json>              save a confirmed brand to work/brand/
  icons <package> <Name>...            check icon names exist in a package
`;
const table = {
  doctor: "./doctor.mjs", repo: "./repo.mjs", build: "./build.mjs", shot: "./shot.mjs",
  "deck-new": "./deck.mjs", "deck-pdf": "./deck.mjs", "deck-check": "./deck.mjs", video: "./video.mjs", stills: "./video.mjs",
  "video-new": "./video.mjs", brand: "./brand.mjs", icons: "./icons.mjs",
};
if (!cmd || !table[cmd]) { process.stdout.write(USAGE); process.exit(cmd ? 2 : 0); }
const mod = await import(table[cmd]);
await mod.main(cmd, args);
