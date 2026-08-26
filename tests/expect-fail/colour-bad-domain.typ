// A domain is the window the palette is stretched over, so it needs a low and a
// high. Anything else used to be dropped without a word, and the column simply
// came out plain.
// expect: data-colour: domain must be auto or a low and a high
// expect: got none.
// expect: Write domain: (0, 100), or leave it auto to span the data.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(
  (product: ("Bolt", "Nut"), units: (10, 20)),
  data-colour(rgb("#08306b"), columns: "units", domain: none),
)
