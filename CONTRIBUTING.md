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

Write the test first.
Unit tests live in `tests/unit/` as `.typ` files of `#assert.eq` calls, and visual tests live in `tests/visual/` as documents to inspect.

## House rules

- The core imports no third-party package.
  Only files under `src/integrations/` may, and `tools/import-boundary.sh` enforces it.
- Public names use full words, British spelling, and no abbreviations.
- Every failure goes through `src/utils/errors.typ`; no inline panic strings.
- Nothing fallible is attempted speculatively, because Typst has no `try`.
- Commit messages follow Conventional Commits, subject line only, ideally under 50 characters.
- Record user-facing changes under `## Unreleased` in [`CHANGELOG.md`](CHANGELOG.md).

See [`ARCHITECTURE.md`](ARCHITECTURE.md) before adding a part, a formatter, or a theme option.
