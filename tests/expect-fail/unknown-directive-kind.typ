// A dictionary carrying a kind this version does not handle. It reached the
// fold and fell out of it, leaving the directive silently undone.
// expect: display-table: unknown directive
// expect: got "sparkline".
// expect: This version handles header, stub, row-group, labels, hide, combine, spanner, move, format, style, substitute, colour, footnote, options, width, align, summary, source-note.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  (kind: "sparkline", columns: "units"),
)
