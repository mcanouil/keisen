# Contributing to Keisen

Thanks for your interest in helping improve Keisen.
This document explains where to file what, and the basics of working on the source.

## Where to file what

- **Bug report.**
  Use [Issues → Bug report](https://github.com/mcanouil/keisen/issues/new?template=bug.yml) only for confirmed defects with a reproducible example.
- **Feature request or idea.**
  Open a thread in [Discussions → Ideas](https://github.com/mcanouil/keisen/discussions/new?category=ideas).
  Feature requests opened as issues are redirected.
- **Question or help.**
  Open a thread in [Discussions → Q&A](https://github.com/mcanouil/keisen/discussions/new?category=q-a).

A bug report must include the Typst version, the Keisen version, and a minimal document that reproduces the problem.

## Working on the source

Requirements: Typst 0.15.0 or later, Bash, and `shellcheck` plus `shfmt` if you touch the scripts.

Run everything before you commit:

```bash
tools/check.sh
```

That compiles every unit test, visual test, and example, and enforces the import boundary.
A failing `#assert` is a compile failure, which is exactly how the tests report.

The same script runs on every pull request, through `.github/workflows/checks.yml`, alongside `shellcheck` and `shfmt` over the scripts.
Run it locally first: a run that only tells you what your own machine would have is a run nobody needed.

Write the test first.
Unit tests live in `tests/unit/` as `.typ` files of `#assert.eq` calls, and visual tests live in `tests/visual/` as documents to inspect.

Failure paths go in `tests/expect-fail/`.
Typst has no `try`, so a panic cannot be asserted from inside a document: each file there is expected to fail compiling, and a `// expect: <text>` comment on its own line names the message it must produce.
A file in that directory which compiles is a test failure.

Anything about how the table looks goes in `tests/probe/`.
Each probe compiles to SVG and asserts what the render must contain, through `// expect-svg:` and `// reject-svg:` comments.
See [`tests/probe/README.md`](tests/probe/README.md); the rule that matters is to break the thing a new probe watches and confirm it fails, because a probe that cannot fail reads as coverage.

## House rules

- The package imports no third-party package.
  Nothing under `src/` may, and `tools/import-boundary.sh` enforces it.
- Public names use full words, British spelling, and no abbreviations.
- Every failure goes through `src/utils/errors.typ`; no inline panic strings.
- Nothing fallible is attempted speculatively, because Typst has no `try`.
- Commit messages follow Conventional Commits, subject line only, ideally under 50 characters.
- Record user-facing changes under `## Unreleased` in [`CHANGELOG.md`](CHANGELOG.md).

Set every test page to grow with what it holds, so a rendered image is the table rather than the table and a field of white:

```typ
#set page(width: auto, height: auto, margin: 0.5cm)
```

Every page fits its width, with no exception. `tests/visual/breakable.typ` fixes its height alone, because a page that grows never breaks and breaking is what it tests.

After changing a visual test, regenerate the images the documentation shows:

```bash
tools/render-docs-assets.sh
```

See [`ARCHITECTURE.md`](ARCHITECTURE.md) before adding a part, a formatter, or a theme option.
Its "Typst constraints that shaped this" section is worth reading first: several decisions look arbitrary until you know which language behaviour forced them.
