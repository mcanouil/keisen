// A fractional width has to be resolved inside the cell with layout(), which
// forbids a page break there, so a nanoplot takes its size in em or pt.
// expect: format-nanoplot: width cannot be a fraction
// expect: got 1fr.
// expect: Give it in em or pt: resolving a fraction inside a cell forbids page breaking there.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line, width: 1fr),
)
