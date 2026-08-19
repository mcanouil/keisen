// A hidden column draws no cell to align, and it is not unknown either.
// expect: columns-align: column price is hidden
// expect: Align a visible column: columns-hide removes one, and columns-combine hides its sources unless hide-sources is false.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align, columns-hide

#build-spec(
  (units: (1,), price: (2,)),
  (columns-hide("price"), columns-align(end, columns: "price")),
  (:),
)
