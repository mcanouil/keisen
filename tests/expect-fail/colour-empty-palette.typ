// The palette is what the scale samples, so an empty one has no colour to give.
// expect: data-colour: the palette is empty
// expect: Give at least one colour, or two for a gradient.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (5, 3)),
  data-colour((), columns: "units"),
)
