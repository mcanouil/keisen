// A spanner entry carrying a key it does not read. The scope names the directive
// the key resolves into, so the reader has a name to look up.
// expect: table-spanner: unknown key levl
// expect: Known keys: label, columns, level.
#import "../../lib.typ": *
#set page(width: auto, height: auto, margin: 0.5cm)
#display-table(spec: (
  kind: "display-table",
  data: ((product: "Bolt", units: 5),),
  spanners: ((label: "Figures", columns: ("units",), levl: 1),),
))
