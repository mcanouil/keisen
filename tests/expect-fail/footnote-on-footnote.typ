// Which row a footnote row lands on is settled by numbering the marks, so a
// footnote that marked a footnote row would have to be numbered before the
// numbering it takes part in. It is refused rather than expanded to nothing.
// expect: cells-footnotes: the footnote rows are not addressable yet
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (units: (1, 2)),
  table-footnote([Explains the table.]),
  table-footnote([Marks the note above.], locations: cells-footnotes(notes: 0)),
)
