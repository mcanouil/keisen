// The plot is the renderer the column is drawn with. The function itself is not
// one: the commonest mistake is to name a renderer without calling it.
// expect: format-nanoplot: plot must be a nanoplot renderer
// expect: got nanoplot-line.
// expect: Call the renderer, as in nanoplot-line(), or pass a dictionary with kind: "nanoplot-renderer".
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (trend: ((1.0, 2.0, 1.5),)),
  format-nanoplot("trend", plot: nanoplot-line),
)
