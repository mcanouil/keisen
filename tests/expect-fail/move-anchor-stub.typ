// A move anchored on a column the stub promotes out of the table.
// expect: columns-move: column city is in the stub

#import "../../src/spec.typ": build-spec
#import "../../src/parts/columns.typ": columns-move
#import "../../src/parts/stub.typ": table-stub

#build-spec(
  (city: (1,), highway: (2,), price: (3,)),
  (columns-move("price", after: "city"), table-stub(rowname: "city")),
  (:),
)
