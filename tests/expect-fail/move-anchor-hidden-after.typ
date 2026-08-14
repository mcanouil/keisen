// A move anchored on a column that a later directive hides. Written this way
// round it used to succeed, because the anchor still existed when the move ran.
// expect: columns-move: column notes is hidden

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-hide, columns-move

#build-spec(
  (city: (1,), highway: (2,), price: (3,), notes: ("x",)),
  (columns-move("price", after: "notes"), columns-hide("notes")),
  (:),
)
