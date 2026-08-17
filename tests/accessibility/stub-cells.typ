// Stub cells are ordinary data cells, and this pins that.
//
// The design calls the limitation documented rather than silent: `table.header`
// is unsuitable for a header column, so a row name is tagged `/TD` like any
// other cell, and nothing carries `/Scope /Row`. Marking a row name as a header
// cell needs `pdf.header-cell`, which sits behind Typst's `a11y-extras`
// feature, and the `accessibility-extras` option that would turn it on is not
// built.
//
// The counts below are the limitation itself. They go red the day it lifts,
// which is the day this file and the design should both be rewritten.
//
// expect-tag: 1 /S /Table
// expect-tag: 2 /S /TH
// expect-tag: 2 /Scope /Column
// expect-tag: 0 /Scope /Row
// expect-tag: 6 /S /TD

#import "../../lib.typ": *

#set document(title: [Regional sales], author: "keisen")
#set text(lang: "en")

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#display-table(
  (
    product: ("Bolt", "Nut", "Beam"),
    units: (1250, 860, 430),
  ),
  table-stub(rowname: "product", label: [Product]),
  columns-label(units: [Units]),
  format-integer("units"),
)
