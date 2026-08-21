// A style descriptor carrying a key it does not read. A style and a footnote
// address cells the same way, so the location keys are known here too.
// expect: display-table: style has an unknown key stlye
// expect: Known keys: style, part, columns, rows, groups, spanners, notes, parts.

#import "../../src/spec.typ": build-spec
#import "../../src/spec/serialised.typ": resolve-serialised

#resolve-serialised(
  (
    kind: "display-table",
    data: ((units: 1),),
    styles: ((stlye: (fill: "#08519c"), columns: "units"),),
  ),
  build-spec,
)
