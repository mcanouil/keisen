// The stub descriptor was one of three that never validated its keys, so a
// plural typo rendered the table ungrouped without a word.
// expect: stub: unknown key groups
// expect: Known keys: rowname, group, label, indent.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/resolve.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((product: "Bolt", region: "North", units: 1),),
    stub: (rowname: "product", groups: "region"),
  ),
  build-spec,
)
