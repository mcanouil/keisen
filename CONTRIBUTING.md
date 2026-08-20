# Contributing to Keisen

Thanks for your interest in helping improve Keisen.
This document explains where to file what, and the basics of working on the source.

> [!NOTE]
> I do not accept pull requests for now.
> The reasons, and when that changes, are in the [README](README.md#contributing).
> File what you have instead, as described in [Where to file what](#where-to-file-what), and say what you would change.

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

This section describes how I work on the source, and the checks a patch must pass once I accept pull requests.
It is also what a fork needs to keep the suite green.

Requirements: Typst 0.15.0 or later, Bash 5 or later, [Quarto](https://quarto.org), and `shellcheck` plus `shfmt` if you touch the scripts.

Quarto is not optional.
`tools/check.sh` renders a table through it, and that check fails and says so when Quarto is absent rather than skipping, because a suite that reports success without running a check reports coverage it does not have.

Run everything before you commit:

```bash
tools/check.sh
```

That compiles every unit test, visual test, and example, and enforces the import boundary.
A failing `#assert` is a compile failure, which is exactly how the tests report.

The same script runs on every pull request, through `.github/workflows/checks.yml`, alongside `shellcheck` over every script and `shfmt` over the ones under `tools/`.
Run it locally first: a run that only tells you what your own machine would have is a run nobody needed.

Write the test first.
Unit tests live in `tests/unit/` as `.typ` files of `#assert.eq` calls, and visual tests live in `tests/visual/` as documents to inspect.

Failure paths go in `tests/expect-fail/`.
Typst has no `try`, so a panic cannot be asserted from inside a document: each file there is expected to fail compiling, and a `// expect: <text>` comment on its own line names the message it must produce.
A file in that directory which compiles is a test failure.

Anything about how the table looks goes in `tests/probe/`.
Each probe compiles to SVG and asserts what the render must contain, through `// expect-svg:` and `// reject-svg:` comments.
See [`tests/probe/README.md`](tests/probe/README.md); the rule that matters is to break the thing a new probe watches and confirm it fails, because a probe that cannot fail reads as coverage.

Anything that must read the same in both writing directions goes in `tests/direction/`, rendered twice and compared glyph by glyph.
See [`tests/direction/README.md`](tests/direction/README.md).

Anything a screen reader must be able to tell apart goes in `tests/accessibility/`, compiled to PDF/UA-1 and counted in the structure tree through `// expect-tag:` comments.
See [`tests/accessibility/README.md`](tests/accessibility/README.md).

Anything about how the package behaves under Quarto goes in `tests/quarto/`, rendered to Typst and asserted through `<!-- expect-typ: -->` and `<!-- expect-pdf: -->` comments.
See [`tests/quarto/README.md`](tests/quarto/README.md).

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

## Rehearsing a release

```bash
SKIP_MANIFEST_LINT=1 tools/dry-release.sh   # a routine run
tools/dry-release.sh                        # what a release is rehearsed with
```

The script stages the payload a release publishes, installs it as `@preview/keisen:<version>` through a symlink under Typst's data directory, and compiles every visual test and every documentation listing against that installed copy before removing the symlink.
It publishes nothing.

The script closes by recording the benchmark timing: a 2000-row, 10-column table with styles and formats, which is the table the style index exists for.
It records rather than judges, since the noise on a wall-clock ratio is as wide as the signal, so read the numbers and compare them with the last release.
Run it alone with `tools/benchmark.sh`.

Run it after touching `lib.typ`, the `exclude` list in `typst.toml`, or any listing in `docs/`.
A module the working tree can import is not necessarily a module a package specification can reach, and compiling from an installed copy is the only check that tells the difference.

The second form also lints the manifest, through [`typst-package-check`](https://github.com/typst/package-check), which is installed with `cargo install --git https://github.com/typst/package-check`.
That linter is the one Typst Universe runs on a submission, and the entry it checks is permanent, so a finding stops the rehearsal, and so does a missing linter.
`SKIP_MANIFEST_LINT=1` runs everything else without it, which is what the checks workflow does and what a routine run wants; a release is not rehearsed that way, and the closing line says which of the two ran.

The release itself rolls `## Unreleased` in [`CHANGELOG.md`](CHANGELOG.md) into `## <version> (YYYY-MM-DD)` and writes the same day as `date-released` in [`CITATION.cff`](CITATION.cff).
`tools/version-check.sh` holds the two to each other, and it refuses a `date-released` while the changelog says nothing has been released, so the development bump after a release removes the field again.

See [`ARCHITECTURE.md`](ARCHITECTURE.md) before adding a part, a formatter, or a theme option.
Its "Typst constraints that shaped this" section is worth reading first: several decisions look arbitrary until you know which language behaviour forced them.
