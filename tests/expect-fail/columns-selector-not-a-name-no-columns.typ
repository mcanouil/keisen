// The same for a column selector: every column is hidden, so the matcher ran
// against nothing and a selector of the wrong kind was never read.
// expect: columns: selector must be auto, a name, an array of names, or a predicate
// expect: got 42.
// expect: Write "units", ("units", "price"), or name => name != "units".

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (units: (1, 2)),
  columns-hide("units"),
  table-style(style(fill: red), locations: cells-column-labels(columns: 42)),
)
