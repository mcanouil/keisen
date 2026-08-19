// The stub's row-name column is the one name beyond the rendered columns that
// an alignment accepts, so the hint that lists what is known has to name it.
// Leading edge first, which is where the stub sits.
// expect: columns-align: unknown column prodcut
// expect: Known columns: product, units, price.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align
#import "../../src/parts/stub.typ": table-stub

#build-spec(
  (product: ("Bolt",), units: (1,), price: (2,)),
  (table-stub(rowname: "product"), columns-align(end, columns: "prodcut")),
  (:),
)
