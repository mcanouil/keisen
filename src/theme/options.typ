///! Option dictionary and merging.
///!
///! A theme is an option dictionary, so a preset and a `table-options()` call
///! are the same kind of thing and compose by merging. Roughly forty curated
///! keys rather than one per conceivable property: an option nobody sets is a
///! maintenance cost with no reader.

#import "../utils/errors.typ": check

#let DEFAULTS = (
  // Table
  "table-font": none,
  "table-font-size": none,
  "table-align": start,
  // `auto` lets the table size itself to its content. Given a width, the columns
  // no columns-width names share whatever the named ones leave.
  "table-width": auto,
  "table-border-top": none,
  "table-border-bottom": none,
  "breakable": true,
  "infer-alignment": true,
  "decimal-align": true,
  // Vertical rules between columns and horizontal rules between rows, both off
  // by default: a table reads better ruled by part than ruled as a grid.
  "column-border": none,
  "row-border": none,
  // Header
  "header-title-size": 1.1em,
  "header-title-weight": "bold",
  "header-subtitle-size": 1em,
  "header-align": start,
  "header-border-bottom": none,
  // Column labels
  // `auto` follows the column beneath, which is what a label usually wants.
  "column-labels-align": auto,
  "column-labels-weight": "bold",
  "column-labels-size": 1em,
  "column-labels-border-top": none,
  "column-labels-border-bottom": none,
  "spanner-border-bottom": none,
  // Stub and groups
  "stub-weight": "regular",
  "stub-indent-step": 1em,
  "row-group-weight": "bold",
  "row-group-fill": none,
  "row-group-border-top": none,
  "row-group-repeat": true,
  // Body
  "row-striping": false,
  "row-striping-fill": luma(245),
  "cell-inset": 0.5em,
  "body-border-top": none,
  "body-border-bottom": none,
  // `auto` leaves the vertical placement to Typst, which centres a cell against
  // the tallest in its row.
  "cell-vertical-align": auto,
  // Summaries
  "summary-weight": "bold",
  "summary-fill": none,
  "summary-border-top": none,
  "grand-summary-border-top": none,
  // Formatter defaults
  //
  // What a formatter uses where its own argument is `auto`, so a French or
  // German table sets its convention once rather than on every directive.
  "number-group-separator": sym.space.thin,
  "number-decimal-separator": ".",
  "number-rounding": "half-up",

  // Footer
  "footer-align": start,
  "footnote-marks": "numbers",
  "footnote-size": 0.8em,
  "source-note-size": 0.8em,
  "footer-border-top": none,
)

#let table-options(..keys) = {
  check(
    keys.pos().len() == 0,
    "table-options",
    "options are named, not positional",
    hint: "Write table-options(row-striping: true).",
  )
  let named = keys.named()
  for name in named.keys() {
    check(
      name in DEFAULTS,
      "table-options",
      "unknown option " + name,
      hint: "See the reference for the option names this version reads.",
    )
  }
  (kind: "options", options: named)
}

// An option read through here always has a value, so the renderer never carries
// a default of its own.
#let option(options, name) = options.at(name, default: DEFAULTS.at(name))

// A theme is an option dictionary, so it is checked exactly as table-options
// checks its keys: a preset passed uncalled, or a typo in a hand-written theme,
// is reported rather than ignored.
#let validate-options(options, scope) = {
  check(
    type(options) == dictionary,
    scope,
    "theme must be an option dictionary",
    value: options,
    hint: "Call the preset: theme: theme-booktabs().",
  )
  for name in options.keys() {
    check(
      name in DEFAULTS,
      scope,
      "unknown option " + name,
      hint: "See the reference for the option names this version reads.",
    )
  }
  options
}
