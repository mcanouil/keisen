// Locations name cells by what the data says, not by where they sit, and
// expand against the folded spec into (part, row, column) addresses.

#import "../../src/locations.typ": (
  cells-body, cells-column-labels, cells-column-spanners, cells-row-groups, cells-source-notes,
  cells-stub, cells-stubhead, cells-title, expand,
)
#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-label
#import "../../src/parts/header.typ": table-header
#import "../../src/parts/notes.typ": table-source-note
#import "../../src/parts/spanners.typ": table-spanner
#import "../../src/parts/stub.typ": table-stub

#let spec = build-spec(
  (
    product: ("Bolt", "Nut", "Beam"),
    region: ("North", "North", "South"),
    units: (10, 20, 30),
    price: (1.5, 2.5, 3.5),
  ),
  (
    table-header(title: [Sales]),
    table-stub(rowname: "product", group: "region"),
    table-spanner([Figures], ("units", "price")),
    table-source-note([Source: ledger.]),
  ),
  (:),
)

// --- body cells ---

// Every visible column, every row.
#assert.eq(expand(cells-body(), spec).len(), 6)

// One column, every row.
#assert.eq(
  expand(cells-body(columns: "units"), spec),
  (
    (part: "body", row: 0, column: "units"),
    (part: "body", row: 1, column: "units"),
    (part: "body", row: 2, column: "units"),
  ),
)

// A predicate over the row, which is the thing show rules cannot express.
#assert.eq(
  expand(cells-body(columns: "units", rows: row => row.units > 15), spec).map(cell => cell.row),
  (1, 2),
)

// A predicate is a filter, so matching nothing is silent: a table built from
// filtered data legitimately has fewer rows on some renderings than on others.
// A name is not a filter, and one that does not resolve is reported instead;
// tests/expect-fail/ holds those, including the stub and hidden cases.
#assert.eq(expand(cells-body(columns: name => name == "absent"), spec), ())
#assert.eq(expand(cells-body(rows: row => false), spec), ())

// --- the other parts ---

#assert.eq(expand(cells-stub(), spec).map(cell => cell.row), (0, 1, 2))
#assert.eq(expand(cells-stub(rows: 1), spec), ((part: "stub", row: 1, column: none),))
#assert.eq(expand(cells-stubhead(), spec), ((part: "stubhead", row: none, column: none),))

#assert.eq(expand(cells-row-groups(), spec).map(cell => cell.row), (0, 1))
#assert.eq(expand(cells-row-groups(groups: "South"), spec).map(cell => cell.row), (1,))

#assert.eq(
  expand(cells-column-labels(columns: "units"), spec),
  ((part: "column-labels", row: none, column: "units"),),
)
#assert.eq(expand(cells-column-labels(), spec).len(), 2)

// A spanner is addressed by its label, which is content: it has no column of
// its own to be named by.
#assert.eq(expand(cells-column-spanners(), spec).map(cell => cell.column), ([Figures],))
#assert.eq(expand(cells-column-spanners(spanners: [Figures]), spec).len(), 1)
#assert.eq(expand(cells-column-spanners(spanners: label => false), spec), ())

#assert.eq(expand(cells-title(), spec).map(cell => cell.column), ("title", "subtitle"))
#assert.eq(expand(cells-title(parts: "title"), spec).map(cell => cell.column), ("title",))

#assert.eq(expand(cells-source-notes(), spec), ((part: "source-notes", row: 0, column: none),))
#assert.eq(expand(cells-source-notes(notes: (0,)), spec).len(), 1)
#assert.eq(expand(cells-source-notes(notes: note => false), spec), ())

// A group column of numbers is labelled by strings, so a numeric selector
// matches the group it plainly means.
#let numeric = build-spec((year: (2025, 2024), units: (1, 2)), (table-stub(group: "year"),), (:))
#assert.eq(expand(cells-row-groups(groups: 2025), numeric).map(cell => cell.row), (0,))
#assert.eq(expand(cells-row-groups(groups: ("2025", 2024)), numeric).len(), 2)

// --- several locations at once ---

#assert.eq(expand((cells-stubhead(), cells-source-notes()), spec).len(), 2)
