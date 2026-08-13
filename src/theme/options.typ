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
  "table-border-top": none,
  "table-border-bottom": none,
  "breakable": true,
  "infer-alignment": true,
  "decimal-align": true,
  "accessibility-extras": false,
  // Header
  "header-title-size": 1.1em,
  "header-title-weight": "bold",
  "header-subtitle-size": 1em,
  "header-align": start,
  "header-border-bottom": none,
  // Column labels
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
  "body-border-top": none,
  "body-border-bottom": none,
  "cell-inset": 0.5em,
  // Rules
  "column-border": none,
  "row-border": none,
  // Summaries
  "summary-weight": "bold",
  "summary-fill": none,
  "summary-border-top": none,
  "grand-summary-border-top": none,
  // Footer
  "footnote-marks": "numbers",
  "footnote-size": 0.8em,
  "source-note-size": 0.8em,
  "footer-border-top": none,
  // Numbers
  "number-decimal-separator": ".",
  "number-group-separator": sym.space.thin,
)

#let table-options(..keys) = {
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
