// A row index outside the data is a typo by definition, so it is named rather
// than dropped. A predicate matching nothing is a different case, and stays
// silent: a table built from filtered data legitimately has fewer rows on some
// renderings than on others.
// expect: table-row-group: row 4 is not in the data
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (country: ("Denmark", "Spain"), units: (1, 2)),
  table-row-group([Nordics], (0, 4)),
)
