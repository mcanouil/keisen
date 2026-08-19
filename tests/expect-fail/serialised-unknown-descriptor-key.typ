// A typo inside a descriptor used to change the table rather than fail: a
// misspelled columns key meant the subtotal spanned every column.
// expect: summary: unknown key colums
// expect: Known keys: name, label, columns, groups.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    summaries: ((name: "aggregate-sum", label: "Subtotal", colums: ("units",)),),
  ),
  build-spec,
)
