// An array selector spells its names out, so a typo among them is a typo. The
// array used to be filtered against the table instead of read, so this passed
// while the same typo written as a bare string was reported.
// expect: columns-align: unknown column tpyo
// expect: Known columns: units, price.

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-align

#build-spec(
  (units: (1,), price: (2,)),
  (columns-align(end, columns: ("units", "tpyo")),),
  (:),
)
