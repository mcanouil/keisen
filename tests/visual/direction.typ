// The same table twice, once in left-to-right text and once in right-to-left,
// which is the check the package's alignments were designed for and nothing
// performed until now.
//
// This one is read by eye. Compiling proves nothing about it, and the unit
// test beside it (tests/unit/test-direction.typ) covers only what a function
// returns. What to look for in the right-to-left table:
//
//   - the columns run the other way, stub last;
//   - the title, the labels and the text cells sit against the right edge;
//   - the amounts sit against the left edge, still lined up on their decimal
//     separators, and each still reads 1 256.750 rather than 750.256 1.
//
// The last of those was broken until the number run was pinned to ltr.

#import "../../lib.typ": *

#set page(width: auto, height: auto, margin: 0.5cm)
#set text(font: "Libertinus Serif", size: 10pt)

#let readings = (
  station: ("Alpha", "Beta", "Gamma"),
  region: ("North", "North", "South"),
  amount: (1256.75, 8.5, 340.125),
  share: (0.62, 0.31, 0.07),
)

#let build = display-table.with(
  readings,
  table-header(title: [Readings], subtitle: [Two directions, one table]),
  table-stub(rowname: "station", group: "region", label: [Station]),
  columns-label(amount: [Amount], share: [Share]),
  format-number("amount", decimals: 3),
  format-percent("share", decimals: 1),
  summary-rows(functions: (Total: aggregate-sum), columns: ("amount",)),
  table-source-note([Source: station log.]),
)

Left to right.

#build()

#v(1em)

#set text(dir: rtl)

Right to left.

#build()
