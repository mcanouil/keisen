// The plot is the renderer the column is drawn with, so a name is not one: it
// reached the cell and Typst reported a string where a function was called.
// expect: format-nanoplot: plot must be a renderer function
// expect: got "nanoplot-line".
// expect: Pass nanoplot-line, nanoplot-bar, nanoplot-points, or a renderer of the same shape.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: "nanoplot-line"),
)
