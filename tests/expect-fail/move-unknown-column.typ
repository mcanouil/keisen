// A typo in the moved column, which used to insert a phantom column instead.
// expect: columns-move: unknown column pricce
// expect: Known columns: city, price.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-move

#build-spec(
  (city: (1,), price: (3,)),
  (columns-move("pricce", before: "city"),),
  (:),
)
