// Every option a test sets, and the recorded list of the ones no test sets.
//
// `test-options-read.typ` holds every declared key to being read by a renderer,
// which is why an option nothing sets was never reported: it is read, in a
// branch or a cell nothing had ever asked for. Thirty-one of the forty-six were
// set by no test, and this list records the twenty-seven that still are.
//
// A key covered tomorrow comes off the list, and a key declared tomorrow is
// covered or added here on purpose, so the list can only shrink.
//
// Two things the list does not claim. Set means a test writes the key, not that
// a test reads what it did to the output: `table-options(cell-inset: 2em)` in a
// merge assertion counts, and nothing measures the inset. And a key a preset
// carries is recorded here all the same, because the scan reads the tests rather
// than `src/theme/presets.typ`, so `summary-border-top` is listed although
// `theme-booktabs` sets it and two tracked renders show it.

#import "../../src/theme/options.typ": DEFAULTS

// A source with its comments removed, so a key named in a comment is not read as
// coverage. Repeated from `test-options-read.typ` rather than shared, so neither
// test can fail for the other's reason.
#let strip-comments(text) = {
  text.split("\n").map(line => line.split("//").first()).join("\n")
}

#assert.eq(strip-comments("a \"x\" // \"y\"\nb"), "a \"x\" \nb")
#assert.eq(strip-comments("// \"x\"\na"), "\na")
#assert.eq(strip-comments("x \"a//b\""), "x \"a")

// A key is set where a test gives it a value: as a quoted key, which is how a
// theme dictionary and a serialised specification write one, or as a named
// argument or a bare dictionary key.
//
// The unquoted form is counted only in a file that configures options at all,
// which is one calling `table-options` or `build-spec`, or one passing a theme
// or an option dictionary. `key: value` is the shape of every named argument in
// Typst, and `breakable` is one of `block`'s. The gate is per file rather than
// per call, so a file that both configures options and writes `block(breakable:
// false)` would count `breakable` as set. It cannot pass silently: the assertion
// at the end compares the whole set, so a wrong count fails the suite and asks
// for this list to be edited.
//
// Reading a key by name is not setting it: `option(theme-compact(), "cell-inset")`
// asserts what the preset carries, and the renderer could stop reading the key
// with that assertion still green, which is what `test-options-read.typ` is for.
//
// Each name is anchored on the character before it, so a longer key ending in
// this one is not a mention of it. Rust regex has no lookaround, so the anchor
// is a character class and each source gains a newline in front of it for the
// case where the key opens the text.
// Whether a source configures options at all, read once per file rather than
// once per key: the answer is the same for all forty-six of them.
// `option_setters` in tools/check.sh holds the sources list below to the files
// these four markers find, so it spells them the same way. Edit the two together.
#let configures(text) = (
  text.contains("table-options(")
    or text.contains("build-spec(")
    or text.contains(regex("theme\\s*:"))
    or text.contains(regex("options\\s*:"))
)

#let sets(name, source) = {
  // A key holding a regex metacharacter would loosen the pattern rather than
  // fail, so the shape a key may take is asserted rather than escaped.
  assert(
    name.match(regex("^[a-z][a-z-]*$")) != none,
    message: "an option name outside a to z and the hyphen needs escaping here: " + name,
  )
  if source.text.contains(regex("[^-\\w]\"" + name + "\"\\s*:")) { return true }
  source.configures and source.text.contains(regex("[^-\\w]" + name + "\\s*:"))
}

// The literals below are written as a source is: the text with a newline in
// front of it, and the marker answered once.
#let probe(text) = (text: "\n" + text, configures: configures(text))

// Both directions, against literals: the shapes that give a key a value count, a
// read does not, a name inside another name does not, and a named argument of
// something else does not.
#assert(sets("k", probe("table-options(k: true)")))
#assert(sets("k", probe("(\"k\": 1em)")))
#assert(sets("k", probe("display-table(data, theme: (k: 1em))")))
#assert(sets("k", probe("cell(directive, options: (k: 1em))")))
#assert(not sets("k", probe("block(k: false)")))
#assert(not sets("k", probe("option(theme-compact(), \"k\")")))
#assert(not sets("k", probe("table-options(a-k: true)")))
#assert(not sets("k", probe("(\"x-k\": 1em)")))
#assert(not sets("k", probe("the k option")))

#let source(path) = {
  let text = read(path)
  assert("/*" not in text, message: "the sequence /* is not stripped and can hide a key: " + path)
  assert("://" not in text, message: "a // inside a string cuts the rest of its line: " + path)
  probe(strip-comments(text))
}

// Every test and example that configures options at all, each read on its own so
// no pattern matches across the boundary between two files. Typst cannot walk a
// directory, so the list is explicit. It is every file the markers above match,
// and `option_setters` in tools/check.sh is the one place that walk is written:
// it holds this list to what the markers find, so the spelling lives there
// rather than being copied here to go stale.
//
// That walk names this file too, and it is left out on purpose: it sets no
// option outside the strings it tests `sets` against, and reading itself would
// trip its own guard against `://`, which it carries as a literal.
//
// A file left out can only leave a key looking uncovered, so an omission cannot
// loosen the assertion below. It leaves the record stale instead: a key covered
// tomorrow in a file nobody added here stays written down as covered by nothing.
// The list holds for the files named, and for no others.
#let sources = (
  source("../expect-fail/align-combine-source.typ"),
  source("../expect-fail/align-hidden-column.typ"),
  source("../expect-fail/align-indented-stub.typ"),
  source("../expect-fail/align-stub-group-column.typ"),
  source("../expect-fail/align-unknown-column-in-array.typ"),
  source("../expect-fail/align-unknown-column-with-stub.typ"),
  source("../expect-fail/move-anchor-hidden-after.typ"),
  source("../expect-fail/move-anchor-hidden-before.typ"),
  source("../expect-fail/move-anchor-stub.typ"),
  source("../expect-fail/move-duplicate-column.typ"),
  source("../expect-fail/move-unknown-column.typ"),
  source("../expect-fail/options-positional.typ"),
  source("../expect-fail/options-unknown-option.typ"),
  source("../expect-fail/theme-not-a-dictionary.typ"),
  source("../expect-fail/theme-unknown-option.typ"),
  source("../probe/row-border-body-edges.typ"),
  source("../probe/striping.typ"),
  source("../probe/table-rules-with-notes.typ"),
  source("../probe/table-rules.typ"),
  source("../probe/theme-borders.typ"),
  source("test-columns-align.typ"),
  source("test-columns-combine.typ"),
  source("test-direction.typ"),
  source("test-directive-order.typ"),
  source("test-display-table.typ"),
  source("test-format-number-defaults.typ"),
  source("test-format-number-limits.typ"),
  source("test-group-label-numeric.typ"),
  source("test-label-alignment.typ"),
  source("test-locations-footnotes.typ"),
  source("test-locations.typ"),
  source("test-marks-order.typ"),
  source("test-marks.typ"),
  source("test-nanoplot.typ"),
  source("test-options.typ"),
  source("test-row-groups.typ"),
  source("test-row-plan.typ"),
  source("test-selector-names.typ"),
  source("test-serialised-surface.typ"),
  source("test-serialised.typ"),
  source("test-spanners.typ"),
  source("test-spec.typ"),
  source("test-stub-groups.typ"),
  source("test-stub.typ"),
  source("test-style.typ"),
  source("test-summaries-precision.typ"),
  source("test-summaries.typ"),
  source("test-summary-format.typ"),
  source("test-summary-label-alignment.typ"),
  source("test-summary-locations.typ"),
  source("test-theme-rounding.typ"),
  source("../visual/combined.typ"),
  source("../visual/conventions.typ"),
  source("../visual/dates-markup.typ"),
  source("../visual/formatters.typ"),
  source("../visual/grouped.typ"),
  source("../visual/nanoplots.typ"),
  source("../visual/row-groups.typ"),
  source("../visual/rules.typ"),
  source("../visual/summaries.typ"),
)

// The options no test gives a value, in the order they are declared.
#let UNCOVERED = (
  "table-font",
  "table-font-size",
  "table-align",
  "table-width",
  "breakable",
  "decimal-align",
  "header-title-size",
  "header-title-weight",
  "header-subtitle-size",
  "header-align",
  "header-border-bottom",
  "column-labels-weight",
  "column-labels-size",
  "spanner-border-bottom",
  "stub-weight",
  "row-group-weight",
  "row-group-fill",
  "row-group-border-top",
  "row-group-repeat",
  "summary-weight",
  "summary-fill",
  "summary-border-top",
  "grand-summary-border-top",
  "footer-align",
  "footnote-marks",
  "footnote-size",
  "source-note-size",
)

#assert.eq(
  DEFAULTS.keys().filter(name => not sources.any(source => sets(name, source))),
  UNCOVERED,
  message: "cover the key or record it in UNCOVERED; a key that gained a test comes off the list",
)
