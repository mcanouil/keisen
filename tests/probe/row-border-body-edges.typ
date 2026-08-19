// `row-border` falls to the row edges the parts leave alone, and four edges are
// not among them: the table's first and last, and the body's opening and
// closing edges. Those four are answered by `table-border-*` and
// `body-border-*`, where `none` is an answer rather than a silence.
//
// The table below holds one body row, so the body has no interior edge for
// `row-border` to draw on, and every one of the four answers is `none`. If any
// of them fell through to the table's rule, the green would reach the render.
//
// `column-border` is drawn in its own colour, so a render that lost its strokes
// altogether cannot pass for the suppression this file watches. The three
// tables further down are the positive controls: each holds one edge the rule
// does reach, in a colour of its own, so a rejection here cannot stay green on
// a renderer that stopped drawing `row-border` at all.
//
// expect-svg: stroke="#ff0000"
// reject-svg: stroke="#00ff00"

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)

#display-table(
  (product: ("Bolt",), units: (1250,)),
  columns-label(units: [Units]),
  format-integer("units"),
  table-options(
    column-border: 1pt + rgb("#ff0000"),
    row-border: 1pt + rgb("#00ff00"),
    table-border-top: none,
    table-border-bottom: none,
    body-border-top: none,
    body-border-bottom: none,
    column-labels-border-bottom: none,
  ),
)

// The table above has no footer, so the body's closing edge is the table's last
// edge and both are answered by the same branch. With a source note the body
// closes against a row that follows it, which is a branch of its own: the rule
// is written as the top of that row rather than as the bottom of the body.
//
// expect-svg: stroke="#0000ff"
// reject-svg: stroke="#00ffff"

#display-table(
  (product: ("Bolt",), units: (1250,)),
  columns-label(units: [Units]),
  format-integer("units"),
  table-source-note([Source: ledger.]),
  table-options(
    column-border: 1pt + rgb("#0000ff"),
    row-border: 1pt + rgb("#00ffff"),
    table-border-top: none,
    table-border-bottom: none,
    body-border-top: none,
    body-border-bottom: none,
    column-labels-border-bottom: none,
    footer-border-top: none,
  ),
)

// The edges `row-border` does reach, and which the reference names. Each is
// given a table of its own, and a colour of its own, so one assertion answers
// for one edge: a probe greps the whole file's render, and a table drawing the
// rule at several edges would let any one of them stand in for the rest.
//
// Two body rows and nothing else: the labels row opens the table and the body
// closes it, so the edge between the two body rows is the only one left to
// `row-border`.
//
// expect-svg: stroke="#ffff00"

#display-table(
  (product: ("Bolt", "Nut"), units: (1250, 860)),
  columns-label(units: [Units]),
  format-integer("units"),
  table-options(
    row-border: 1pt + rgb("#ffff00"),
    table-border-top: none,
    table-border-bottom: none,
    body-border-top: none,
    body-border-bottom: none,
    column-labels-border-bottom: none,
  ),
)

// One body row and two notes: the body's closing edge is the first note's top,
// which `body-border-bottom` answers, so the edge between the two notes is the
// only one left.
//
// expect-svg: stroke="#800080"

#display-table(
  (product: ("Bolt",), units: (1250,)),
  columns-label(units: [Units]),
  format-integer("units"),
  table-source-note([Source: ledger.]),
  table-source-note([Figures are provisional.]),
  table-options(
    row-border: 1pt + rgb("#800080"),
    table-border-top: none,
    table-border-bottom: none,
    body-border-top: none,
    body-border-bottom: none,
    column-labels-border-bottom: none,
    footer-border-top: none,
  ),
)

// A title and a subtitle. The top of the column-labels row would fall to
// `row-border` as well, so the labels row claims that edge with a rule of its
// own, drawn as a cell rule that wins over the table's. The edge between the
// title and the subtitle is then the only one left in its colour.
//
// expect-svg: stroke="#008080"
// expect-svg: stroke="#ff8000"

#display-table(
  (product: ("Bolt",), units: (1250,)),
  table-header(title: [Regional sales], subtitle: [First quarter]),
  columns-label(units: [Units]),
  format-integer("units"),
  table-options(
    row-border: 1pt + rgb("#008080"),
    column-labels-border-top: 1pt + rgb("#ff8000"),
    table-border-top: none,
    table-border-bottom: none,
    body-border-top: none,
    body-border-bottom: none,
    column-labels-border-bottom: none,
  ),
)
