// Marks follow the order a reader meets the cells, which grouping changes, and
// a spanner is addressed by the level it sits on.

#import "../../src/spec.typ": build-spec
#import "../../src/locations.typ": cells-body, cells-column-spanners
#import "../../src/parts/marks.typ": assign-marks, marks-for
#import "../../src/parts/notes.typ": table-footnote
#import "../../src/parts/spanners.typ": table-spanner
#import "../../src/parts/stub.typ": table-stub

// --- display order, not input order ---

// Rows 1 and 2 sit in different groups, so grouping puts input row 2 above
// input row 1. The marks must follow the page, not the data.
#let spec = build-spec(
  (name: ("a", "b", "c", "d"), region: ("N", "S", "N", "S"), units: (1, 2, 3, 4)),
  (
    table-stub(rowname: "name", group: "region"),
    table-footnote([On input row 1.], locations: cells-body(rows: 1)),
    table-footnote([On input row 2.], locations: cells-body(rows: 2)),
  ),
  (:),
)
#let footnotes = assign-marks(spec)

// Input row 2 renders in the first group, so it is met first and marked first.
#assert.eq(marks-for(footnotes, "body", 2, "units"), ("1",))
#assert.eq(marks-for(footnotes, "body", 1, "units"), ("2",))

// --- left to right within a row ---

#let across = assign-marks(build-spec(
  (first: (1,), second: (2,)),
  (
    table-footnote([Right.], locations: cells-body(columns: "second")),
    table-footnote([Left.], locations: cells-body(columns: "first")),
  ),
  (:),
))
#assert.eq(marks-for(across, "body", 0, "first"), ("1",))
#assert.eq(marks-for(across, "body", 0, "second"), ("2",))

// --- a spanner above level one still takes its mark ---

#let stacked = build-spec(
  (a: (1,), b: (2,)),
  (
    table-spanner([Inner], ("a", "b")),
    table-spanner([Outer], ("a", "b"), level: 2),
    table-footnote([On the outer spanner.], locations: cells-column-spanners(spanners: [Outer])),
  ),
  (:),
)
#assert.eq(marks-for(assign-marks(stacked), "column-spanners", 2, [Outer]), ("1",))

// --- a spanner is ranked where it renders ---

// Levels render highest first, so the level cannot be the rank as it stands: a
// spanner at level 2 sits above one at level 1 and must be met first. The rank
// read the level straight, so the reader met mark 2 above mark 1.
#let levels = build-spec(
  (a: (1,), b: (2,)),
  (
    table-spanner([Low], ("a", "b")),
    table-spanner([High], ("a", "b"), level: 2),
    table-footnote([On the lower spanner.], locations: cells-column-spanners(spanners: [Low])),
    table-footnote([On the higher spanner.], locations: cells-column-spanners(spanners: [High])),
  ),
  (:),
)
#let ranked = assign-marks(levels)
#assert.eq(marks-for(ranked, "column-spanners", 2, [High]), ("1",))
#assert.eq(marks-for(ranked, "column-spanners", 1, [Low]), ("2",))

// Within one level a spanner is met at the leftmost column it covers. A spanner
// address carries its label where a cell address carries a column name, so the
// column rank was never found and the order the directives happened to be
// written in decided instead.
#let side-by-side = build-spec(
  (a: (1,), b: (2,), c: (3,), d: (4,)),
  (
    table-spanner([Left], ("a", "b")),
    table-spanner([Right], ("c", "d")),
    table-footnote([On the right spanner.], locations: cells-column-spanners(spanners: [Right])),
    table-footnote([On the left spanner.], locations: cells-column-spanners(spanners: [Left])),
  ),
  (:),
)
#let across-spanners = assign-marks(side-by-side)
#assert.eq(marks-for(across-spanners, "column-spanners", 1, [Left]), ("1",))
#assert.eq(marks-for(across-spanners, "column-spanners", 1, [Right]), ("2",))
