// Every option a test sets, and the recorded list of the ones no test sets.
//
// `test-options-read.typ` holds every declared key to being read by a renderer,
// which is why an option nothing sets was never reported: it is read, in a
// branch or a cell nothing had ever asked for. Thirty-one of the forty-six were
// set by no test, each of them a promise no test has seen kept, and this list
// records the twenty-eight that still are.
//
// A key covered tomorrow comes off the list, and a key declared tomorrow is
// covered or added here on purpose, so the list can only shrink.

#import "../../src/theme/options.typ": DEFAULTS

// A source with its comments removed, so a key named in a comment is not read as
// coverage. Repeated from `test-options-read.typ` rather than shared, so neither
// test can fail for the other's reason.
#let strip-comments(text) = {
  text.split("\n").map(line => line.split("//").first()).join("\n")
}

#assert.eq(strip-comments("a \"x\" // \"y\"\nb"), "a \"x\" \nb")
#assert.eq(strip-comments("// \"x\"\na"), "\na")

// A key is covered where a test gives it a value: as a named argument,
// `table-options(cell-inset: 0.3em)`, or as a key of a theme dictionary, whether
// it is written bare or quoted.
//
// Reading a key by name is not covering it. `option(theme-compact(), "cell-inset")`
// asserts what the preset carries, and the renderer could stop reading the key
// with that assertion still green, which is what `test-options-read.typ` is for.
#let set-by(name, text) = {
  // A key holding a regex metacharacter would loosen the pattern rather than
  // fail, so the shape a key may take is asserted rather than escaped.
  assert(
    name.match(regex("^[a-z][a-z-]*$")) != none,
    message: "an option name outside a to z and the hyphen needs escaping here: " + name,
  )
  // Anchored on the character before the name, so a longer key ending in this
  // one is not a mention of it. Rust regex has no lookaround, so the anchor is a
  // character class and the text gains a newline in front of it for the case
  // where the key opens the text.
  ("\n" + text).contains(regex("[^-\\w]\"?" + name + "\"?\\s*:"))
}

// Both directions, against literals: the shapes that give a key a value count,
// a read does not, and a name inside another name does not.
#assert(set-by("k", "table-options(k: true)"))
#assert(set-by("k", "(k: 1em)"))
#assert(set-by("k", "(\"k\": 1em)"))
#assert(not set-by("k", "option(theme-compact(), \"k\")"))
#assert(not set-by("k", "table-options(a-k: true)"))
#assert(not set-by("k", "(\"x-k\": 1em)"))
#assert(not set-by("k", "the k option"))

#let source(path) = {
  let text = read(path)
  assert("/*" not in text, message: "the sequence /* is not stripped and can hide a key: " + path)
  assert("://" not in text, message: "a // inside a string cuts the rest of its line: " + path)
  strip-comments(text)
}

// Every test and example that gives an option a value. Typst cannot walk a
// directory, so the list is explicit, and a test that starts setting an option
// is added here.
//
// A file left out can only leave a key looking uncovered, so an omission cannot
// loosen the assertion below. It can leave the record stale instead: a key
// covered tomorrow in a file nobody added here stays written down as covered by
// nothing. The list holds for the files named, and for no others.
#let sources = (
  source("../probe/row-border-body-edges.typ"),
  source("../probe/striping.typ"),
  source("../probe/table-rules-with-notes.typ"),
  source("../probe/table-rules.typ"),
  source("../probe/theme-borders.typ"),
  source("test-direction.typ"),
  source("test-format-number-defaults.typ"),
  source("test-label-alignment.typ"),
  source("test-options.typ"),
  source("test-serialised.typ"),
  source("test-spec.typ"),
  source("test-stub.typ"),
  source("test-theme-rounding.typ"),
  source("../visual/conventions.typ"),
  source("../visual/grouped.typ"),
  source("../visual/nanoplots.typ"),
  source("../../examples/serialised.typ"),
  // A parenthesis between the sources, so no pattern matches across the
  // boundary between two files.
).join("\n)\n")

// The options no test gives a value, in the order they are declared.
#let UNCOVERED = (
  "table-font",
  "table-font-size",
  "table-align",
  "table-width",
  "breakable",
  "infer-alignment",
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
  DEFAULTS.keys().filter(name => not set-by(name, sources)),
  UNCOVERED,
  message: "cover the key or record it in UNCOVERED; a key that gained a test comes off the list",
)
