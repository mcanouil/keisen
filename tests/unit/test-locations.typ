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

// Hidden and stub columns are not body cells.
#assert.eq(expand(cells-body(columns: "product"), spec), ())

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
#assert.eq(expand(cells-column-spanners(spanners: [Missing]), spec), ())

#assert.eq(expand(cells-title(), spec).map(cell => cell.column), ("title", "subtitle"))
#assert.eq(expand(cells-title(parts: "title"), spec).map(cell => cell.column), ("title",))

#assert.eq(expand(cells-source-notes(), spec), ((part: "source-notes", row: 0, column: none),))

// --- several locations at once ---

#assert.eq(expand((cells-stubhead(), cells-source-notes()), spec).len(), 2)
