// A renderer's draw is the function that paints a cell.
// expect: format-nanoplot: draw must be a function
// expect: got "line".
// expect: Give a function of the cell value, or call the renderer as it ships.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line() + (draw: "line")),
)
