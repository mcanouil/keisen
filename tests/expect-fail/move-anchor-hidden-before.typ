// The same pair the other way round. Both orders must fail the same way: that
// symmetry is the guarantee, and it is why moves resolve after the fold.
// expect: columns-move: column notes is hidden

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-hide, columns-move

#build-spec(
  (city: (1,), highway: (2,), price: (3,), notes: ("x",)),
  (columns-hide("notes"), columns-move("price", after: "notes")),
  (:),
)
